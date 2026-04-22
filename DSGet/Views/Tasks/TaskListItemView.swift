//
//  TaskListItemView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

struct TaskListItemView: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    let task: DownloadTask
    var isSelected = false
    var opensDetailInWindowOnDoubleClick = false
    var onDelete: (DownloadTask) -> Void // Callback to notify deletion
    var onTogglePause: (DownloadTask) -> Void // Callback to notify pause/resume

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    // MARK: - Computed Properties for Display

    private var title: String {
        task.title
    }

    private var status: TaskStatusPresentation {
        TaskStatusPresentation(status: task.status)
    }

    private var progress: Double {
        task.progress
    }

    private var progressPercentage: String {
        "\(Int(progress * 100))%"
    }

    private var sizeText: String {
        let downloaded = task.downloadedSize.formatted
        let total = task.size.formatted
        return "\(downloaded) of \(total)"
    }

    private var downloadSpeed: String? {
        guard let transfer = task.transfer, transfer.downloadSpeed.bytes > 0 else { return nil }
        return transfer.formattedDownloadSpeed
    }

    private var uploadSpeed: String? {
        guard let transfer = task.transfer, transfer.uploadSpeed.bytes > 0 else { return nil }
        return transfer.formattedUploadSpeed
    }

    private var etaText: String? {
        guard progress < 1,
              let eta = task.estimatedTimeRemaining,
              eta.isFinite && !eta.isInfinite else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: eta)
    }

    private var taskTypeLabel: String {
        task.type.displayName
    }

    private var ratioText: String? {
        guard task.shareRatio > 0 else { return nil }
        return String(format: "%.2f", task.shareRatio)
    }

    private var trailingRateText: String {
        let down = downloadSpeed ?? "0 B/s"
        let up = uploadSpeed ?? "0 B/s"
        return "D \(down)  U \(up)"
    }

    private var primaryRowColor: Color {
        #if os(iOS)
        isSelected ? .white : .primary
        #else
        .primary
        #endif
    }

    private var secondaryRowColor: Color {
        #if os(iOS)
        isSelected ? .white.opacity(0.82) : .secondary
        #else
        .secondary
        #endif
    }

    private var statusRowColor: Color {
        #if os(iOS)
        isSelected ? .white.opacity(0.92) : status.color
        #else
        status.color
        #endif
    }

    private var progressRowColor: Color {
        #if os(iOS)
        isSelected ? .white.opacity(0.92) : status.color
        #else
        status.color
        #endif
    }

    var body: some View {
        rowContent
    }

    @ViewBuilder
    private var rowContent: some View {
        let baseContent = taskContent
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .taskAccessibility(task)
            .taskRotorActions(
                onPause: { Task { await handleTogglePause() } },
                onResume: { Task { await handleTogglePause() } },
                onDelete: { Task { await handleDelete() } },
                isPaused: task.isPaused
            )
            .contextMenu { contextMenuContent }
            .alert(String.localized("taskItem.status.error"), isPresented: $showingErrorAlert) {
                Button(String.localized("general.ok")) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }

        #if os(macOS)
        baseContent
            .onTapGesture(count: 2) {
                guard opensDetailInWindowOnDoubleClick else { return }
                openWindow(value: task.id)
            }
        #else
        baseContent
            .hoverEffect(.highlight)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) { swipeActionsContent }
        #endif
    }

    // MARK: - Subviews

    @ViewBuilder
    private var taskContent: some View {
        #if os(iOS)
        iosLayout
        #else
        AdaptiveLayoutReader { width in
            if width == .expanded {
                expandedLayout
            } else {
                compactLayout
            }
        }
        #endif
    }

    #if os(iOS)
    @ViewBuilder
    private var iosLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: task.type == .bt ? "arrow.down.circle.fill" : "tray.full.fill")
                    .foregroundStyle(statusRowColor)
                    .frame(width: 18)

                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(primaryRowColor)

                Spacer(minLength: 0)

                Text(progressPercentage)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(primaryRowColor)
            }

            HStack(spacing: 8) {
                Text(status.text)
                    .foregroundStyle(statusRowColor)
                Text("•")
                Text(taskTypeLabel)
                if let etaText {
                    Text("•")
                    Text("ETA \(etaText)")
                }
            }
            .font(.caption)
            .foregroundStyle(secondaryRowColor)
            .lineLimit(1)

            ProgressBar(progress: progress, color: progressRowColor)
                .frame(height: 4)

            HStack(spacing: 8) {
                Text(sizeText)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let downloadSpeed {
                    Text("D \(downloadSpeed)")
                        .monospacedDigit()
                }

                if let uploadSpeed {
                    Text("U \(uploadSpeed)")
                        .monospacedDigit()
                }
            }
            .font(.caption2)
            .foregroundStyle(secondaryRowColor)
        }
    }
    #endif

    @ViewBuilder
    private var expandedLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            leadingColumn
            progressColumn(width: 86)
            trailingColumn(width: 120)
        }
    }

    @ViewBuilder
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            leadingColumn
            compactMetaRow
            ProgressBar(progress: progress, color: status.color)
                .frame(height: 5)
            compactFooterRow
        }
    }

    @ViewBuilder
    private var leadingColumn: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: task.type == .bt ? "arrow.down.circle" : "tray.full")
                .foregroundStyle(statusRowColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                    .foregroundStyle(primaryRowColor)

                HStack(spacing: 8) {
                    TaskInfoBadge(text: status.text, systemImage: "circle.fill", tint: statusRowColor)
                    TaskInfoBadge(text: taskTypeLabel, systemImage: "circle.dashed", tint: secondaryRowColor)
                    if let ratioText {
                        TaskInfoBadge(text: "Ratio \(ratioText)", systemImage: "arrow.triangle.swap", tint: secondaryRowColor)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func progressColumn(width: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(progressPercentage)
                .font(.body.monospacedDigit())
                .foregroundStyle(primaryRowColor)
            ProgressBar(progress: progress, color: progressRowColor)
                .frame(width: width, height: 5)
        }
        .font(.caption)
        .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private func trailingColumn(width: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(trailingRateText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(secondaryRowColor)

            Text(sizeText)
                .font(.caption)
                .foregroundStyle(secondaryRowColor)

            if let etaText {
                Text("ETA \(etaText)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(secondaryRowColor)
            }
        }
        .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private var compactMetaRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                Text(sizeText)
                if task.peers > 0 {
                    Text("Peers \(task.peers)")
                }
                if task.seeders > 0 {
                    Text("Seeds \(task.seeders)")
                }
                Spacer(minLength: 0)
                Text(progressPercentage)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sizeText)
                HStack(spacing: 12) {
                    if task.peers > 0 {
                        Text("Peers \(task.peers)")
                    }
                    if task.seeders > 0 {
                        Text("Seeds \(task.seeders)")
                    }
                }
            }
        }
        .font(.caption)
        .foregroundStyle(secondaryRowColor)
    }

    @ViewBuilder
    private var compactFooterRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Text(trailingRateText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(secondaryRowColor)
                if let etaText {
                    Text("ETA \(etaText)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(secondaryRowColor)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trailingRateText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(secondaryRowColor)
                if let etaText {
                    Text("ETA \(etaText)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(secondaryRowColor)
                }
            }
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            Task { await handleTogglePause() }
        } label: {
            Label(task.isPaused ? String.localized("taskItem.action.resume") : String.localized("taskItem.action.pause"),
                  systemImage: task.isPaused ? "play.fill" : "pause.fill")
        }
        .disabled(task.type == .emule && task.isCompleted)

        Button(role: .destructive) {
            Task { await handleDelete() }
        } label: {
            Label(String.localized("taskItem.action.delete"), systemImage: "trash")
        }

        Divider()

        if let uri = task.detail?.uri, !uri.isEmpty {
            Button {
                copyToClipboard(uri)
            } label: {
                Label(String.localized("taskItem.action.copyURL"), systemImage: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private var swipeActionsContent: some View {
        Button(role: .destructive) {
            Task { await handleDelete() }
        } label: {
            Label(String.localized("taskItem.action.delete"), systemImage: "trash")
        }
        .disabled(isLoading)

        if !(task.type == .emule && task.isCompleted) {
            Button {
                Task { await handleTogglePause() }
            } label: {
                Label(
                    task.isPaused
                        ? String.localized("taskItem.action.resume")
                        : String.localized("taskItem.action.pause"),
                    systemImage: task.isPaused ? "play.fill" : "pause.fill"
                )
            }
            .tint(.orange)
            .disabled(isLoading)
        }
    }

    // MARK: - Private Helper Functions

    private func handleDelete() async {
        isLoading = true
        errorMessage = nil
        showingErrorAlert = false

        // Call the onDelete closure, which will handle the API call and list update
        onDelete(task)

        // Note: The actual API call and error handling for the API call
        // will be done in TaskListView. This view just triggers the action.
        // If TaskListView needs to report an error back, it would need another callback.

        isLoading = false
    }

    private func handleTogglePause() async {
        isLoading = true
        errorMessage = nil
        showingErrorAlert = false

        onTogglePause(task)

        isLoading = false
    }

    private func copyToClipboard(_ text: String) {
        PlatformClipboard.copy(text)
    }
}

// MARK: - Subvistas (Redefined for compilation, ideally in a common file)

private struct StatusDot: View {
    var color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

private struct TaskInfoBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
    }
}

private struct SpeedBadge: View {
    var systemName: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.caption2.bold())
            Text(value)
                .font(.caption2)
                .monospacedDigit()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .foregroundStyle(color)
        .background(
            Capsule(style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}

private struct ProgressBar: View {
    var progress: CGFloat // 0.0 - 1.0
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.18))

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: clamped * geo.size.width)
            }
        }
    }
}
