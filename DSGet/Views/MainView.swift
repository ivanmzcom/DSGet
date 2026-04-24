//
//  MainView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

// MARK: - Main View

struct MainView: View {
    @Environment(AppViewModel.self) private var appViewModel
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif

    @SceneStorage("main.selectedSection")
    private var selectedSectionRawValue = AppSection.downloads.rawValue
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }
    private var feedsVM: FeedsViewModel { appViewModel.feedsViewModel }

    private var selectedSection: AppSection? {
        AppSection(rawValue: selectedSectionRawValue) ?? .downloads
    }

    private var selectedSectionBinding: Binding<AppSection?> {
        Binding(
            get: { selectedSection },
            set: { selectedSectionRawValue = $0?.rawValue ?? AppSection.downloads.rawValue }
        )
    }

    var body: some View {
        @Bindable var appVM = appViewModel

        rootContainer
            .overlay(alignment: .top) {
                if !appViewModel.isOnline {
                    OfflineIndicatorView()
                }
            }
            .sheet(item: addTaskPresentationBinding, content: addTaskSheet)
            .onChange(of: selectedSection) { oldValue, newValue in
                handleSectionChange(from: oldValue, to: newValue)
            }
            .onChange(of: appVM.isShowingSettings) { _, newValue in
                if newValue {
                    #if os(macOS)
                    openSettings()
                    #else
                    selectedSectionRawValue = AppSection.settings.rawValue
                    #endif
                    appVM.isShowingSettings = false
                }
            }
            .onChange(of: appVM.incomingTorrentURL) { _, newValue in
                if newValue != nil {
                    selectedSectionRawValue = AppSection.downloads.rawValue
                }
            }
            .onChange(of: appVM.incomingMagnetURL) { _, newValue in
                if let url = newValue {
                    appVM.presentAddTask(prefilledURL: url.absoluteString)
                    appVM.incomingMagnetURL = nil
                    selectedSectionRawValue = AppSection.downloads.rawValue
                }
            }
            .onAppear {
                if selectedSection == .downloads {
                    tasksVM.startAutoRefresh()
                }
            }
    }

    @ViewBuilder
    private var rootContainer: some View {
        #if os(iOS)
        if horizontalSizeClass == .compact {
            TabView(selection: selectedSectionBinding) {
                NavigationStack {
                    MainContentColumn(
                        appViewModel: appViewModel,
                        selectedSection: .downloads,
                        statusFilter: statusFilterBinding
                    )
                }
                .tabItem {
                    Label(AppSection.downloads.label, systemImage: AppSection.downloads.icon)
                        .accessibilityIdentifier(AccessibilityID.Sidebar.downloads)
                }
                .tag(Optional(AppSection.downloads))

                NavigationStack {
                    MainContentColumn(
                        appViewModel: appViewModel,
                        selectedSection: .feeds,
                        statusFilter: statusFilterBinding
                    )
                }
                .tabItem {
                    Label(AppSection.feeds.label, systemImage: AppSection.feeds.icon)
                        .accessibilityIdentifier(AccessibilityID.Sidebar.feeds)
                }
                .tag(Optional(AppSection.feeds))

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(AppSection.settings.label, systemImage: AppSection.settings.icon)
                        .accessibilityIdentifier(AccessibilityID.Sidebar.settings)
                }
                .tag(Optional(AppSection.settings))
            }
        } else {
            rootSplitView
        }
        #else
        rootSplitView
        #endif
    }

    @ViewBuilder
    private var rootSplitView: some View {
        #if os(macOS)
        let splitView = NavigationSplitView(columnVisibility: $columnVisibility) {
            MainSidebarView(selectedSection: selectedSectionBinding)
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 220)
        } detail: {
            MainContentColumn(
                appViewModel: appViewModel,
                selectedSection: selectedSection,
                statusFilter: statusFilterBinding
            )
            .navigationSplitViewColumnWidth(min: 520, ideal: 760, max: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        #else
        let splitView = NavigationSplitView(columnVisibility: $columnVisibility) {
            MainSidebarView(selectedSection: selectedSectionBinding)
        } content: {
            MainContentColumn(
                appViewModel: appViewModel,
                selectedSection: selectedSection,
                statusFilter: statusFilterBinding
            )
        } detail: {
            MainDetailColumn(
                appViewModel: appViewModel,
                selectedSection: selectedSection
            )
        }
        .navigationSplitViewStyle(.balanced)
        #endif

        #if os(macOS)
        if selectedSection == .downloads {
            splitView
                .searchable(
                    text: searchTextBinding,
                    placement: .toolbar,
                    prompt: String.localized("tasks.search.prompt")
                )
        } else if selectedSection == .feeds {
            splitView
                .searchable(
                    text: feedSearchTextBinding,
                    placement: .toolbar,
                    prompt: String.localized("feeds.search.prompt")
                )
        } else {
            splitView
        }
        #elseif os(iOS)
        if selectedSection == .downloads {
            splitView
                .searchable(
                    text: searchTextBinding,
                    prompt: String.localized("tasks.search.prompt")
                )
        } else if selectedSection == .feeds {
            splitView
                .searchable(
                    text: feedSearchTextBinding,
                    prompt: String.localized("feeds.search.prompt")
                )
        } else {
            splitView
        }
        #endif
    }

    private func handleSectionChange(from oldValue: AppSection?, to newValue: AppSection?) {
        if oldValue == .downloads {
            tasksVM.stopAutoRefresh()
        }
        if newValue == .downloads {
            tasksVM.startAutoRefresh()
        }
    }

    private func addTaskSheet(_ presentation: AddTaskPresentation) -> some View {
        NavigationStack {
            AddTaskView(
                preselectedTorrent: nil,
                prefilledURL: presentation.prefilledURL,
                isFromSearch: presentation.isFromSearch
            )
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { tasksVM.searchText },
            set: { tasksVM.searchText = $0 }
        )
    }

    private var feedSearchTextBinding: Binding<String> {
        Binding(
            get: { feedsVM.searchText },
            set: { feedsVM.searchText = $0 }
        )
    }

    private var statusFilterBinding: Binding<TaskStatusFilter> {
        Binding(
            get: { tasksVM.statusFilter },
            set: { tasksVM.statusFilter = $0 }
        )
    }

    private var addTaskPresentationBinding: Binding<AddTaskPresentation?> {
        Binding(
            get: { appViewModel.addTaskPresentation },
            set: { appViewModel.addTaskPresentation = $0 }
        )
    }
}
