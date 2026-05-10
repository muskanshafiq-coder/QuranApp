//
//  ReaderPDFViewerView.swift 
//

import SwiftUI
import PDFKit
import Combine

struct ReaderPDFViewerView: View {
    let book: ReaderQuranBook

    @StateObject private var loader = PDFLoader()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.app.ignoresSafeArea()

            switch loader.state {
            case .idle, .downloading:
                downloadingView
            case .ready(let document):
                PDFKitRepresentedView(
                    document: document,
                    isArabic: book.language.lowercased().contains("arabic")
                )
                .ignoresSafeArea(.container, edges: .bottom)
            case .failed(let message):
                errorView(message: message)
            }
        }
        .navigationTitle(Text(verbatim: book.title))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loader.start(book: book)
        }
    }

    private var downloadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: loader.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 220)

            Text(loader.progressLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .regular))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await loader.start(book: book) }
            } label: {
                Text("sleep_action_retry")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - PDFKit bridge

private struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument
    let isArabic: Bool

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(false)
        view.backgroundColor = .clear
        view.document = document
        // Arabic mushafs read right-to-left.
        if isArabic, let last = document.page(at: max(0, document.pageCount - 1)) {
            view.go(to: last)
        }
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }
    }
}

// MARK: - Loader

enum QuranPDFDiskCache {
    static let namespace = "QuranPDFs"
    static func key(id: Int) -> String { "pdf-\(id)" }

    static func isDownloaded(id: Int) -> Bool {
        DiskCache(namespace: namespace).data(for: key(id: id)) != nil
    }
}

@MainActor
final class PDFLoader: ObservableObject {

    enum State {
        case idle
        case downloading
        case ready(PDFDocument)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var progress: Double = 0

    var progressLabel: String {
        let pct = Int((progress * 100).rounded())
        return "\(pct)%"
    }

    private let cache = DiskCache(namespace: QuranPDFDiskCache.namespace)

    func start(book: ReaderQuranBook) async {
        state = .downloading
        progress = 0

        let cacheKey = QuranPDFDiskCache.key(id: book.id)

        if let cached = cache.data(for: cacheKey),
           let document = PDFDocument(data: cached) {
            state = .ready(document)
            return
        }

        guard let url = book.downloadURL else {
            state = .failed("Invalid PDF URL")
            return
        }

        do {
            let data = try await downloadWithProgress(from: url)
            cache.setData(data, for: cacheKey)
            guard let document = PDFDocument(data: data) else {
                state = .failed("Could not open PDF")
                return
            }
            state = .ready(document)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func resetToIdle() {
        state = .idle
        progress = 0
    }

    private func downloadWithProgress(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let total = Double(response.expectedContentLength)
        var data = Data()
        if total > 0 { data.reserveCapacity(Int(total)) }
        var lastReported: Double = 0

        for try await byte in asyncBytes {
            data.append(byte)
            if total > 0 {
                let pct = Double(data.count) / total
                if pct - lastReported >= 0.01 {
                    lastReported = pct
                    progress = pct
                }
            }
        }
        progress = 1
        return data
    }
}
