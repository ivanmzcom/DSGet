//
//  WidgetDataSyncService.swift
//  DSGet
//
//  Servicio para sincronizar datos de descargas con App Groups
//  para que el widget pueda acceder a ellos.
//

import Foundation
import DSGetCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Servicio que sincroniza datos de tareas con App Groups para el widget.
public final class WidgetDataSyncService: WidgetDataSyncProtocol {
    public static let shared = WidgetDataSyncService()

    private let snapshotStore = WidgetSnapshotStore()

    private init() {}

    // MARK: - Public Methods

    /// Guarda los datos de tareas actuales para el widget.
    /// - Parameter tasks: Lista de tareas a sincronizar.
    public func syncDownloads(_ tasks: [DownloadTask]) {
        let downloadItems = tasks.map { mapToDownloadItem($0) }
        let mainDownloadID = tasks
            .filter { $0.status == .downloading || $0.status == .paused }
            .max(by: { ($0.transfer?.downloaded ?? .zero).bytes < ($1.transfer?.downloaded ?? .zero).bytes })
            .map(\.id.rawValue)

        let snapshot = WidgetDownloadsSnapshot(
            items: downloadItems,
            mainItemID: mainDownloadID,
            isConnected: true
        )

        do {
            try snapshotStore.save(snapshot)
            reloadWidgets()
        } catch {
            #if DEBUG
            print("[WidgetDataSync] Failed to save snapshot: \(error)")
            #endif
        }

        #if DEBUG
        print("[WidgetDataSync] Synced \(downloadItems.count) downloads at \(Date())")
        #endif
    }

    /// Guarda el estado de error de conexión.
    public func setConnectionError() {
        let currentSnapshot = snapshotStore.load()
        let snapshot = WidgetDownloadsSnapshot(
            items: currentSnapshot?.items ?? [],
            mainItemID: currentSnapshot?.mainItemID,
            isConnected: false
        )
        try? snapshotStore.save(snapshot)
        reloadWidgets()
    }

    /// Obtiene la última fecha de actualización.
    public func lastUpdateDate() -> Date? {
        snapshotStore.load()?.updatedAt
    }

    /// Verifica si hay datos disponibles para mostrar.
    public func hasCachedData() -> Bool {
        !(snapshotStore.load()?.items.isEmpty ?? true)
    }

    /// Verifica si la última sincronización es reciente (menos de 1 hora).
    public func isRecentSync() -> Bool {
        guard let lastUpdate = lastUpdateDate() else { return false }
        return Date().timeIntervalSince(lastUpdate) < 3600
    }

    // MARK: - Private Methods

    private func mapToDownloadItem(_ task: DownloadTask) -> WidgetDownloadItem {
        let status: WidgetDownloadStatus
        switch task.status {
        case .downloading:
            status = .downloading
        case .paused:
            status = .paused
        case .finished, .seeding:
            status = .completed
        case .error:
            status = .failed
        case .waiting, .finishing, .hashChecking, .filehostingWaiting, .extracting, .unknown:
            status = .pending
        }

        return WidgetDownloadItem(
            id: task.id.rawValue,
            fileName: task.title,
            progress: task.progress,
            status: status,
            totalBytes: task.size.bytes,
            downloadedBytes: task.transfer?.downloaded.bytes ?? 0,
            downloadSpeedBytes: task.transfer?.downloadSpeed.bytes ?? 0,
            uploadSpeedBytes: task.transfer?.uploadSpeed.bytes ?? 0
        )
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
