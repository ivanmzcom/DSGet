//
//  FilterTypes.swift
//  DSGetCore
//
//  Filter types shared between ViewModels.
//

import Foundation

// MARK: - Task Filters

/// Download task type filter.
public enum TaskTypeFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case bt = "BT"
    case e2k = "e2k"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .all: return "All"
        case .bt: return "BitTorrent"
        case .e2k: return "eMule"
        }
    }
}

/// Task status filter.
public enum TaskStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case downloading = "Downloading"
    case paused = "Paused"
    case completed = "Completed"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .all: return "All"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }
}

/// Task sort key.
public enum TaskSortKey: String, CaseIterable, Identifiable, Sendable {
    case date = "Date"
    case name = "Name"
    case downloadSpeed = "Download Speed"
    case uploadSpeed = "Upload Speed"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .date: return "Date"
        case .name: return "Name"
        case .downloadSpeed: return "Download Speed"
        case .uploadSpeed: return "Upload Speed"
        }
    }
}

/// Task sort direction.
public enum TaskSortDirection: String, CaseIterable, Identifiable, Sendable {
    case ascending = "Ascending"
    case descending = "Descending"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}
