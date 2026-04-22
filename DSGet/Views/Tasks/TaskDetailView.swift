//
//  TaskDetailView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

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
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var selectedTab: TaskDetailTab = .general

    init(task: DownloadTask, onTaskUpdated: (() -> Void)? = nil, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: TaskDetailViewModel(task: task))
        self.onClose = onClose
        // Callbacks are set via the viewModel properties after creation
    }

    // MARK: - Helper Properties for Display

    private var statusTextAndColor: (text: String, color: Color) {
        switch viewModel.effectiveStatus {
        case "downloading": return ("Downloading", .blue)
        case "seeding", "finished": return ("Completed", .green)
        case "paused": return ("Paused", .orange)
        case "waiting": return ("Waiting", .gray)
        case "error": return ("Error", .red)
        default: return (viewModel.effectiveStatus.capitalized, .purple)
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
        guard !rawURI.isEmpty else { return nil }
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

    @ViewBuilder
    private var trackersSection: some View {
        if !viewModel.task.trackers.isEmpty {
            Section(String.localized("taskDetail.trackersCount").replacingOccurrences(of: "%d", with: "\(viewModel.task.trackers.count)")) {
                ForEach(viewModel.task.trackers) { tracker in
                    trackerRow(tracker)
                }
            }
        } else {
            ContentUnavailableView(
                String.localized("taskDetail.noTrackers"),
                systemImage: "antenna.radiowaves.left.and.right",
                description: Text(String.localized("taskDetail.noTrackers.description"))
            )
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
        AdaptiveLayoutReader { width in
            VStack(spacing: 0) {
                TaskDetailHero(
                    task: viewModel.task,
                    statusText: statusTextAndColor.text,
                    statusColor: statusTextAndColor.color,
                    progressValue: progressValue,
                    progressPercentage: progressPercentage,
                    downloadSpeed: downloadSpeed,
                    uploadSpeed: uploadSpeed,
                    etaText: etaText
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if width.prefersSegmentedTabs {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(TaskDetailTab.allCases, id: \.self) { tab in
                            Label(tab.rawValue, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                } else {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(TaskDetailTab.allCases, id: \.self) { tab in
                            Label(tab.rawValue, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

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
                #if os(macOS)
                .listStyle(.inset)
                #else
                .listStyle(.insetGrouped)
                #endif
            }
        }
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(viewModel.task.title)
        .toolbar { toolbarContent }
        .confirmationDialog(
            String.localized("taskDetail.delete.confirmTitle"),
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String.localized("taskDetail.delete.confirmButton"), role: .destructive) {
                Task {
                    await viewModel.deleteTask()
                    dismiss()
                }
            }
            Button(String.localized("general.cancel"), role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.task.title)\"?")
        }
        .sheet(isPresented: $viewModel.showingEditDestination) {
            EditDestinationSheet(
                task: viewModel.task,
                onSave: { newDestination in Task { await viewModel.editDestination(newDestination) } },
                onDismiss: { viewModel.showingEditDestination = false }
            )
        }
        .alert(String.localized("error.title"), isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if showsCloseButton {
            ToolbarItem(placement: .cancellationAction) {
                Button(String.localized("taskDetail.button.close")) {
                    onClose?()
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(
                viewModel.isTaskPaused
                    ? String.localized("taskDetail.button.resume")
                    : String.localized("taskDetail.button.pause")
            ) {
                Task { await viewModel.togglePauseResume() }
            }
            .disabled(!viewModel.canTogglePause)
        }
        ToolbarItem(placement: .destructiveAction) {
            Button(
                String.localized("taskDetail.button.delete"),
                systemImage: "trash",
                role: .destructive
            ) {
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

    private var showsCloseButton: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass != .compact
        #endif
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

private struct TaskDetailHero: View {
    let task: DownloadTask
    let statusText: String
    let statusColor: Color
    let progressValue: Double
    let progressPercentage: String
    let downloadSpeed: String?
    let uploadSpeed: String?
    let etaText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: task.type == .bt ? "arrow.down.circle.fill" : "tray.full.fill")
                    .foregroundStyle(statusColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                Spacer(minLength: 0)

                Text(progressPercentage)
                    .font(.title3.monospacedDigit().weight(.semibold))
            }

            ProgressView(value: progressValue)
                .tint(statusColor)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    detailMetric(title: "Downloaded", value: task.downloadedSize.formatted)
                    detailMetric(title: "Size", value: task.size.formatted)
                    if let downloadSpeed {
                        detailMetric(title: "Down", value: downloadSpeed + "/s")
                    }
                    if let uploadSpeed {
                        detailMetric(title: "Up", value: uploadSpeed + "/s")
                    }
                    if let etaText {
                        detailMetric(title: "ETA", value: etaText)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    detailMetric(title: "Downloaded", value: task.downloadedSize.formatted)
                    detailMetric(title: "Size", value: task.size.formatted)
                    if let downloadSpeed {
                        detailMetric(title: "Down", value: downloadSpeed + "/s")
                    }
                    if let uploadSpeed {
                        detailMetric(title: "Up", value: uploadSpeed + "/s")
                    }
                    if let etaText {
                        detailMetric(title: "ETA", value: etaText)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func detailMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}

// MARK: - TaskDetailView Extension (Tab Content & Sections)

private extension TaskDetailView {
    @ViewBuilder
    var generalTabContent: some View {
        List {
            overviewSection
            taskInfoSection
        }
    }

    @ViewBuilder
    var transferTabContent: some View {
        List {
            transferSection
        }
    }

    @ViewBuilder
    var trackersTabContent: some View {
        List {
            trackersSection
        }
    }

    @ViewBuilder
    var peersTabContent: some View {
        List {
            connectionSection
        }
    }

    @ViewBuilder
    var filesTabContent: some View {
        List {
            filesSection
        }
    }

    @ViewBuilder
    var overviewSection: some View {
        Section(String.localized("taskDetail.overview")) {
            LabeledContent(String.localized("taskDetail.title")) {
                Text(viewModel.task.title)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent(String.localized("taskDetail.status")) {
                Text(statusTextAndColor.text)
                    .foregroundStyle(statusTextAndColor.color)
            }
            LabeledContent(String.localized("taskDetail.progress")) {
                Text(progressPercentage)
            }
            ProgressView(value: progressValue)
                .tint(statusTextAndColor.color)
            LabeledContent(String.localized("taskDetail.totalSize")) { Text(viewModel.task.size.formatted) }
            LabeledContent(String.localized("taskDetail.downloaded")) { Text(viewModel.task.downloadedSize.formatted) }
            LabeledContent(String.localized("taskDetail.uploaded")) { Text(viewModel.task.uploadedSize.formatted) }
        }
    }

    @ViewBuilder
    var transferSection: some View {
        Section(String.localized("taskDetail.transferDetails")) {
            if let downloadSpeed {
                LabeledContent(String.localized("taskDetail.downloadSpeed")) { Text(downloadSpeed) }
            }
            if let uploadSpeed {
                LabeledContent(String.localized("taskDetail.uploadSpeed")) { Text(uploadSpeed) }
            }
            if let etaText {
                LabeledContent(String.localized("taskDetail.timeRemaining")) { Text(etaText) }
            }
            if let seedElapsed = viewModel.task.detail?.seedElapsed, seedElapsed > 0 {
                LabeledContent(String.localized("taskDetail.seedingTime")) { Text(formatTimeInterval(seedElapsed)) }
            }
            if !hasTransferDetails {
                ContentUnavailableView(
                    String.localized("taskDetail.noTransferData"),
                    systemImage: "arrow.down.arrow.up",
                    description: Text(String.localized("taskDetail.noTransferData.description"))
                )
            }
        }
    }

    @ViewBuilder
    var taskInfoSection: some View {
        Section(String.localized("taskDetail.taskInfo")) {
            LabeledContent(String.localized("taskDetail.type")) { Text(viewModel.task.type.displayName) }
            if let createTime = viewModel.task.detail?.createTime {
                LabeledContent(String.localized("taskDetail.created")) { Text(formatDate(createTime)) }
            }
            if let startTime = viewModel.task.detail?.startedTime {
                LabeledContent(String.localized("taskDetail.started")) { Text(formatDate(startTime)) }
            }
            if let completedTime = viewModel.task.detail?.completedTime {
                LabeledContent(String.localized("taskDetail.completed")) { Text(formatDate(completedTime)) }
            }
            destinationRow
            uriRow
        }
    }

    @ViewBuilder
    var destinationRow: some View {
        let destination = viewModel.task.destination
        if !destination.isEmpty {
            Button {
                viewModel.showingEditDestination = true
            } label: {
                LabeledContent(String.localized("taskDetail.destination")) {
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
    var uriRow: some View {
        if let rawURI = viewModel.task.detail?.uri {
            if let shareableURI {
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
                LabeledContent(String.localized("taskDetail.uri")) {
                    Text(rawURI)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    var connectionSection: some View {
        Section(String.localized("taskDetail.connectionInfo")) {
            if let detail = viewModel.task.detail, detail.hasPeerInfo {
                LabeledContent(String.localized("taskDetail.connectedPeers")) { Text("\(detail.connectedPeers)") }
                LabeledContent(String.localized("taskDetail.connectedSeeders")) { Text("\(detail.connectedSeeders)") }
                LabeledContent(String.localized("taskDetail.connectedLeechers")) { Text("\(detail.connectedLeechers)") }
                LabeledContent(String.localized("taskDetail.totalPeers")) { Text("\(detail.totalPeers)") }
            } else {
                ContentUnavailableView(
                    String.localized("taskDetail.noPeerInfo"),
                    systemImage: "person.2",
                    description: Text(String.localized("taskDetail.noPeerInfo.description"))
                )
            }
        }
    }

    @ViewBuilder
    var filesSection: some View {
        if !viewModel.task.files.isEmpty {
            Section(String.localized("taskDetail.filesCount").replacingOccurrences(of: "%d", with: "\(viewModel.task.files.count)")) {
                ForEach(viewModel.task.files) { file in
                    fileRow(file)
                }
            }
        } else {
            ContentUnavailableView(
                String.localized("taskDetail.noFiles"),
                systemImage: "doc.on.doc",
                description: Text(String.localized("taskDetail.noFiles.description"))
            )
        }
    }

    func fileRow(_ file: TaskFile) -> some View {
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
