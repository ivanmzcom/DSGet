import SwiftUI

enum DSGetDesign {
    static let cornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 18
    static let rowPadding: CGFloat = 12
    static let borderOpacity: Double = 0.08
    static let selectedBorderOpacity: Double = 0.35

    static var contentBackground: Color {
        #if os(macOS)
        Color.clear
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }
}

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

enum DSGetSurfaceStyle {
    case card
    case row
    case selectedRow
    case header
}

private struct DSGetSurfaceModifier: ViewModifier {
    let style: DSGetSurfaceStyle
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(surfaceFill)
            .overlay(surfaceStroke)
    }

    @ViewBuilder
    private var surfaceFill: some View {
        let shape = RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)

        switch style {
        case .card, .header:
            shape.fill(.regularMaterial)
        case .row:
            #if os(macOS)
            shape.fill(Color.clear)
            #else
            shape.fill(Color.secondary.opacity(0.07))
            #endif
        case .selectedRow:
            #if os(iOS)
            shape.fill(tint)
            #else
            shape.fill(tint.opacity(0.14))
            #endif
        }
    }

    @ViewBuilder
    private var surfaceStroke: some View {
        let shape = RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)

        switch style {
        case .selectedRow:
            shape.stroke(tint.opacity(DSGetDesign.selectedBorderOpacity), lineWidth: 1)
        case .card, .header:
            shape.stroke(Color.primary.opacity(DSGetDesign.borderOpacity), lineWidth: 1)
        case .row:
            #if os(macOS)
            shape.stroke(Color.clear, lineWidth: 1)
            #else
            shape.stroke(Color.primary.opacity(DSGetDesign.borderOpacity), lineWidth: 1)
            #endif
        }
    }
}

private struct DSGetContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(DSGetDesign.contentBackground)
    }
}

extension View {
    func dsgetSurface(_ style: DSGetSurfaceStyle = .card, tint: Color = .accentColor) -> some View {
        modifier(DSGetSurfaceModifier(style: style, tint: tint))
    }

    func dsgetContentBackground() -> some View {
        modifier(DSGetContentBackgroundModifier())
    }
}
