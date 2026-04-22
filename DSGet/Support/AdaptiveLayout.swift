import SwiftUI

enum AdaptiveLayoutWidth: Equatable {
    case compact
    case medium
    case expanded

    init(width: CGFloat) {
        switch width {
        case ..<520:
            self = .compact
        case ..<900:
            self = .medium
        default:
            self = .expanded
        }
    }

    var contentMaxWidth: CGFloat {
        switch self {
        case .compact:
            520
        case .medium:
            720
        case .expanded:
            1040
        }
    }

    var usesTwoColumns: Bool {
        self == .expanded
    }

    var prefersSegmentedTabs: Bool {
        self != .compact
    }
}

struct AdaptiveLayoutReader<Content: View>: View {
    let content: (AdaptiveLayoutWidth) -> Content

    init(@ViewBuilder content: @escaping (AdaptiveLayoutWidth) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            content(AdaptiveLayoutWidth(width: proxy.size.width))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

struct AdaptiveSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
