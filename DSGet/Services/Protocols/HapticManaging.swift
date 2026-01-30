//
//  HapticManaging.swift
//  DSGet
//
//  Protocol for haptic feedback management.
//

import UIKit

/// Protocol for centralized haptic feedback.
@MainActor
protocol HapticManaging {
    func prepare()
    func lightImpact()
    func mediumImpact()
    func heavyImpact()
    func selectionChanged()
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func success()
    func warning()
    func error()
}
