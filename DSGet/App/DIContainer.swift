//
//  DIContainer.swift
//  DSGet
//
//  Dependency Injection Container.
//  Simplified architecture with Services replacing UseCases+Repositories.
//

import Foundation
import DSGetCore

// MARK: - Dependency Container

/// Main dependency injection container using lazy initialization.
/// All services are created on the main actor where they're used.
@MainActor
final class DIContainer {

    static let shared = DIContainer()

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

    /// File service for FileStation operations.
    lazy var fileService: FileServiceProtocol = FileService(apiClient: synologyAPIClient)
}

// MARK: - Convenience Accessors

/// Provides convenient access to the shared container.
@MainActor
enum DI {
    static var container: DIContainer { DIContainer.shared }

    // Services
    static var taskService: TaskServiceProtocol { container.taskService }
    static var authService: AuthServiceProtocol { container.authService }
    static var feedService: FeedServiceProtocol { container.feedService }
    static var fileService: FileServiceProtocol { container.fileService }

    // Infrastructure (for direct access when needed)
    static var connectivityService: ConnectivityServiceProtocol { container.connectivityService }
}
