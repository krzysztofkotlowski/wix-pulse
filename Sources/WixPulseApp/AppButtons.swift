import SwiftUI
import WixPulseCore

struct WPPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.wpAccent.gradient)
            )
            .foregroundStyle(Color.white)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .shadow(color: Color.wpAccent.opacity(0.25), radius: configuration.isPressed ? 0 : 4, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct WPGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    var destructive: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        let tint: Color = destructive ? .wpDanger : .primary
        return configuration.label
            .font(.system(.callout, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? tint.opacity(0.12) : tint.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(tint.opacity(0.18), lineWidth: 0.5)
            )
            .foregroundStyle(tint)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct WPIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .frame(width: 30, height: 30)
            .background(
                Circle().fill(configuration.isPressed ? Color.wpAccent.opacity(0.18) : Color.primary.opacity(0.06))
            )
            .overlay(Circle().strokeBorder(Color.wpHairline, lineWidth: 0.5))
            .foregroundStyle(.primary)
    }
}

extension ButtonStyle where Self == WPPrimaryButtonStyle { static var wpPrimary: WPPrimaryButtonStyle { .init() } }
extension ButtonStyle where Self == WPGhostButtonStyle {
    static var wpGhost: WPGhostButtonStyle { .init() }
    static var wpDanger: WPGhostButtonStyle { .init(destructive: true) }
}
extension ButtonStyle where Self == WPIconButtonStyle { static var wpIcon: WPIconButtonStyle { .init() } }
