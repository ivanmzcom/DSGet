//
//  TaskDetailView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI

enum TaskDetailTab: String, CaseIterable {
    case general = "General"
    case transfer = "Transfer"
    case trackers = "Trackers"
    case peers = "Peers"
    case files = "Files"

    var icon: String {
        switch self {
        case .general: return "info.circle"
        case .transfer: return "arrow.down.arrow.up"
        case .trackers: return "antenna.radiowaves.left.and.right"
        case .peers: return "person.2"
        case .files: return "doc.on.doc"
        }
    }
}

struct TaskDetailView: View {

    @State private var viewModel: TaskDetailViewModel
    let onClose: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab: TaskDetailTab = .general

    init(task: DownloadTask, onTaskUpdated: (() -> Void)? = nil, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: TaskDetailViewModel(task: task))
        self.onClose = onClose
        // Callbacks are set via the viewModel properties after creation
    }

    // MARK: - Helper Properties for Display

    private var statusTextAndColor: (text: String, color: Color) {
        switch viewModel.effectiveStatus {
        case "downloading":
            return ("Downloading", .blue)
        case "seeding", "finished":
            return ("Completed", .green)
        case "paused":
            return ("Paused", .orange)
        case "waiting":
            return ("Waiting", .gray)
        case "error":
            return ("Error", .red)
        default:
            return (viewModel.effectiveStatus.capitalized, .purple)
        }
    }

    private var progressValue: Double {
        viewModel.task.progress
    }

    private var progressPercentage: String {
        "\(Int(progressValue * 100))%"
    }

    private var downloadSpeed: String? {
        guard let transfer = viewModel.task.transfer, transfer.downloadSpeed.bytes > 0 else { return nil }
        return transfer.formattedDownloadSpeed
    }

    private var uploadSpeed: String? {
        guard let transfer = viewModel.task.transfer, transfer.uploadSpeed.bytes > 0 else { return nil }
        return transfer.formattedUploadSpeed
    }

    private var etaText: String? {
        guard progressValue < 1,
              let eta = viewModel.task.estimatedTimeRemaining,
              eta.isFinite && !eta.isInfinite else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: eta)
    }

    private var hasTransferDetails: Bool {
        downloadSpeed != nil ||
        uploadSpeed != nil ||
        etaText != nil ||
        (viewModel.task.detail?.seedElapsed ?? 0) > 0
    }

    private var shareableURI: String? {
        guard let uri = viewModel.task.detail?.uri else { return nil }
        let rawURI = uri.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !rawURI.isEmpty else {
            return nil
        }

        let scheme: String?
        if let url = URL(string: rawURI), let parsedScheme = url.scheme {
            scheme = parsedScheme.lowercased()
        } else if let colonIndex = rawURI.firstIndex(of: ":") {
            scheme = String(rawURI[..<colonIndex]).lowercased()
        } else {
            scheme = nil
        }

        guard let scheme, !scheme.isEmpty else { return nil }

        let allowedSchemes: Set<String> = ["http", "https", "magnet", "ftp", "sftp", "ed2k"]
        return allowedSchemes.contains(scheme) ? rawURI : nil
    }

    // MARK: - Section Views

    @ViewBuilder
    private var generalTabContent: some View {
        List {
            overviewSection
            taskInfoSection
        }
    }

    @ViewBuilder
    private var transferTabContent: some View {
        List {
            transferSection
        }
    }

    @ViewBuilder
    private var trackersTabContent: some View {
        List {
            trackersSection
        }
    }

    @ViewBuilder
    private var peersTabContent: some View {
        List {
            connectionSection
        }
    }

    @ViewBuilder
    private var filesTabContent: some View {
        List {
            filesSection
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Title") {
                Text(viewModel.task.title)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("Status") {
                Text(statusTextAndColor.text)
                    .foregroundStyle(statusTextAndColor.color)
            }
            LabeledContent("Progress") {
                Text(progressPercentage)
            }
            ProgressView(value: progressValue)
                .tint(statusTextAndColor.color)
            LabeledContent("Total Size") { Text(viewModel.task.size.formatted) }
            LabeledContent("Downloaded") { Text(viewModel.task.downloadedSize.formatted) }
            LabeledContent("Uploaded") { Text(viewModel.task.uploadedSize.formatted) }
        }
    }

    @ViewBuilder
    private var transferSection: some View {
        Section("Transfer Details") {
            if let downloadSpeed = downloadSpeed {
                LabeledContent("Download Speed") { Text(downloadSpeed) }
            }
            if let uploadSpeed = uploadSpeed {
                LabeledContent("Upload Speed") { Text(uploadSpeed) }
            }
            if let etaText = etaText {
                LabeledContent("Time Remaining") { Text(etaText) }
            }
            if let seedElapsed = viewModel.task.detail?.seedElapsed, seedElapsed > 0 {
                LabeledContent("Seeding Time") { Text(formatTimeInterval(seedElapsed)) }
            }
            if !hasTransferDetails {
                ContentUnavailableView("No transfer data", systemImage: "arrow.down.arrow.up", description: Text("No transfer information available"))
            }
        }
    }

    @ViewBuilder
    private var taskInfoSection: some View {
        Section("Task Info") {
            LabeledContent("Type") { Text(viewModel.task.type.displayName) }
            if let createTime = viewModel.task.detail?.createTime {
                LabeledContent("Created") { Text(formatDate(createTime)) }
            }
            if let startTime = viewModel.task.detail?.startedTime {
                LabeledContent("Started") { Text(formatDate(startTime)) }
            }
            if let completedTime = viewModel.task.detail?.completedTime {
                LabeledContent("Completed") { Text(formatDate(completedTime)) }
            }
            destinationRow
            uriRow
        }
    }

    @ViewBuilder
    private var destinationRow: some View {
        let destination = viewModel.task.destination
        if !destination.isEmpty {
            Button {
                viewModel.showingEditDestination = true
            } label: {
                LabeledContent("Destination") {
                    HStack {
                        Text(destination)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var uriRow: some View {
        if let rawURI = viewModel.task.detail?.uri {
            if let shareableURI = shareableURI {
                ShareLink(item: shareableURI) {
                    HStack {
                        Text("URI")
                        Spacer()
                        Text(rawURI)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            } else {
                LabeledContent("URI") {
                    Text(rawURI)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var connectionSection: some View {
        Section("Connection Info") {
            if let detail = viewModel.task.detail, detail.hasPeerInfo {
                LabeledContent("Connected Peers") { Text("\(detail.connectedPeers)") }
                LabeledContent("Connected Seeders") { Text("\(detail.connectedSeeders)") }
                LabeledContent("Connected Leechers") { Text("\(detail.connectedLeechers)") }
                LabeledContent("Total Peers") { Text("\(detail.totalPeers)") }
            } else {
                ContentUnavailableView("No peer information", systemImage: "person.2", description: Text("No peer information available"))
            }
        }
    }

    @ViewBuilder
    private var filesSection: some View {
        if !viewModel.task.files.isEmpty {
            Section("Files (\(viewModel.task.files.count))") {
                ForEach(viewModel.task.files) { file in
                    fileRow(file)
                }
            }
        } else {
            ContentUnavailableView("No files", systemImage: "doc.on.doc", description: Text("No file information available"))
        }
    }

    private func fileRow(_ file: TaskFile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(file.name)
                    .font(.body)
                Spacer()
                Text(file.size.formatted)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: file.progress)
                .tint(.accentColor)
        }
        .opacity(file.isWanted ? 1.0 : 0.5)
    }

    @ViewBuilder
    private var trackersSection: some View {
        if !viewModel.task.trackers.isEmpty {
            Section("Trackers (\(viewModel.task.trackers.count))") {
                ForEach(viewModel.task.trackers) { tracker in
                    trackerRow(tracker)
                }
            }
        } else {
            ContentUnavailableView("No trackers", systemImage: "antenna.radiowaves.left.and.right", description: Text("No tracker information available"))
        }
    }

    private func trackerRow(_ tracker: TaskTracker) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tracker.url)
                    .font(.body)
                    .lineLimit(2)
                if let interval = tracker.updateInterval, interval > 0 {
                    Text("Update interval: \(interval)s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(tracker.status.displayName)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                ForEach(TaskDetailTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab content
            Group {
                switch selectedTab {
                case .general:
                    generalTabContent
                case .transfer:
                    transferTabContent
                case .trackers:
                    trackersTabContent
                case .peers:
                    peersTabContent
                case .files:
                    filesTabContent
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.task.title)
        .toolbar {
            if horizontalSizeClass != .compact {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onClose?()
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(viewModel.isTaskPaused ? "Resume" : "Pause") {
                    Task { await viewModel.togglePauseResume() }
                }
                .disabled(!viewModel.canTogglePause)
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    viewModel.showingDeleteConfirmation = true
                }
                .disabled(viewModel.isProcessingAction)
            }
            ToolbarItem(placement: .principal) {
                if viewModel.isProcessingAction {
                    ProgressView()
                }
            }
        }
        .confirmationDialog("Delete Task", isPresented: $viewModel.showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Task", role: .destructive) {
                Task {
                    await viewModel.deleteTask()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.task.title)\"?")
        }
        .sheet(isPresented: $viewModel.showingEditDestination) {
            EditDestinationSheet(task: viewModel.task, onSave: { newDestination in
                Task { await viewModel.editDestination(newDestination) }
            }, onDismiss: {
                viewModel.showingEditDestination = false
            })
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    // MARK: - Private Helper Functions

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "N/A"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Edit Destination Sheet

private struct EditDestinationSheet: View {
    let task: DownloadTask
    let onSave: (String) -> Void
    let onDismiss: () -> Void

    @State private var selectedPath: String = ""

    var body: some View {
        NavigationStack {
            FolderPickerView(
                selectedFolderPath: $selectedPath,
                onDismissSheet: onDismiss
            )
        }
        .onAppear {
            selectedPath = task.destination
        }
        .onChange(of: selectedPath) { _, newValue in
            if !newValue.isEmpty && newValue != task.destination {
                onSave(newValue)
                onDismiss()
            }
        }
    }
}
