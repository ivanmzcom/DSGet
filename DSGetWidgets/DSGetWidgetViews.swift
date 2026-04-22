import SwiftUI
import WidgetKit
import DSGetCore

struct DSGetWidgetEntryView: View {
    let entry: DownloadEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: DownloadEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            Spacer()

            if let mainItem = entry.mainItem {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mainItem.fileName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    ProgressView(value: mainItem.progress)
                        .tint(color(for: mainItem.status))
                    Text(progressLabel(for: mainItem))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                emptyState(label: entry.isConnected ? "Sin descargas activas" : "Abre DSGet para sincronizar")
            }
        }
        .padding()
    }

    private var header: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(entry.isConnected ? .blue : .orange)
            Text("DSGet")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if !entry.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func emptyState(label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.activeDownloads)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

struct MediumWidgetView: View {
    let entry: DownloadEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(entry.isConnected ? .blue : .orange)
                Text("DSGet")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let mainItem = entry.mainItem {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(mainItem.fileName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Spacer()
                        Text(progressLabel(for: mainItem))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: mainItem.progress)
                        .tint(color(for: mainItem.status))
                    HStack {
                        Text(statusLabel(for: mainItem.status))
                        Spacer()
                        if mainItem.status.isActive {
                            Text(rateLabel(bytesPerSecond: mainItem.downloadSpeedBytes))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.isConnected ? "Sin descargas activas" : "Abre la app para cargar tus descargas")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(entry.isConnected ? "El widget está al día, pero no hay actividad ahora mismo." : "El widget necesita un snapshot reciente compartido por DSGet.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 20) {
                statBlock(value: entry.activeDownloads, label: "Activas", icon: "arrow.down.circle", color: .blue)
                statBlock(value: entry.completedDownloads, label: "Completadas", icon: "checkmark.circle", color: .green)
                if entry.failedDownloads > 0 {
                    statBlock(value: entry.failedDownloads, label: "Fallidas", icon: "xmark.circle", color: .red)
                }
            }
        }
        .padding()
    }

    private func statBlock(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Label("\(value)", systemImage: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct LargeWidgetView: View {
    let entry: DownloadEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(entry.isConnected ? .blue : .orange)
                Text("DSGet")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 20) {
                if let mainItem = entry.mainItem {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            Image(systemName: icon(for: mainItem.status))
                                .font(.title3)
                                .foregroundStyle(color(for: mainItem.status))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mainItem.fileName)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(statusLabel(for: mainItem.status))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(progressLabel(for: mainItem))
                                .font(.headline)
                        }
                        ProgressView(value: mainItem.progress)
                            .tint(color(for: mainItem.status))
                        HStack {
                            Text(sizeLabel(for: mainItem))
                            Spacer()
                            if mainItem.status.isActive {
                                Text(rateLabel(bytesPerSecond: mainItem.downloadSpeedBytes))
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(color(for: mainItem.status).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    summaryCard(
                        title: entry.isConnected ? "Sin descargas activas" : "Abre DSGet en el iPhone",
                        subtitle: entry.isConnected ? "No hay transferencias en curso ahora mismo" : "El widget mostrará datos cuando la app sincronice un snapshot",
                        icon: entry.isConnected ? "tray.fill" : "iphone",
                        color: entry.isConnected ? .gray : .orange
                    )
                }

                summaryCard(
                    title: "\(entry.activeDownloads) activas",
                    subtitle: entry.isConnected ? "En curso ahora mismo" : "Sin conexión reciente",
                    icon: entry.isConnected ? "arrow.down.circle.fill" : "wifi.slash",
                    color: entry.isConnected ? .blue : .orange
                )

                summaryCard(
                    title: "\(entry.completedDownloads) completadas",
                    subtitle: "Listas en tu servidor",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                if entry.failedDownloads > 0 {
                    summaryCard(
                        title: "\(entry.failedDownloads) fallidas",
                        subtitle: "Necesitan revisión",
                        icon: "xmark.circle.fill",
                        color: .red
                    )
                }
            }

            Spacer()
        }
        .padding()
    }

    private func summaryCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func color(for status: WidgetDownloadStatus) -> Color {
    switch status {
    case .downloading:
        .blue
    case .paused:
        .orange
    case .completed:
        .green
    case .failed:
        .red
    case .pending:
        .gray
    }
}

private func icon(for status: WidgetDownloadStatus) -> String {
    switch status {
    case .downloading:
        "arrow.down.circle.fill"
    case .paused:
        "pause.circle.fill"
    case .completed:
        "checkmark.circle.fill"
    case .failed:
        "xmark.circle.fill"
    case .pending:
        "clock.fill"
    }
}

private func statusLabel(for status: WidgetDownloadStatus) -> String {
    switch status {
    case .downloading:
        "Descargando"
    case .paused:
        "Pausada"
    case .completed:
        "Completada"
    case .failed:
        "Error"
    case .pending:
        "Pendiente"
    }
}

private func progressLabel(for item: WidgetDownloadItem) -> String {
    "\(Int((item.progress * 100).rounded()))%"
}

private func sizeLabel(for item: WidgetDownloadItem) -> String {
    let current = ByteCountFormatter.string(fromByteCount: item.downloadedBytes, countStyle: .file)
    let total = ByteCountFormatter.string(fromByteCount: item.totalBytes, countStyle: .file)
    return "\(current) / \(total)"
}

private func rateLabel(bytesPerSecond: Int64) -> String {
    let value = ByteCountFormatter.string(fromByteCount: bytesPerSecond, countStyle: .file)
    return "\(value)/s"
}

#Preview("Small", as: .systemSmall) {
    DSGetWidget()
} timeline: {
    DownloadEntry(
        date: .now,
        snapshot: WidgetDownloadsSnapshot(
            items: [
                WidgetDownloadItem(
                    id: "preview",
                    fileName: "Ubuntu 24.04.iso",
                    progress: 0.64,
                    status: .downloading,
                    totalBytes: 4_000_000_000,
                    downloadedBytes: 2_560_000_000,
                    downloadSpeedBytes: 4_200_000
                )
            ],
            mainItemID: "preview",
            isConnected: true
        ),
        activeDownloads: 3,
        completedDownloads: 12,
        failedDownloads: 1,
        isConnected: true
    )
}

#Preview("Medium", as: .systemMedium) {
    DSGetWidget()
} timeline: {
    DownloadEntry(
        date: .now,
        snapshot: WidgetDownloadsSnapshot(
            items: [
                WidgetDownloadItem(
                    id: "preview",
                    fileName: "Ubuntu 24.04.iso",
                    progress: 0.64,
                    status: .downloading,
                    totalBytes: 4_000_000_000,
                    downloadedBytes: 2_560_000_000,
                    downloadSpeedBytes: 4_200_000
                )
            ],
            mainItemID: "preview",
            isConnected: true
        ),
        activeDownloads: 3,
        completedDownloads: 12,
        failedDownloads: 1,
        isConnected: true
    )
}

#Preview("Large", as: .systemLarge) {
    DSGetWidget()
} timeline: {
    DownloadEntry(
        date: .now,
        snapshot: WidgetDownloadsSnapshot(
            items: [
                WidgetDownloadItem(
                    id: "preview",
                    fileName: "Ubuntu 24.04.iso",
                    progress: 0.64,
                    status: .downloading,
                    totalBytes: 4_000_000_000,
                    downloadedBytes: 2_560_000_000,
                    downloadSpeedBytes: 4_200_000
                )
            ],
            mainItemID: "preview",
            isConnected: true
        ),
        activeDownloads: 3,
        completedDownloads: 12,
        failedDownloads: 1,
        isConnected: true
    )
}
