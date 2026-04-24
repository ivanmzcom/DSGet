//
//  LoginHeaderView.swift
//  DSGet
//

import SwiftUI

struct LoginHeaderView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(String.localized("auth.login.title"))
                    .font(.largeTitle.weight(.semibold))

                Text(String.localized("auth.login.subtitle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
