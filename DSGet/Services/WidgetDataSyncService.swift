//
//  WidgetDataSyncService.swift
//  DSGet
//
//  Servicio para sincronizar datos de descargas con App Groups
//  para que el widget pueda acceder a ellos.
//

import Foundation
import DSGetCore

/// Servicio que sincroniza datos de tareas con App Groups para el widget.
public final class WidgetDataSyncService: WidgetDataSyncProtocol {
    public static let shared = WidgetDataSyncService()

    private let suiteName = "group.es.ncrd.DSGet"
    private let downloadsKey = "widget_downloads"
    private let mainDownloadKey = "widget_main_download"
    private let lastUpdateKey = "widget_last_update"
    private let connectionStatusKey = "widget_connection_status"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    // MARK: - Public Methods

    /// Guarda los datos de tareas actuales para el widget.
    /// - Parameter tasks: Lista de tareas a sincronizar.
    public func syncDownloads(_ tasks: [DownloadTask]) {
        // Convertir tasks a DownloadItem para el widget
        let downloadItems = tasks.map { mapToDownloadItem($0) }

        // Determinar la descarga principal (la más activa o más reciente)
        let mainDownload = tasks
            .filter { $0.status == .downloading || $0.status == .paused }
            .max(by: { ($0.transfer?.downloaded ?? .zero).bytes < ($1.transfer?.downloaded ?? .zero).bytes })
            .map { mapToDownloadItem($0) }

        guard let data = try? JSONEncoder().encode(downloadItems) else {
            #if DEBUG
            print("[WidgetDataSync] Failed to encode downloads")
            #endif
            return
        }

        userDefaults?.set(data, forKey: downloadsKey)

        if let mainData = try? JSONEncoder().encode(mainDownload) {
            userDefaults?.set(mainData, forKey: mainDownloadKey)
        }

        // Guardar timestamp de última actualización
        userDefaults?.set(Date(), forKey: lastUpdateKey)

        // Guardar estado de conexión
        userDefaults?.set(true, forKey: connectionStatusKey)

        #if DEBUG
        print("[WidgetDataSync] Synced \(downloadItems.count) downloads at \(Date())")
        #endif
    }

    /// Guarda el estado de error de conexión.
    public func setConnectionError() {
        userDefaults?.set(false, forKey: connectionStatusKey)
        userDefaults?.set(Date(), forKey: lastUpdateKey)
    }

    /// Obtiene la última fecha de actualización.
    public func lastUpdateDate() -> Date? {
        userDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    /// Verifica si hay datos disponibles para mostrar.
    public func hasCachedData() -> Bool {
        guard let data = userDefaults?.data(forKey: downloadsKey),
              let downloads = try? JSONDecoder().decode([DownloadItem].self, from: data) else {
            return false
        }
        return !downloads.isEmpty
    }

    /// Verifica si la última sincronización es reciente (menos de 1 hora).
    public func isRecentSync() -> Bool {
        guard let lastUpdate = lastUpdateDate() else { return false }
        return Date().timeIntervalSince(lastUpdate) < 3600 // 1 hora
    }

    // MARK: - Private Methods

    private func mapToDownloadItem(_ task: DownloadTask) -> DownloadItem {
        let status: DownloadStatus
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

        return DownloadItem(
            id: task.id.rawValue,
            fileName: task.title,
            progress: task.progress,
            status: status,
            totalBytes: task.size.bytes,
            downloadedBytes: task.transfer?.downloaded.bytes ?? 0
        )
    }
}

// MARK: - DownloadStatus

enum DownloadStatus: String, Codable {
    case downloading
    case paused
    case completed
    case failed
    case pending
}

// MARK: - DownloadItem

struct DownloadItem: Codable, Identifiable {
    let id: String
    let fileName: String
    let progress: Double
    let status: DownloadStatus
    let totalBytes: Int64
    let downloadedBytes: Int64
}

// MARK: - WidgetDownloadItem (compatibilidad con widget)

import WidgetKit

/// Modelo compatible con el widget para mostrar estado de descargas.
/// Esta estructura debe coincidir con DownloadItem en el widget.
public struct WidgetDownloadItem: Codable, Identifiable {
    public let id: UUID
    public let fileName: String
    public let progress: Double
    public let status: String
    public let totalBytes: Int64
    public let downloadedBytes: Int64

    public var progressPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(downloadedBytes) / Double(totalBytes)
    }
}

// MARK: - Error Display Names

extension WidgetDownloadItem {
    public var statusDisplayName: String {
        switch status.lowercased() {
        case "downloading": return "Descargando"
        case "completed": return "Completado"
        case "paused": return "Pausado"
        case "failed", "error": return "Error"
        default: return "Pendiente"
        }
    }

    public var statusIcon: String {
        switch status.lowercased() {
        case "downloading": return "arrow.down.circle"
        case "completed": return "checkmark.circle.fill"
        case "paused": return "pause.circle"
        case "failed", "error": return "xmark.circle.fill"
        default: return "clock"
        }
    }
}
