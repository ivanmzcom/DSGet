//
//  HapticManager.swift
//  DSGet
//
//  Centralized haptic feedback manager for iOS.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptic Manager

@MainActor
final class HapticManager: HapticManaging {
    static let shared = HapticManager()

    private init() {}

    #if canImport(UIKit)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    #endif

    /// Prepare generators for lower latency.
    func prepare() {
        #if canImport(UIKit)
        impactLight.prepare()
        impactMedium.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        #endif
    }

    /// Light impact feedback - for subtle UI interactions.
    func lightImpact() {
        #if canImport(UIKit)
        impactLight.impactOccurred()
        #endif
    }

    /// Medium impact feedback - for standard interactions.
    func mediumImpact() {
        #if canImport(UIKit)
        impactMedium.impactOccurred()
        #endif
    }

    /// Heavy impact feedback - for significant actions.
    func heavyImpact() {
        #if canImport(UIKit)
        impactHeavy.impactOccurred()
        #endif
    }

    /// Selection changed feedback - for picker/list selection.
    func selectionChanged() {
        #if canImport(UIKit)
        selectionGenerator.selectionChanged()
        #endif
    }

    /// Notification feedback - for task completion states.
    func notification(_ type: AppHapticNotificationType) {
        #if canImport(UIKit)
        let feedbackType: UINotificationFeedbackGenerator.FeedbackType

        switch type {
        case .success:
            feedbackType = .success
        case .warning:
            feedbackType = .warning
        case .error:
            feedbackType = .error
        }

        notificationGenerator.notificationOccurred(feedbackType)
        #endif
    }

    /// Success notification.
    func success() {
        notification(.success)
    }

    /// Warning notification.
    func warning() {
        notification(.warning)
    }

    /// Error notification.
    func error() {
        notification(.error)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Triggers light haptic feedback when the view appears.
    func hapticOnAppear() -> some View {
        self.onAppear {
            HapticManager.shared.lightImpact()
        }
    }

    /// Triggers selection haptic feedback when the value changes.
    func hapticOnChange<V: Equatable>(of value: V) -> some View {
        self.onChange(of: value) { _, _ in
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    enum HapticType {
        case light
        case medium
        case heavy
        case selection
    }

    let hapticType: HapticType

    init(_ hapticType: HapticType = .light) {
        self.hapticType = hapticType
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    triggerHaptic()
                }
            }
    }

    private func triggerHaptic() {
        switch hapticType {
        case .light:
            HapticManager.shared.lightImpact()

        case .medium:
            HapticManager.shared.mediumImpact()

        case .heavy:
            HapticManager.shared.heavyImpact()

        case .selection:
            HapticManager.shared.selectionChanged()
        }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var haptic: HapticButtonStyle { HapticButtonStyle() }
    static func haptic(_ type: HapticButtonStyle.HapticType) -> HapticButtonStyle {
        HapticButtonStyle(type)
    }
}
