//
//  SettingsAboutCard.swift
//  DSGet
//

import SwiftUI

struct SettingsAboutCard: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.about"), systemImage: "info.circle") {
            SettingsDetailRow(title: String.localized("settings.about.version"), value: appVersion)
        }
    }
}
