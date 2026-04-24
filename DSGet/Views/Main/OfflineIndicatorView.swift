import SwiftUI

struct OfflineIndicatorView: View {
    var body: some View {
        Label(String.localized("offline.mode"), systemImage: "wifi.slash")
            .font(.footnote)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.bar)
    }
}
