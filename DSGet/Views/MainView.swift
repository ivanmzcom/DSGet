//
//  MainView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

// MARK: - Tab Enum

enum AppTab: Hashable {
    case downloads
    case feeds
    case settings

    var label: String {
        switch self {
        case .downloads: return "Downloads"
        case .feeds: return "Feeds"
        case .settings: return "Settings"
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

    @State private var selectedTab: AppTab = .downloads

    var body: some View {
        @Bindable var appVM = appViewModel

        TabView(selection: $selectedTab) {
            Tab(AppTab.downloads.label, systemImage: AppTab.downloads.icon, value: .downloads) {
                DownloadsTabView()
                    .environment(appViewModel)
            }

            Tab(AppTab.feeds.label, systemImage: AppTab.feeds.icon, value: .feeds) {
                FeedsTabView()
                    .environment(appViewModel)
            }

            Tab(AppTab.settings.label, systemImage: AppTab.settings.icon, value: .settings) {
                SettingsTabView()
                    .environment(appViewModel)
            }
        }
        .sheet(isPresented: $appVM.isShowingAddTask, onDismiss: {
            appVM.prefilledAddTaskURL = nil
        }) {
            addTaskSheet
        }
        .onChange(of: appVM.incomingTorrentURL) { _, newValue in
            if newValue != nil {
                selectedTab = .downloads
            }
        }
        .onChange(of: appVM.incomingMagnetURL) { _, newValue in
            if let url = newValue {
                appVM.prefilledAddTaskURL = url.absoluteString
                appVM.isShowingAddTask = true
                appVM.incomingMagnetURL = nil
                selectedTab = .downloads
            }
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private var addTaskSheet: some View {
        NavigationStack {
            AddTaskView(preselectedTorrent: nil, prefilledURL: appViewModel.prefilledAddTaskURL, isFromSearch: appViewModel.prefilledAddTaskURL != nil)
        }
    }
}

// MARK: - Downloads Tab View

struct DownloadsTabView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var statusFilter: TaskStatusFilter = .all

    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }

    var body: some View {
        NavigationSplitView {
            TaskListContentView(
                statusFilter: statusFilter,
                onStatusFilterChange: { newFilter in
                    statusFilter = newFilter
                }
            )
            .environment(appViewModel)
        } detail: {
            taskDetailContent
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            offlineIndicator
        }
        .onAppear {
            tasksVM.startAutoRefresh()
        }
        .onDisappear {
            tasksVM.stopAutoRefresh()
        }
    }

    @ViewBuilder
    private var taskDetailContent: some View {
        if let task = tasksVM.selectedTask {
            TaskDetailView(task: task, onTaskUpdated: {
                Task { await tasksVM.fetchTasks(forceRefresh: true) }
            }, onClose: {
                tasksVM.selectedTask = nil
            })
            .id(task.id)
        } else {
            ContentUnavailableView("Select a Task", systemImage: "arrow.down.circle")
        }
    }

    @ViewBuilder
    private var offlineIndicator: some View {
        if !appViewModel.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Offline Mode")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
        }
    }
}

// MARK: - Feeds Tab View

struct FeedsTabView: View {
    @Environment(AppViewModel.self) private var appViewModel

    private var feedsVM: FeedsViewModel { appViewModel.feedsViewModel }

    var body: some View {
        NavigationSplitView {
            FeedListContentView(
                favoriteFeedIDs: feedsVM.favoriteFeedIDs,
                onToggleFavorite: { feed in
                    feedsVM.toggleFavorite(feed)
                }
            )
            .environment(appViewModel)
        } detail: {
            feedDetailContent
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            offlineIndicator
        }
    }

    @ViewBuilder
    private var feedDetailContent: some View {
        if let feedID = feedsVM.selectedFeedID,
           let feed = feedsVM.feeds.first(where: { $0.id == feedID }) {
            FeedDetailView(feed: feed, onClose: {
                feedsVM.selectedFeedID = nil
            })
            .id(feed.id)
        } else {
            ContentUnavailableView("Select a Feed", systemImage: "dot.radiowaves.left.and.right")
        }
    }

    @ViewBuilder
    private var offlineIndicator: some View {
        if !appViewModel.isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Offline Mode")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
        }
    }
}

// MARK: - Settings Tab View

struct SettingsTabView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        NavigationStack {
            SettingsView()
                .environment(appViewModel)
        }
    }
}
