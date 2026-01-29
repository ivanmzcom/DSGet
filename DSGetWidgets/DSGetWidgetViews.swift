import SwiftUI
import WidgetKit

struct DSGetWidgetEntryView: View {
    var entry: DownloadEntry

    var body: some View {
        switch WidgetFamily.systemSmall {
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
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text("DSGet")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.activeDownloads)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("Activas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: DownloadEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text("DSGet")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Label("\(entry.activeDownloads)", systemImage: "arrow.down.circle")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Text("Activas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Label("\(entry.completedDownloads)", systemImage: "checkmark.circle")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                    Text("Completadas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if entry.failedDownloads > 0 {
                    VStack(alignment: .leading) {
                        Label("\(entry.failedDownloads)", systemImage: "xmark.circle")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        Text("Fallidas")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: DownloadEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
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
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("\(entry.activeDownloads) Descargas Activas")
                            .font(.headline)
                        Text("Descargando archivos...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("\(entry.completedDownloads) Completadas")
                            .font(.headline)
                        Text("Archivos descargados exitosamente")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                if entry.failedDownloads > 0 {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                        VStack(alignment: .leading) {
                            Text("\(entry.failedDownloads) Fallidas")
                                .font(.headline)
                            Text("Revisa los errores")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview("Small", as: .systemSmall) {
    DSGetWidget()
} timeline: {
    DownloadEntry(date: .now, activeDownloads: 3, completedDownloads: 12, failedDownloads: 1)
}

#Preview("Medium", as: .systemMedium) {
    DSGetWidget()
} timeline: {
    DownloadEntry(date: .now, activeDownloads: 3, completedDownloads: 12, failedDownloads: 1)
}

#Preview("Large", as: .systemLarge) {
    DSGetWidget()
} timeline: {
    DownloadEntry(date: .now, activeDownloads: 3, completedDownloads: 12, failedDownloads: 1)
}
