//
//  TaskListItemView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import UIKit
import DSGetCore

struct TaskListItemView: View {

    let task: DownloadTask
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(title)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.9)

                // Status + percentage + size
                HStack(spacing: 8) {
                    StatusDot(color: status.color)
                    Text(status.text)
                    Text("• \(progressPercentage)")
                        .monospacedDigit()
                    Text("• \(sizeText)")
                    Spacer(minLength: 0)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Progress bar
                ProgressBar(progress: progress, color: status.color)
                    .frame(height: 6)

                // Speeds / ETA
                HStack(spacing: 10) {
                    if let downloadSpeed {
                        SpeedBadge(systemName: "arrow.down", value: downloadSpeed, color: .blue)
                    }
                    if let uploadSpeed {
                        SpeedBadge(systemName: "arrow.up", value: uploadSpeed, color: .purple)
                    }
                    if let etaText {
                        Text("ETA \(etaText)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        // Accessibility
        .taskAccessibility(task)
        .taskRotorActions(
            onPause: { Task { await handleTogglePause() } },
            onResume: { Task { await handleTogglePause() } },
            onDelete: { Task { await handleDelete() } },
            isPaused: task.isPaused
        )
        // Context Menu
        .contextMenu {
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
        .hoverEffect(.highlight)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                    Label(task.isPaused ? String.localized("taskItem.action.resume") : String.localized("taskItem.action.pause"), systemImage: task.isPaused ? "play.fill" : "pause.fill")
                }
                .tint(.orange)
                .disabled(isLoading)
            }
        }
        .alert(String.localized("taskItem.status.error"), isPresented: $showingErrorAlert) {
            Button(String.localized("general.ok")) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
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
        UIPasteboard.general.string = text
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
