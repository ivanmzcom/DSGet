//
//  MainView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

// MARK: - Section Enum

enum AppSection: Hashable {
    case downloads
    case feeds
    case settings

    var label: String {
        switch self {
        case .downloads: return String.localized("tab.downloads")
        case .feeds: return String.localized("tab.feeds")
        case .settings: return String.localized("tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .downloads: return "arrow.down.circle"
        case .feeds: return "dot.radiowaves.left.and.right"
        case .settings: return "gear"
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var selectedSection: AppSection? = .downloads
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var statusFilter: TaskStatusFilter = .all

    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }
    private var feedsVM: FeedsViewModel { appViewModel.feedsViewModel }

    var body: some View {
        @Bindable var appVM = appViewModel

        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarColumn
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            offlineIndicator
        }
        .sheet(
            isPresented: $appVM.isShowingAddTask,
            onDismiss: { appVM.prefilledAddTaskURL = nil },
            content: { addTaskSheet }
        )
        .onChange(of: selectedSection) { oldValue, newValue in
            handleSectionChange(from: oldValue, to: newValue)
        }
        .onChange(of: appVM.isShowingSettings) { _, newValue in
            if newValue {
                selectedSection = .settings
                appVM.isShowingSettings = false
            }
        }
        .onChange(of: appVM.incomingTorrentURL) { _, newValue in
            if newValue != nil {
                selectedSection = .downloads
            }
        }
        .onChange(of: appVM.incomingMagnetURL) { _, newValue in
            if let url = newValue {
                appVM.prefilledAddTaskURL = url.absoluteString
                appVM.isShowingAddTask = true
                appVM.incomingMagnetURL = nil
                selectedSection = .downloads
            }
        }
        .onAppear {
            if selectedSection == .downloads {
                tasksVM.startAutoRefresh()
            }
        }
    }

    // MARK: - Sidebar Column

    @ViewBuilder
    private var sidebarColumn: some View {
        List(selection: $selectedSection) {
            Label(AppSection.downloads.label, systemImage: AppSection.downloads.icon)
                .tag(AppSection.downloads)
                .accessibilityIdentifier(AccessibilityID.Sidebar.downloads)

            Label(AppSection.feeds.label, systemImage: AppSection.feeds.icon)
                .tag(AppSection.feeds)
                .accessibilityIdentifier(AccessibilityID.Sidebar.feeds)

            Label(AppSection.settings.label, systemImage: AppSection.settings.icon)
                .tag(AppSection.settings)
                .accessibilityIdentifier(AccessibilityID.Sidebar.settings)
        }
        .navigationTitle("DSGet")
    }

    // MARK: - Content Column

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSection {
        case .downloads:
            TaskListContentView(
                statusFilter: statusFilter,
                onStatusFilterChange: { statusFilter = $0 }
            )
            .environment(appViewModel)

        case .feeds:
            FeedListContentView(
                favoriteFeedIDs: feedsVM.favoriteFeedIDs,
                onToggleFavorite: { feedsVM.toggleFavorite($0) }
            )
            .environment(appViewModel)

        case .settings:
            SettingsView()
                .environment(appViewModel)

        case nil:
            ContentUnavailableView(
                String.localized("tab.downloads"),
                systemImage: "sidebar.left"
            )
        }
    }

    // MARK: - Detail Column

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedSection {
        case .downloads:
            if let task = tasksVM.selectedTask {
                TaskDetailView(
                    task: task,
                    onTaskUpdated: { Task { await tasksVM.fetchTasks(forceRefresh: true) } },
                    onClose: { tasksVM.selectedTask = nil }
                )
                .id(task.id)
            } else {
                ContentUnavailableView(
                    String.localized("tasks.selectTask"),
                    systemImage: "arrow.down.circle"
                )
            }

        case .feeds:
            if let feedID = feedsVM.selectedFeedID,
               let feed = feedsVM.feeds.first(where: { $0.id == feedID }) {
                FeedDetailView(feed: feed, onClose: {
                    feedsVM.selectedFeedID = nil
                })
                .id(feed.id)
            } else {
                ContentUnavailableView(
                    String.localized("feeds.selectFeed"),
                    systemImage: "dot.radiowaves.left.and.right"
                )
            }

        case .settings, nil:
            ContentUnavailableView(
                String.localized("settings.title"),
                systemImage: "gear"
            )
        }
    }

    // MARK: - Helpers

    private func handleSectionChange(from oldValue: AppSection?, to newValue: AppSection?) {
        if oldValue == .downloads {
            tasksVM.stopAutoRefresh()
            tasksVM.selectedTask = nil
        }
        if oldValue == .feeds {
            feedsVM.selectedFeedID = nil
        }
        if newValue == .downloads {
            tasksVM.startAutoRefresh()
        }
    }

    // MARK: - Offline Indicator

    @ViewBuilder
    private var offlineIndicator: some View {
        if !appViewModel.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                Text(String.localized("offline.mode"))
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private var addTaskSheet: some View {
        NavigationStack {
            AddTaskView(
                preselectedTorrent: nil,
                prefilledURL: appViewModel.prefilledAddTaskURL,
                isFromSearch: appViewModel.prefilledAddTaskURL != nil
            )
        }
    }
}
