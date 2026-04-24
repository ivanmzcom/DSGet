//
//  SettingsServerStatus.swift
//  DSGet
//

import SwiftUI

enum SettingsServerStatus: Equatable {
    case unknown
    case checking
    case connected(Date)
    case signedOut
    case unavailable(String)
    case noServer

    var isChecking: Bool {
        if case .checking = self {
            return true
        }
        return false
    }

    var title: String {
        switch self {
        case .unknown:
            return String.localized("settings.server.status.unknown")
        case .checking:
            return String.localized("settings.server.status.checking")
        case .connected:
            return String.localized("settings.server.status.connected")
        case .signedOut:
            return String.localized("settings.server.status.signedOut")
        case .unavailable:
            return String.localized("settings.server.status.unavailable")
        case .noServer:
            return String.localized("settings.server.noServer")
        }
    }

    var detail: String {
        switch self {
        case .unknown:
            return String.localized("settings.server.status.unknown.description")
        case .checking:
            return String.localized("settings.server.status.checking.description")
        case .connected:
            return String.localized("settings.server.status.connected.description")
        case .signedOut:
            return String.localized("settings.server.status.signedOut.description")
        case .unavailable(let message):
            return message
        case .noServer:
            return String.localized("settings.server.noServer")
        }
    }

    var systemImage: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .checking:
            return "hourglass"
        case .connected:
            return "checkmark.circle.fill"
        case .signedOut:
            return "person.crop.circle.badge.exclamationmark"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        case .noServer:
            return "server.rack"
        }
    }

    var tint: Color {
        switch self {
        case .unknown, .noServer:
            return .secondary
        case .checking:
            return .accentColor
        case .connected:
            return .green
        case .signedOut, .unavailable:
            return .orange
        }
    }
}

func settingsRelativeDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}
