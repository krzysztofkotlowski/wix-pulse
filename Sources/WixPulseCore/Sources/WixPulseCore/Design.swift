import SwiftUI

public enum WP {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 28
    }
    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
    }
}

public extension Color {
    /// Refined cool slate — replaces the previous gold/champagne accent.
    /// Light: deep blue-slate. Dark: soft platinum-blue. Reads as "expensive
    /// muted" rather than flashy.
    static let wpAccent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.62, green: 0.71, blue: 0.82, alpha: 1)   // #9FB5D1
            : NSColor(red: 0.27, green: 0.39, blue: 0.55, alpha: 1)   // #46638D
    })

    static let wpAccentSoft = wpAccent.opacity(0.14)
    static let wpPositive = Color(nsColor: .systemGreen)
    static let wpWarning = Color(nsColor: .systemOrange)
    static let wpDanger = Color(nsColor: .systemRed)
    static let wpMuted = Color.secondary

    /// Near-black base for dark mode (Tahoe-style charcoal), almost-white in light.
    static let wpSurface = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1)
            : NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
    })

    /// One step above the surface for cards and the sidebar.
    static let wpSurfaceRaised = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1)
            : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    })

    static let wpHairline = Color.primary.opacity(0.08)
}

public extension Font {
    static func wpDisplay(_ size: CGFloat = 36) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func wpNumber(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func wpTitle() -> Font { .system(.title3, design: .rounded, weight: .semibold) }
    static func wpHeader() -> Font { .system(.subheadline, design: .default, weight: .semibold) }
    static func wpEyebrow() -> Font { .system(size: 10, weight: .semibold, design: .default) }
    static func wpBody() -> Font { .system(.callout, design: .default, weight: .regular) }
    static func wpCaption() -> Font { .system(.caption, design: .default, weight: .medium) }
}

public struct WPCardStyle: ViewModifier {
    var padding: CGFloat
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: WP.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WP.Radius.lg, style: .continuous)
                    .strokeBorder(Color.wpHairline, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
    }
}

public extension View {
    func wpCard(padding: CGFloat = WP.Spacing.lg) -> some View {
        modifier(WPCardStyle(padding: padding))
    }

    func wpEyebrowStyle() -> some View {
        self.font(.wpEyebrow())
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

public struct WPSectionHeader: View {
    let icon: String?
    let title: String
    let trailing: AnyView?

    public init(icon: String? = nil, title: String, trailing: AnyView? = nil) {
        self.icon = icon
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: WP.Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.wpAccent)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title).wpEyebrowStyle()
            Spacer()
            if let trailing { trailing }
        }
    }
}

public struct WPChip: View {
    public enum Style { case neutral, accent, positive, warning, danger }
    let text: String
    let style: Style
    let icon: String?

    public init(_ text: String, style: Style = .neutral, icon: String? = nil) {
        self.text = text
        self.style = style
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            } else {
                Circle().fill(tint).frame(width: 5, height: 5)
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.3)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.18), lineWidth: 0.5))
    }

    private var tint: Color {
        switch style {
        case .neutral: return .secondary
        case .accent: return .wpAccent
        case .positive: return .wpPositive
        case .warning: return .wpWarning
        case .danger: return .wpDanger
        }
    }
}

public struct WPNumber: View {
    let value: String
    let size: CGFloat
    let tinted: Bool

    public init(_ value: String, size: CGFloat = 28, tinted: Bool = false) {
        self.value = value
        self.size = size
        self.tinted = tinted
    }

    public var body: some View {
        Text(value)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(tinted ? AnyShapeStyle(Color.wpAccent.gradient) : AnyShapeStyle(Color.primary))
    }
}

public struct WPMetricCard: View {
    let eyebrow: String
    let value: String
    let caption: String?
    let icon: String
    let tint: Color
    let tinted: Bool

    public init(eyebrow: String, value: String, caption: String? = nil, icon: String, tint: Color = .wpAccent, tinted: Bool = false) {
        self.eyebrow = eyebrow
        self.value = value
        self.caption = caption
        self.icon = icon
        self.tint = tint
        self.tinted = tinted
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.sm) {
            HStack {
                ZStack {
                    Circle().fill(tint.opacity(0.14)).frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                        .font(.system(size: 13, weight: .semibold))
                }
                Spacer()
            }
            Text(eyebrow).wpEyebrowStyle()
            WPNumber(value, size: 26, tinted: tinted)
            if let caption {
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .wpCard()
    }
}

public struct WPDot: View {
    public enum Kind { case positive, warning, danger, neutral }
    let kind: Kind
    public init(_ kind: Kind) { self.kind = kind }
    public var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: 8, height: 8)
            .overlay(Circle().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
    }
    private var color: Color {
        switch kind {
        case .positive: return .wpPositive
        case .warning: return .wpWarning
        case .danger: return .wpDanger
        case .neutral: return .secondary
        }
    }
}

public struct WPWidgetBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            Color.wpSurface
            LinearGradient(
                colors: [Color.wpAccent.opacity(0.035), .clear],
                startPoint: .topLeading,
                endPoint: .bottom
            )
        }
    }
}
