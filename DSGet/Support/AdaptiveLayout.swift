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
                .foregroundStyle(.primary)

            content
        }
        .padding(DSGetDesign.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsgetSurface()
    }
}

struct DSGetIconBadge: View {
    let systemName: String
    var tint: Color = .accentColor
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous))
    }
}

struct DSGetMetricLabel: View {
    let title: String
    let value: String
    var systemImage: String?
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 14)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .frame(minWidth: 72, alignment: .leading)
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
