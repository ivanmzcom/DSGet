import WidgetKit
import SwiftUI

struct DownloadEntry: TimelineEntry {
    let date: Date
    let activeDownloads: Int
    let completedDownloads: Int
    let failedDownloads: Int
}

struct DSGetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DownloadEntry {
        DownloadEntry(date: Date(), activeDownloads: 3, completedDownloads: 12, failedDownloads: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (DownloadEntry) -> Void) {
        let entry = DownloadEntry(
            date: Date(),
            activeDownloads: 3,
            completedDownloads: 12,
            failedDownloads: 1
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DownloadEntry>) -> Void) {
        let currentDate = Date()
        let entry = DownloadEntry(
            date: currentDate,
            activeDownloads: 3,
            completedDownloads: 12,
            failedDownloads: 1
        )

        // Refresh every 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}
