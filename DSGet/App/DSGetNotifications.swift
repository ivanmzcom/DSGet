//
//  DSGetNotifications.swift
//  DSGet
//
//  Centralized notification names for app-wide communication.
//

import Foundation

// MARK: - Notification Names

enum DSGetNotification {
    static let addTaskRequested = Notification.Name("dsgetAddTaskRequested")
    static let addTaskFromClipboard = Notification.Name("dsgetAddTaskFromClipboard")
    static let searchRequested = Notification.Name("dsgetSearchRequested")
    static let refreshRequested = Notification.Name("dsgetRefreshRequested")
    static let pauseAllRequested = Notification.Name("dsgetPauseAllRequested")
    static let resumeAllRequested = Notification.Name("dsgetResumeAllRequested")
}
