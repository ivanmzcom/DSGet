//
//  FilterTypes.swift
//  DSGet
//
//  Filter types shared between ViewModels.
//

import Foundation

// MARK: - Task Filters

/// Download task type filter.
enum TaskTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case bt = "BT"
    case e2k = "e2k"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .bt: return "BitTorrent"
        case .e2k: return "eMule"
        }
    }
}

/// Task status filter.
enum TaskStatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case downloading = "Downloading"
    case paused = "Paused"
    case completed = "Completed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

/// Task sort key.
enum TaskSortKey: String, CaseIterable, Identifiable {
    case date = "Date"
    case name = "Name"
    case downloadSpeed = "Download Speed"
    case uploadSpeed = "Upload Speed"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date: return "Date"
        case .name: return "Name"
        case .downloadSpeed: return "Download Speed"
        case .uploadSpeed: return "Upload Speed"
        }
    }
}

/// Task sort direction.
enum TaskSortDirection: String, CaseIterable, Identifiable {
    case ascending = "Ascending"
    case descending = "Descending"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

