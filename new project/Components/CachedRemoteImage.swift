import CryptoKit
import ImageIO
import SwiftUI

struct CachedRemoteImage: View {
    let url: URL
    var showsProgressWhileLoading = false
    var loadFailed: Binding<Bool>?

    @Environment(\.displayScale) private var displayScale
    @State private var bitmap: CGImage?

    init(url: URL, showsProgressWhileLoading: Bool = false, loadFailed: Binding<Bool>? = nil) {
        self.url = url
        self.showsProgressWhileLoading = showsProgressWhileLoading
        self.loadFailed = loadFailed
        _bitmap = State(initialValue: Self.decode(DiskCache.remoteImages.data(for: Self.key(url))))
    }

    var body: some View {
        Group {
            if let bitmap {
                Image(decorative: bitmap, scale: displayScale).resizable()
            } else if loadFailed?.wrappedValue == true {
                Color.clear
            } else if showsProgressWhileLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
        .task(id: url.absoluteString) { await fetch() }
    }

    private func fetch() async {
        await MainActor.run {
            bitmap = Self.decode(DiskCache.remoteImages.data(for: Self.key(url)))
            loadFailed?.wrappedValue = false
        }
        guard bitmap == nil else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              !data.isEmpty,
              let cg = Self.decode(data) else {
            await MainActor.run { loadFailed?.wrappedValue = true }
            return
        }
        DiskCache.remoteImages.setData(data, for: Self.key(url))
        await MainActor.run {
            bitmap = cg
            loadFailed?.wrappedValue = false
        }
    }

    private static func key(_ url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func decode(_ data: Data?) -> CGImage? {
        guard let data,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
