//
//  SettingsHeaderView.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsHeaderView: View {
    let server: Server?
    let status: SettingsServerStatus

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DSGetIconBadge(systemName: "gearshape.fill", tint: .accentColor, size: 42)

            VStack(alignment: .leading, spacing: 8) {
                Text(String.localized("settings.title"))
                    .font(.largeTitle.weight(.semibold))

                Text(server?.displayName ?? String.localized("settings.server.noServer"))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                SettingsStatusBadge(status: status)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
