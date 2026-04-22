import SwiftUI
import DSGetCore

struct WatchDownloadsView: View {
    @Bindable var viewModel: WatchTasksViewModel

    var body: some View {
        List {
            if let serverName = viewModel.serverName {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(serverName)
                            .font(.headline)
                        if let lastUpdatedAt = viewModel.lastUpdatedAt {
                            Text(lastUpdatedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !viewModel.tasks.isEmpty {
                Section(String.watchLocalized("watch.summary.title")) {
                    HStack {
                        WatchMetricView(
                            title: String.watchLocalized("watch.summary.active"),
                            value: "\(viewModel.activeTasksCount)"
                        )
                        WatchMetricView(
                            title: String.watchLocalized("watch.summary.completed"),
                            value: "\(viewModel.completedTasksCount)"
                        )
                        WatchMetricView(
                            title: String.watchLocalized("watch.summary.down"),
                            value: viewModel.totalDownloadSpeed
                        )
                    }
                }
            }

            Section(String.watchLocalized("watch.downloads_title")) {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView(String.watchLocalized("watch.loading"))
                } else if viewModel.tasks.isEmpty {
                    WatchEmptyStateView()
                } else {
                    ForEach(viewModel.tasks) { task in
                        NavigationLink {
                            WatchTaskDetailView(
                                task: task,
                                isBusy: viewModel.isLoading,
                                onRefresh: { await viewModel.refresh() },
                                onTogglePause: { await viewModel.togglePause(task) },
                                onDelete: { await viewModel.delete(task) }
                            )
                        } label: {
                            WatchTaskRow(task: task)
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct WatchMetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WatchEmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(String.watchLocalized("watch.no_downloads"))
                .font(.headline)
            Text(String.watchLocalized("watch.add_tasks_hint"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct WatchTaskRow: View {
    let task: DownloadTask

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: task.watchStatusSymbol)
                    .foregroundStyle(task.watchStatusColor)

                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)

                Spacer(minLength: 6)

                Text(task.watchProgressText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Text(task.watchStatusText)
                .font(.caption)
                .foregroundStyle(task.watchStatusColor)

            ProgressView(value: task.progress)
                .tint(task.watchStatusColor)

            HStack {
                Text("\(task.downloadedSize.formatted) / \(task.size.formatted)")
                Spacer()
                if task.downloadSpeed.bytes > 0 {
                    Text(task.transfer?.formattedDownloadSpeed ?? task.downloadSpeed.formattedAsSpeed)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct WatchTaskDetailView: View {
    let task: DownloadTask
    let isBusy: Bool
    let onRefresh: @MainActor () async -> Void
    let onTogglePause: @MainActor () async -> Void
    let onDelete: @MainActor () async -> Void

    @State private var showsDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(task.watchStatusText, systemImage: task.watchStatusSymbol)
                        .foregroundStyle(task.watchStatusColor)

                    Text(task.title)
                        .font(.headline)

                    ProgressView(value: task.progress)
                        .tint(task.watchStatusColor)

                    HStack {
                        Text(task.downloadedSize.formatted)
                        Spacer()
                        Text(task.watchProgressText)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Section(String.watchLocalized("watch.detail.transfer")) {
                WatchValueRow(title: String.watchLocalized("watch.detail.download"), value: task.downloadSpeed.formattedAsSpeed)
                WatchValueRow(title: String.watchLocalized("watch.detail.upload"), value: task.uploadSpeed.formattedAsSpeed)
                WatchValueRow(title: String.watchLocalized("watch.detail.size"), value: task.size.formatted)
                if let eta = task.watchETA {
                    WatchValueRow(title: String.watchLocalized("watch.detail.eta"), value: eta)
                }
            }

            Section(String.watchLocalized("watch.detail.actions")) {
                if task.status.canPause || task.status.canResume {
                    Button {
                        Task { await onTogglePause() }
                    } label: {
                        Label(
                            task.status.canResume
                            ? String.watchLocalized("watch.action.resume")
                            : String.watchLocalized("watch.action.pause"),
                            systemImage: task.status.canResume ? "play.fill" : "pause.fill"
                        )
                    }
                    .disabled(isBusy)
                }

                Button {
                    Task { await onRefresh() }
                } label: {
                    Label(String.watchLocalized("watch.action.refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isBusy)

                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label(String.watchLocalized("watch.action.delete"), systemImage: "trash")
                }
                .disabled(isBusy)
            }
        }
        .navigationTitle(String.watchLocalized("watch.detail.title"))
        .confirmationDialog(
            String.watchLocalized("watch.delete.confirmation"),
            isPresented: $showsDeleteConfirmation
        ) {
            Button(String.watchLocalized("watch.action.delete"), role: .destructive) {
                Task { await onDelete() }
            }
            Button(String.watchLocalized("watch.action.cancel"), role: .cancel) {}
        }
    }
}

private struct WatchValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}

private extension DownloadTask {
    var watchStatusText: String {
        status.watchLocalizedTitle
    }

    var watchStatusColor: Color {
        switch status {
        case .downloading:
            return .blue
        case .seeding, .finished:
            return .green
        case .paused:
            return .orange
        case .waiting, .hashChecking, .finishing, .filehostingWaiting, .extracting:
            return .yellow
        case .error:
            return .red
        case .unknown:
            return .gray
        }
    }

    var watchStatusSymbol: String {
        switch status {
        case .downloading:
            return "arrow.down.circle.fill"
        case .seeding, .finished:
            return "checkmark.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .waiting, .filehostingWaiting:
            return "clock.fill"
        case .hashChecking:
            return "checkmark.shield.fill"
        case .finishing, .extracting:
            return "gearshape.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    var watchProgressText: String {
        "\(Int(progress * 100))%"
    }

    var watchETA: String? {
        guard let estimatedTimeRemaining else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: estimatedTimeRemaining)
    }
}

private extension TaskStatus {
    var watchLocalizedTitle: String {
        switch self {
        case .waiting, .filehostingWaiting:
            return String.watchLocalized("watch.status.waiting")
        case .downloading:
            return String.watchLocalized("watch.status.downloading")
        case .paused:
            return String.watchLocalized("watch.status.paused")
        case .finishing:
            return String.watchLocalized("watch.status.finishing")
        case .finished, .seeding:
            return String.watchLocalized("watch.status.completed")
        case .hashChecking:
            return String.watchLocalized("watch.status.checking")
        case .extracting:
            return String.watchLocalized("watch.status.extracting")
        case .error:
            return String.watchLocalized("watch.status.error")
        case .unknown(let value):
            return value.capitalized
        }
    }
}
