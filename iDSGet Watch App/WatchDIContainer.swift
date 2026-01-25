//
//  WatchDIContainer.swift
//  iDSGet Watch App
//
//  Dependency Injection Container for watchOS.
//

import Foundation
import DSGetCore

// MARK: - Watch Dependency Container

/// Dependency injection container for watchOS.
/// Uses lazy initialization for services.
@MainActor
final class WatchDIContainer {

    static let shared = WatchDIContainer()

    private init() {}

    // MARK: - Infrastructure (Singletons)

    /// Network client for HTTP requests.
    lazy var networkClient: NetworkClientProtocol = NetworkClient.shared

    /// Network connectivity service.
    lazy var connectivityService: ConnectivityServiceProtocol = ConnectivityService.shared

    /// Secure storage (Keychain).
    lazy var secureStorage: SecureStorageProtocol = KeychainService.shared

    /// Synology API client.
    lazy var synologyAPIClient: SynologyAPIClient = SynologyAPIClient(networkClient: networkClient)

    // MARK: - Services

    /// Task service for download operations.
    lazy var taskService: TaskServiceProtocol = TaskService(
        apiClient: synologyAPIClient,
        connectivityService: connectivityService
    )

    /// Auth service for authentication and server management.
    lazy var authService: AuthServiceProtocol = AuthService(
        apiClient: synologyAPIClient,
        networkClient: networkClient,
        secureStorage: secureStorage
    )

    /// Feed service for RSS operations.
    lazy var feedService: FeedServiceProtocol = FeedService(
        apiClient: synologyAPIClient,
        connectivityService: connectivityService
    )
}

// MARK: - Convenience Accessors

/// Provides convenient access to the shared container.
@MainActor
enum WatchDI {
    static var container: WatchDIContainer { WatchDIContainer.shared }

    // Services
    static var taskService: TaskServiceProtocol { container.taskService }
    static var authService: AuthServiceProtocol { container.authService }
    static var feedService: FeedServiceProtocol { container.feedService }

    // Infrastructure
    static var connectivityService: ConnectivityServiceProtocol { container.connectivityService }
}
