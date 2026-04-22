import SwiftUI

struct OfflineIndicatorView: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(String.localized("offline.mode"))
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .padding(.top, 8)
    }
}
