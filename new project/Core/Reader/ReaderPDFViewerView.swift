//
//  ReaderPDFViewerView.swift
//

import SwiftUI
import PDFKit
import Combine
import UIKit

struct ReaderPDFViewerView: View {
    let book: ReaderQuranBook

    @StateObject private var loader = PDFLoader()
    @Environment(\.dismiss) private var dismiss

    @State private var logicalPageIndex = 0
    @State private var pageCount = 0
    @State private var showPageGrid = false
    @State private var isBookmarked = false

    private var bookmarkStorageKey: String { "ReaderPDF.savedPage.\(book.id)" }

    private var isArabic: Bool { book.language.lowercased().contains("arabic") }

    private func displayedPageNumber(totalPages total: Int) -> Int {
        return logicalPageIndex + 1
    }

    var body: some View {
        ZStack {
            Color.app
                .ignoresSafeArea()

            switch loader.state {
            case .idle, .downloading:
                downloadingView
            case .ready(let document):
                pdfReaderSwiftUI(document: document)
            case .failed(let message):
                errorView(message: message)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topChrome
        }
        .navigationBarHidden(true)
        .task {
            await loader.start(book: book)
        }
    }

    private func logicalIndex(forDisplayed displayed: Int, pageCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return max(0, min(displayed - 1, count - 1))
    }

    @ViewBuilder
    private func pdfReaderSwiftUI(document: PDFDocument) -> some View {
        GeometryReader { geo in
            let contentBottomInset: CGFloat = 96
            let width = max(200, geo.size.width)
            let totalPages = document.pageCount

            ZStack(alignment: .bottom) {
                // Single-page reader (hidden behind grid)
                ReaderPDFPageSurface(
                    document: document,
                    logicalPageIndex: $logicalPageIndex,
                    pageCount: totalPages,
                    layoutDirection: isArabic ? .rightToLeft : .leftToRight,
                    contentWidth: width
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
                .padding(.bottom, contentBottomInset)
                .opacity(showPageGrid ? 0 : 1)

                // Grid overlay
                if showPageGrid {
                    pageGridView(document: document, totalPages: totalPages)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, contentBottomInset)
                        .transition(.opacity)
                }

                // Bottom bar: page badge + thumbnail strip
                VStack(spacing: 0) {
                    if !showPageGrid {
                        Text("\(displayedPageNumber(totalPages: totalPages))/\(totalPages)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.black.opacity(0.72))
                            .clipShape(Capsule())
                            .padding(.bottom, 8)
                    }

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 6) {
                                ForEach(0 ..< totalPages, id: \.self) { logical in
                                    ReaderPDFThumbnailCell(
                                        document: document,
                                        logicalIndex: logical,
                                        isSelected: logical == logicalPageIndex
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            logicalPageIndex = logical
                                            showPageGrid = false
                                        }
                                    }
                                    .id(logical)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .frame(height: contentBottomInset)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .onChange(of: logicalPageIndex) { newIndex in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
            .onAppear {
                let n = document.pageCount
                pageCount = n
                logicalPageIndex = Self.resolvedLogicalIndex(document: document, book: book, storageKey: bookmarkStorageKey)
                if n > 0 {
                    logicalPageIndex = min(max(logicalPageIndex, 0), n - 1)
                }
                refreshBookmarkState()
            }
            .onChange(of: logicalPageIndex) { _ in
                refreshBookmarkState()
            }
        }
    }

    // MARK: - Page Grid View

    private func pageGridView(document: PDFDocument, totalPages: Int) -> some View {
        let ordered = Array(0 ..< totalPages)
        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(ordered, id: \.self) { logical in
                        ReaderPDFGridCell(
                            document: document,
                            logicalIndex: logical,
                            isSelected: logical == logicalPageIndex
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                logicalPageIndex = logical
                                showPageGrid = false
                            }
                        }
                        .id(logical)
                    }
                }
                .padding(12)
            }
            .background(Color.app)
            .onAppear {
                proxy.scrollTo(logicalPageIndex, anchor: .center)
            }
        }
    }

    private func displayedPageNumber(forLogical logical: Int, total: Int) -> Int {
        return logical + 1
    }

    // MARK: - Top Chrome

    private var topChrome: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.secondary.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("close_button"))

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                // Resume pill — only visible while grid is open
                if showPageGrid {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showPageGrid = false
                        }
                    } label: {
                        Text("reader_pdf_resume")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color.secondary.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showPageGrid.toggle()
                    }
                } label: {
                    Image(systemName: showPageGrid ? "square.grid.2x2.fill" : "square.grid.2x2")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(showPageGrid ? Color.accentColor : .primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showPageGrid ? Text("reader_pdf_close_grid") : Text("reader_pdf_browse_pages"))

                Button {
                    saveBookmarkCurrentPage()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isBookmarked ? Color.accentColor : .primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("reader_pdf_save_page"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.app)
        .animation(.easeInOut(duration: 0.2), value: showPageGrid)
    }

    // MARK: - Persistence

    private func saveBookmarkCurrentPage() {
        UserDefaults.standard.set(logicalPageIndex, forKey: bookmarkStorageKey)
        withAnimation(.spring(duration: 0.3)) { isBookmarked = true }
    }

    private func refreshBookmarkState() {
        guard let saved = UserDefaults.standard.object(forKey: bookmarkStorageKey) as? Int else {
            isBookmarked = false
            return
        }
        isBookmarked = (saved == logicalPageIndex)
    }

    private static func resolvedLogicalIndex(document: PDFDocument, book: ReaderQuranBook, storageKey: String) -> Int {
        let count = document.pageCount
        guard count > 0 else { return 0 }
        if UserDefaults.standard.object(forKey: storageKey) != nil {
            let saved = UserDefaults.standard.integer(forKey: storageKey)
            if saved >= 0, saved < count { return saved }
        }
        return 0
    }

    // MARK: - Download / Error states

    private var downloadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: loader.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 220)

            Text(loader.progressLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
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

// MARK: - Single visible page + swipe + edge taps

private struct ReaderPDFPageSurface: View {
    let document: PDFDocument
    @Binding var logicalPageIndex: Int
    let pageCount: Int
    let layoutDirection: LayoutDirection
    let contentWidth: CGFloat

    private let edgeFraction: CGFloat = 0.16

    var body: some View {
        GeometryReader { geo in
            let side = max(44, geo.size.width * edgeFraction)
            ZStack {
                ReaderPDFZoomablePage(
                    document: document,
                    logicalIndex: logicalPageIndex,
                    targetWidth: contentWidth
                )
                .id(logicalPageIndex)

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: side)
                        .onTapGesture(perform: goToAdjacentFromLeadingEdge)

                    Spacer(minLength: 0)

                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: side)
                        .onTapGesture(perform: goToAdjacentFromTrailingEdge)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        // Only act on predominantly horizontal swipes
                        guard abs(horizontal) > vertical, abs(horizontal) > 50 else { return }
                        if horizontal < 0 {
                            goToAdjacentFromTrailingEdge()
                        } else {
                            goToAdjacentFromLeadingEdge()
                        }
                    }
            )
        }
    }

    private func goToAdjacentFromLeadingEdge() {
        if layoutDirection == .rightToLeft { goForward() } else { goBackward() }
    }

    private func goToAdjacentFromTrailingEdge() {
        if layoutDirection == .rightToLeft { goBackward() } else { goForward() }
    }

    private func goForward() {
        guard logicalPageIndex < pageCount - 1 else { return }
        withAnimation(.easeOut(duration: 0.2)) { logicalPageIndex += 1 }
    }

    private func goBackward() {
        guard logicalPageIndex > 0 else { return }
        withAnimation(.easeOut(duration: 0.2)) { logicalPageIndex -= 1 }
    }
}

// MARK: - Zoomable page (static raster for now)

private struct ReaderPDFZoomablePage: View {
    let document: PDFDocument
    let logicalIndex: Int
    let targetWidth: CGFloat

    @State private var raster: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let raster {
                    Image(uiImage: raster)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.layoutDirection, .leftToRight)
        .task(id: "\(logicalIndex)-\(Int(targetWidth))") {
            raster = await PDFPageRasterizer.uiImage(
                document: document,
                pageIndex: logicalIndex,
                targetWidth: targetWidth
            )
        }
    }
}

// MARK: - Grid cell (larger thumbnail for the page browser)

private struct ReaderPDFGridCell: View {
    let document: PDFDocument
    let logicalIndex: Int
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var thumb: UIImage?

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.systemBackground))

                if let thumb {
                    Image(uiImage: thumb)
                        .resizable()
                        .interpolation(.medium)
                        .scaledToFit()
                        .padding(4)
                } else {
                    ProgressView()
                }
            }
            .aspectRatio(3.0 / 4.2, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.25),
                        lineWidth: isSelected ? 2.5 : 0.8
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
        .task(id: logicalIndex) {
            thumb = await PDFPageRasterizer.uiImage(
                document: document,
                pageIndex: logicalIndex,
                targetWidth: 100
            )
        }
    }
}

// MARK: - Thumbnail strip cell

private struct ReaderPDFThumbnailCell: View {
    let document: PDFDocument
    let logicalIndex: Int
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var thumb: UIImage?

    private let thumbWidth: CGFloat = 44
    private let thumbHeight: CGFloat = 62

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                if let thumb {
                    Image(uiImage: thumb)
                        .resizable()
                        .interpolation(.medium)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbWidth, height: thumbHeight)
                        .clipped()
                        .cornerRadius(4)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: thumbWidth, height: thumbHeight)
                        .cornerRadius(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
        .task(id: logicalIndex) {
            thumb = await PDFPageRasterizer.uiImage(
                document: document,
                pageIndex: logicalIndex,
                targetWidth: thumbWidth
            )
        }
    }
}

// MARK: - PDF rasterization

private enum PDFPageRasterizer {

    private static func displayBoxAndBounds(for page: PDFPage) -> (PDFDisplayBox, CGRect) {
        let crop = page.bounds(for: .cropBox)
        if crop.width > 8, crop.height > 8 {
            return (.cropBox, crop)
        }
        let media = page.bounds(for: .mediaBox)
        return (.mediaBox, media)
    }

    @MainActor
    static func uiImage(
        document: PDFDocument,
        pageIndex: Int,
        targetWidth: CGFloat
    ) async -> UIImage? {
        guard
            pageIndex >= 0, pageIndex < document.pageCount,
            let page = document.page(at: pageIndex),
            targetWidth >= 20
        else { return nil }

        let (box, rect) = displayBoxAndBounds(for: page)
        guard rect.width > 0 else { return nil }

        // Render at physical pixels so the image is sharp on Retina displays.
        // thumbnail(of:for:) treats the size as points and returns scale=1,
        // so we multiply by screen scale and re-wrap with the correct scale factor.
        let screenScale = UIScreen.main.scale
        let w = max(24, targetWidth) * screenScale
        let h = max(24, w * rect.height / rect.width)
        let size = CGSize(width: w, height: h)

        let raw = page.thumbnail(of: size, for: box)
        guard let cgImage = raw.cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: screenScale, orientation: raw.imageOrientation)
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
            state = .failed(String(localized: "reader_pdf_error_invalid_url"))
            return
        }

        do {
            let data = try await downloadWithProgress(from: url)
            cache.setData(data, for: cacheKey)
            guard let document = PDFDocument(data: data) else {
                state = .failed(String(localized: "reader_pdf_error_open_failed"))
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
