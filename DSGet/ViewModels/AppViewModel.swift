//
//  AppViewModel.swift
//  DSGet
//
//  ViewModel principal que coordina el estado global de la aplicación.
//

import Foundation
import SwiftUI
import DSGetCore

struct AddTaskPresentation: Identifiable, Equatable {
    let id = UUID()
    let prefilledURL: String?

    var isFromSearch: Bool {
        prefilledURL != nil
    }
}

// MARK: - AppViewModel

@MainActor
@Observable
final class AppViewModel {
    // MARK: - Child ViewModels

    let tasksViewModel: TasksViewModel
    let feedsViewModel: FeedsViewModel

    // MARK: - Authentication State

    var isLoggedIn: Bool = false

    var isCheckingAuth: Bool = true

    let otpService = OTPService()

    // MARK: - Network State

    private(set) var isOnline: Bool = true

    // MARK: - Server Info

    private(set) var currentServer: Server?

    var serverName: String? {
        currentServer?.displayName
    }

    // MARK: - Global Error State

    var globalError: DSGetError?
    var showingGlobalError: Bool = false

    // MARK: - Incoming URLs

    var incomingTorrentURL: URL?
    var incomingMagnetURL: URL?

    // MARK: - UI State

    var addTaskPresentation: AddTaskPresentation?
    var isShowingSettings: Bool = false

    // MARK: - Injected Dependencies

    private let authService: AuthServiceProtocol
    private let connectivityService: ConnectivityServiceProtocol

    // MARK: - Private State

    private var authenticationObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(
        tasksViewModel: TasksViewModel? = nil,
        feedsViewModel: FeedsViewModel? = nil,
        authService: AuthServiceProtocol? = nil,
        connectivityService: ConnectivityServiceProtocol? = nil
    ) {
        self.tasksViewModel = tasksViewModel ?? TasksViewModel()
        self.feedsViewModel = feedsViewModel ?? FeedsViewModel()

        self.authService = authService ?? DIService.authService
        self.connectivityService = connectivityService ?? DIService.connectivityService

        setupAuthenticationObserver()

        Task {
            await checkLoginStatus()
            await updateOnlineStatus()
            await loadServer()
        }
    }

    // MARK: - Private Setup

    private func setupAuthenticationObserver() {
        authenticationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAuthenticationRequired()
            }
        }
    }

    private func handleAuthenticationRequired() {
        // Only handle if currently logged in to avoid duplicate handling
        guard isLoggedIn else { return }

        #if DEBUG
        print("[AppViewModel] Authentication required - showing login screen")
        #endif

        // Clear session but keep server info for re-login
        isLoggedIn = false
    }

    // MARK: - Public Methods

    /// Loads the current server info.
    func loadServer() async {
        currentServer = try? await authService.getServer()
    }

    /// Updates the online status from the connectivity service.
    func updateOnlineStatus() async {
        isOnline = connectivityService.isConnected
    }

    func checkLoginStatus() async {
        defer { isCheckingAuth = false }

        do {
            let session = try await authService.validateSession()
            isLoggedIn = session != nil
        } catch {
            isLoggedIn = false
        }
    }

    func currentSession() -> Session? {
        try? authService.getCurrentSession()
    }

    func validateCurrentSession() async throws -> Session? {
        let session = try await authService.validateSession()
        isLoggedIn = session != nil
        return session
    }

    func refreshCurrentSession() async throws -> Session {
        let session = try await authService.refreshSession()
        isLoggedIn = true
        return session
    }

    func testCurrentServerConnection() async throws {
        guard let currentServer else {
            throw DSGetError.authentication(.notLoggedIn)
        }

        try await authService.testConnection(configuration: currentServer.configuration)
    }

    func recentServers() async -> [Server] {
        await authService.getRecentServers()
    }

    func clearServerHistory() async {
        await authService.clearRecentServers()
    }

    func logout() async {
        do {
            try await authService.logout()
        } catch {
            #if DEBUG
            print("Logout error: \(error)")
            #endif
        }

        // Clear server data
        try? await authService.removeServer()

        currentServer = nil
        isLoggedIn = false
    }

    func handleIncomingURL(_ url: URL) {
        if url.scheme?.lowercased() == AppConstants.URLSchemes.magnet {
            incomingMagnetURL = url
        } else if url.pathExtension.lowercased() == AppConstants.URLSchemes.torrentExtension {
            incomingTorrentURL = url
        } else if url.scheme?.lowercased() == AppConstants.URLSchemes.dsget {
            handleDeepLink(url)
        }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.tasksViewModel.refresh() }
            group.addTask { await self.feedsViewModel.refresh() }
        }
    }

    func showError(_ error: DSGetError) {
        globalError = error
        showingGlobalError = true
    }

    func clearError() {
        globalError = nil
        showingGlobalError = false
    }

    func presentAddTask(prefilledURL: String? = nil) {
        addTaskPresentation = AddTaskPresentation(prefilledURL: prefilledURL)
    }

    func dismissAddTaskPresentation() {
        addTaskPresentation = nil
    }

    /// Called after successful login to update state.
    func onLoginSuccess() async {
        await loadServer()
        isLoggedIn = true
        await refreshAll()
    }

    // MARK: - Private Methods

    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch components.host {
        case AppConstants.DeepLinkHosts.add:
            if let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value {
                presentAddTask(prefilledURL: urlParam)
            }

        case AppConstants.DeepLinkHosts.settings:
            isShowingSettings = true

        default:
            break
        }
    }
}
