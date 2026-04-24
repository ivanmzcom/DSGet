//
//  SettingsSessionCard.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsSessionCard: View {
    let session: Session?
    let isRefreshingSession: Bool
    let isLoggingOut: Bool
    let refreshSession: () async -> Void
    let logout: () async -> Void

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.session"), systemImage: "person.crop.circle") {
            Text(String.localized("settings.session.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            SettingsSessionSummary(session: session)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    refreshButton
                    logoutButton
                }

                VStack(alignment: .leading, spacing: 12) {
                    refreshButton
                    logoutButton
                }
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await refreshSession() }
        } label: {
            HStack {
                if isRefreshingSession {
                    ProgressView()
                }
                Label(String.localized("settings.session.refresh"), systemImage: "arrow.clockwise")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isRefreshingSession || isLoggingOut)
        .accessibilityIdentifier(AccessibilityID.Settings.refreshSessionButton)
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            Task { await logout() }
        } label: {
            HStack {
                if isLoggingOut {
                    ProgressView()
                }
                Text(String.localized("settings.logout.button"))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(isLoggingOut || isRefreshingSession)
        .accessibilityIdentifier(AccessibilityID.Settings.logoutButton)
    }
}

private struct SettingsSessionSummary: View {
    let session: Session?

    var body: some View {
        if let session {
            let mayBeExpired = session.mightBeExpired()

            SettingsMessageSummary(
                title: mayBeExpired
                    ? String.localized("settings.session.status.expired")
                    : String.localized("settings.session.status.active"),
                detail: mayBeExpired
                    ? String.localized("settings.session.status.expired.description")
                    : String.localized("settings.session.status.active.description"),
                systemImage: mayBeExpired ? "clock.badge.exclamationmark" : "checkmark.circle.fill",
                tint: mayBeExpired ? .orange : .green
            )

            SettingsDetailRow(
                title: String.localized("settings.session.started"),
                value: settingsRelativeDate(session.createdAt)
            )
            SettingsDetailRow(title: String.localized("settings.session.server"), value: session.serverInfo)
        } else {
            SettingsMessageSummary(
                title: String.localized("settings.session.status.signedOut"),
                detail: String.localized("settings.session.status.signedOut.description"),
                systemImage: "person.crop.circle.badge.exclamationmark",
                tint: .orange
            )
        }
    }
}
