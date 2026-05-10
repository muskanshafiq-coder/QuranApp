//
//  ReaderQuranBooksStrip.swift
//

import SwiftUI
import Combine

struct ReaderQuranBooksStrip: View {
    private let bookWidth: CGFloat = 108
    private let bookHeight: CGFloat = 142
    private let corner: CGFloat = 14

    @StateObject private var viewModel = ReaderQuranBooksViewModel()
    @StateObject private var downloader = PDFLoader()
    @State private var selectedBook: ReaderQuranBook?
    @State private var pendingDownload: ReaderQuranBook?
    @State private var downloadingBook: ReaderQuranBook?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.books.isEmpty && viewModel.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            placeholderCell
                        }
                    } else {
                        ForEach(viewModel.books) { book in
                            bookCell(book)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let book = selectedBook {
                        ReaderPDFViewerView(book: book)
                    }
                },
                isActive: Binding(
                    get: { selectedBook != nil },
                    set: { if !$0 { selectedBook = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .alert(
            Text("quran_pro_download_title"),
            isPresented: Binding(
                get: { pendingDownload != nil },
                set: { if !$0 { pendingDownload = nil } }
            ),
            presenting: pendingDownload
        ) { book in
            Button("alert_cancel", role: .cancel) {}
            Button("alert_download") {
                downloadingBook = book
                Task { await downloader.start(book: book) }
            }
        } message: { _ in
            Text("quran_pro_download_message")
        }
        .fullScreenCover(isPresented: Binding(
            get: { downloadingBook != nil },
            set: { if !$0 { downloadingBook = nil } }
        )) {
            downloadingOverlay
                .presentationBackground(.clear)
        }
        .onReceive(downloader.$state) { state in
            switch state {
            case .ready:
                if let book = downloadingBook {
                    downloadingBook = nil
                    selectedBook = book
                    downloader.resetToIdle()
                }
            case .failed:
                downloadingBook = nil
            case .idle, .downloading:
                break
            }
        }
    }

    private var downloadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("reader_downloading_title")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("reader_downloading_status")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                ProgressView(value: downloader.progress)
                    .progressViewStyle(.linear)
                    .tint(.red)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(white: 0.13))
            )
            .padding(.horizontal, 32)
        }
    }

    private func bookCell(_ book: ReaderQuranBook) -> some View {
        Button {
            if QuranPDFDiskCache.isDownloaded(id: book.id) {
                selectedBook = book
            } else {
                pendingDownload = book
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: book.coverColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    spineDecoration(for: book)

                    AsyncImage(url: book.thumbnailURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.clear
                    }
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                }
                .frame(width: bookWidth, height: bookHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(
                            Color.white.opacity(book.coverStyle == .tajweed ? 0.15 : 0.35),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)

                Text(verbatim: book.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: bookWidth + 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(book.title)
        .accessibilityHint(book.category)
    }

    @ViewBuilder
    private func spineDecoration(for book: ReaderQuranBook) -> some View {
        switch book.coverStyle {
        case .tajweed:
            glyph("text.book.closed.fill")
        case .translation:
            glyph("globe")
        case .madinah:
            ribbon(color: Color.blue.opacity(0.45))
        case .standard:
            ribbon(color: Color.red.opacity(0.35))
        case .qiraat:
            ribbon(color: Color.yellow.opacity(0.55))
        case .generic:
            ribbon(color: Color.brown.opacity(0.45))
        }
    }

    private func glyph(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(.white.opacity(0.35))
    }

    private func ribbon(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: 10, height: bookHeight * 0.55)
            .offset(x: -bookWidth * 0.28)
    }

    private var placeholderCell: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(width: bookWidth, height: bookHeight)
                .overlay(
                    ProgressView()
                )
            Rectangle()
                .fill(Color(UIColor.tertiarySystemBackground))
                .frame(width: bookWidth - 16, height: 12)
                .clipShape(Capsule())
        }
    }
}
