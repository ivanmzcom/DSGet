import WidgetKit
import DSGetCore

struct DownloadEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetDownloadsSnapshot?
    let activeDownloads: Int
    let completedDownloads: Int
    let failedDownloads: Int
    let isConnected: Bool

    var mainItem: WidgetDownloadItem? {
        snapshot?.mainItem
    }
}

struct DSGetTimelineProvider: TimelineProvider {
    private let snapshotStore = WidgetSnapshotStore()

    func placeholder(in context: Context) -> DownloadEntry {
        previewEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (DownloadEntry) -> Void) {
        completion(snapshotEntry ?? emptyEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DownloadEntry>) -> Void) {
        let entry = snapshotEntry ?? emptyEntry
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private var snapshotEntry: DownloadEntry? {
        guard let snapshot = snapshotStore.load() else {
            return nil
        }

        return DownloadEntry(
            date: snapshot.updatedAt,
            snapshot: snapshot,
            activeDownloads: snapshot.activeCount,
            completedDownloads: snapshot.completedCount,
            failedDownloads: snapshot.failedCount,
            isConnected: snapshot.isConnected
        )
    }

    private var previewEntry: DownloadEntry {
        let previewItem = WidgetDownloadItem(
            id: "preview",
            fileName: "Ubuntu 24.04.iso",
            progress: 0.64,
            status: .downloading,
            totalBytes: 4_000_000_000,
            downloadedBytes: 2_560_000_000,
            downloadSpeedBytes: 4_200_000,
            uploadSpeedBytes: 320_000
        )
        let snapshot = WidgetDownloadsSnapshot(
            items: [previewItem],
            mainItemID: previewItem.id,
            isConnected: true
        )

        return DownloadEntry(
            date: snapshot.updatedAt,
            snapshot: snapshot,
            activeDownloads: snapshot.activeCount,
            completedDownloads: 12,
            failedDownloads: 0,
            isConnected: true
        )
    }

    private var emptyEntry: DownloadEntry {
        DownloadEntry(
            date: Date(),
            snapshot: WidgetDownloadsSnapshot(
                items: [],
                mainItemID: nil,
                isConnected: false
            ),
            activeDownloads: 0,
            completedDownloads: 0,
            failedDownloads: 0,
            isConnected: false
        )
    }
}
