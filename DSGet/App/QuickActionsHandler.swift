//
//  QuickActionsHandler.swift
//  DSGet
//
//  Handles iOS Home Screen Quick Actions (3D Touch / Long Press).
//

import SwiftUI
import Combine
import UIKit

// MARK: - Quick Action Type

enum QuickActionType: String {
    case addTask = "com.dsget.addTask"
    case viewDownloads = "com.dsget.viewDownloads"
    case refresh = "com.dsget.refresh"

    var title: String {
        switch self {
        case .addTask:
            return String.localized("quickAction.addTask")

        case .viewDownloads:
            return String.localized("quickAction.viewDownloads")

        case .refresh:
            return String.localized("quickAction.refresh")
        }
    }

    var systemImage: String {
        switch self {
        case .addTask:
            return "plus.circle.fill"

        case .viewDownloads:
            return "arrow.down.circle.fill"

        case .refresh:
            return "arrow.clockwise"
        }
    }
}

// MARK: - Quick Actions Handler

@MainActor
final class QuickActionsHandler: ObservableObject {
    static let shared = QuickActionsHandler()

    @Published var pendingAction: QuickActionType?

    private init() {}

    /// Configures the static quick actions for the app.
    func configureQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickActionType.addTask.rawValue,
                localizedTitle: QuickActionType.addTask.title,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.addTask.systemImage)
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.viewDownloads.rawValue,
                localizedTitle: QuickActionType.viewDownloads.title,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.viewDownloads.systemImage)
            )
        ]
    }

    /// Handles a quick action shortcut item.
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else {
            return false
        }

        pendingAction = actionType
        return true
    }

    /// Updates the quick actions with dynamic content (e.g., active download count).
    func updateDynamicActions(activeDownloads: Int) {
        var items: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: QuickActionType.addTask.rawValue,
                localizedTitle: QuickActionType.addTask.title,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.addTask.systemImage)
            )
        ]

        if activeDownloads > 0 {
            items.append(
                UIApplicationShortcutItem(
                    type: QuickActionType.viewDownloads.rawValue,
                    localizedTitle: QuickActionType.viewDownloads.title,
                    localizedSubtitle: "\(activeDownloads) active",
                    icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.viewDownloads.systemImage)
                )
            )
        } else {
            items.append(
                UIApplicationShortcutItem(
                    type: QuickActionType.viewDownloads.rawValue,
                    localizedTitle: QuickActionType.viewDownloads.title,
                    localizedSubtitle: nil,
                    icon: UIApplicationShortcutIcon(systemImageName: QuickActionType.viewDownloads.systemImage)
                )
            )
        }

        UIApplication.shared.shortcutItems = items
    }

    /// Processes the pending action and clears it.
    func processPendingAction(appViewModel: AppViewModel) {
        guard let action = pendingAction else { return }

        switch action {
        case .addTask:
            appViewModel.isShowingAddTask = true

        case .viewDownloads:
            // Navigate to downloads - handled by MainView navigation state
            break

        case .refresh:
            Task {
                await appViewModel.refreshAll()
            }
        }

        pendingAction = nil
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Handles quick actions when the app becomes active.
    func handleQuickActions(appViewModel: AppViewModel) -> some View {
        self
            .onReceive(QuickActionsHandler.shared.$pendingAction) { action in
                guard action != nil else { return }
                QuickActionsHandler.shared.processPendingAction(appViewModel: appViewModel)
            }
    }
}
