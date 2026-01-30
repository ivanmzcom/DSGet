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
    lazy var synologyAPIClient: SynologyAPIClientProtocol = SynologyAPIClient(networkClient: networkClient)

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

    // MARK: - iOS Services

    /// Widget data sync service.
    lazy var widgetSyncService: WidgetDataSyncProtocol = WidgetDataSyncService.shared

    /// Spotlight indexer.
    lazy var spotlightIndexer: SpotlightIndexing = SpotlightIndexer.shared

    /// Haptic manager.
    lazy var hapticManager: HapticManaging = HapticManager.shared

    /// Recent folders service.
    lazy var recentFoldersService: RecentFoldersManaging = RecentFoldersService.shared
}

// MARK: - Convenience Accessors

/// Provides convenient access to the shared container.
@MainActor
enum DIService {
    static var container: DIContainer { DIContainer.shared }

    // Services
    static var taskService: TaskServiceProtocol { container.taskService }
    static var authService: AuthServiceProtocol { container.authService }
    static var feedService: FeedServiceProtocol { container.feedService }
    static var fileService: FileServiceProtocol { container.fileService }

    // Infrastructure (for direct access when needed)
    static var connectivityService: ConnectivityServiceProtocol { container.connectivityService }

    // iOS Services
    static var widgetSyncService: WidgetDataSyncProtocol { container.widgetSyncService }
    static var spotlightIndexer: SpotlightIndexing { container.spotlightIndexer }
    static var hapticManager: HapticManaging { container.hapticManager }
    static var recentFoldersService: RecentFoldersManaging { container.recentFoldersService }
}
