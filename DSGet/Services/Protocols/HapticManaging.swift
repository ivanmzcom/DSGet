//
//  HapticManaging.swift
//  DSGet
//
//  Protocol for haptic feedback management.
//

enum AppHapticNotificationType {
    case success
    case warning
    case error
}

/// Protocol for centralized haptic feedback.
@MainActor
protocol HapticManaging {
    func prepare()
    func lightImpact()
    func mediumImpact()
    func heavyImpact()
    func selectionChanged()
    func notification(_ type: AppHapticNotificationType)
    func success()
    func warning()
    func error()
}
