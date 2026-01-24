//
//  HapticManager.swift
//  DSGet
//
//  Centralized haptic feedback manager for iOS.
//

import SwiftUI

// MARK: - Haptic Manager

@MainActor
final class HapticManager {

    static let shared = HapticManager()

    private init() {}

    // MARK: - iOS Haptics

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// Prepare generators for lower latency.
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Light impact feedback - for subtle UI interactions.
    func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Medium impact feedback - for standard interactions.
    func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Heavy impact feedback - for significant actions.
    func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    /// Selection changed feedback - for picker/list selection.
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }

    /// Notification feedback - for task completion states.
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    /// Success notification.
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification.
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification.
    func error() {
        notificationGenerator.notificationOccurred(.error)
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
