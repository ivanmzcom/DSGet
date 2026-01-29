//
//  DragDropHandlers.swift
//  DSGet
//
//  Drag and drop support for torrent files and magnet links.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Supported Drop Types

extension UTType {
    static let torrent = UTType(filenameExtension: "torrent") ?? .data
}

// MARK: - Drop Result

enum TorrentDropResult {
    case torrentFile(URL)
    case magnetLink(URL)
    case httpURL(URL)
    case none
}

// MARK: - Torrent Drop Delegate

struct TorrentDropDelegate: DropDelegate {
    let onDrop: (TorrentDropResult) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        // Accept file URLs (for .torrent files)
        if info.hasItemsConforming(to: [.fileURL]) {
            return true
        }
        // Accept regular URLs (for magnet links or HTTP torrent URLs)
        if info.hasItemsConforming(to: [.url]) {
            return true
        }
        // Accept plain text (for magnet links pasted as text)
        if info.hasItemsConforming(to: [.plainText]) {
            return true
        }
        return false
    }

    func performDrop(info: DropInfo) -> Bool {
        // Try file URL first (for .torrent files)
        if let item = info.itemProviders(for: [.fileURL]).first {
            _ = item.loadObject(ofClass: URL.self) { url, error in
                guard let url, error == nil else { return }

                if url.pathExtension.lowercased() == AppConstants.URLSchemes.torrentExtension {
                    DispatchQueue.main.async {
                        onDrop(.torrentFile(url))
                    }
                }
            }
            return true
        }

        // Try URL (for magnet links or HTTP URLs)
        if let item = info.itemProviders(for: [.url]).first {
            _ = item.loadObject(ofClass: URL.self) { url, error in
                guard let url, error == nil else { return }

                let result = classifyURL(url)
                DispatchQueue.main.async {
                    onDrop(result)
                }
            }
            return true
        }

        // Try plain text (for magnet links copied as text)
        if let item = info.itemProviders(for: [.plainText]).first {
            item.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let text = String(data: data, encoding: .utf8),
                      error == nil else { return }

                if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let result = classifyURL(url)
                    DispatchQueue.main.async {
                        onDrop(result)
                    }
                }
            }
            return true
        }

        return false
    }

    private func classifyURL(_ url: URL) -> TorrentDropResult {
        if url.scheme?.lowercased() == AppConstants.URLSchemes.magnet {
            return .magnetLink(url)
        } else if url.pathExtension.lowercased() == AppConstants.URLSchemes.torrentExtension {
            return .httpURL(url)
        } else if url.absoluteString.contains(".torrent") {
            return .httpURL(url)
        }
        return .none
    }
}

// MARK: - View Extension

extension View {
    /// Enables drop support for torrent files and magnet links.
    func torrentDropTarget(onDrop: @escaping (TorrentDropResult) -> Void) -> some View {
        self.onDrop(
            of: [.fileURL, .url, .plainText],
            delegate: TorrentDropDelegate(onDrop: onDrop)
        )
    }
}

// MARK: - Drop Zone View

struct TorrentDropZone<Content: View>: View {
    @State private var isTargeted = false
    let onDrop: (TorrentDropResult) -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .overlay {
                if isTargeted {
                    DropTargetOverlay()
                }
            }
            .onDrop(
                of: [.fileURL, .url, .plainText],
                isTargeted: $isTargeted,
                perform: { providers in
                    handleProviders(providers)
                }
            )
    }

    private func handleProviders(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url, error == nil else { return }

                if url.isFileURL {
                    if url.pathExtension.lowercased() == AppConstants.URLSchemes.torrentExtension {
                        DispatchQueue.main.async {
                            onDrop(.torrentFile(url))
                        }
                    }
                } else if url.scheme?.lowercased() == AppConstants.URLSchemes.magnet {
                    DispatchQueue.main.async {
                        onDrop(.magnetLink(url))
                    }
                } else if url.pathExtension.lowercased() == AppConstants.URLSchemes.torrentExtension ||
                          url.absoluteString.contains(".torrent") {
                    DispatchQueue.main.async {
                        onDrop(.httpURL(url))
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - Drop Target Overlay

private struct DropTargetOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)

                Text("Drop torrent file or magnet link")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                )
        }
        .padding(8)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    TorrentDropZone(onDrop: { result in
        print("Dropped: \(result)")
    }, content: {
        VStack {
            Text("Drop Zone")
                .padding()
        }
        .frame(width: 300, height: 200)
        .background(Color.gray.opacity(0.1))
    })
}
#endif
