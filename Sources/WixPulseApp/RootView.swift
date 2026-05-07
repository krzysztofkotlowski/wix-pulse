import SwiftUI
import WixPulseCore

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: Tab = .orders

    enum Tab: Hashable, CaseIterable {
        case orders, analytics, settings
        var label: String {
            switch self {
            case .orders: return "Orders"
            case .analytics: return "Analytics"
            case .settings: return "Settings"
            }
        }
        var icon: String {
            switch self {
            case .orders: return "shippingbox.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .settings: return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detail
        }
        .tint(Color.wpAccent)
        .background(Color.wpSurface.ignoresSafeArea())
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            BrandHeader()
                .padding(.horizontal, WP.Spacing.lg)
                .padding(.top, WP.Spacing.lg)
                .padding(.bottom, WP.Spacing.md)

            VStack(alignment: .leading, spacing: 4) {
                Text("Workspace").wpEyebrowStyle()
                    .padding(.horizontal, WP.Spacing.md)
                    .padding(.bottom, 2)
                ForEach(Tab.allCases, id: \.self) { tab in
                    SidebarItem(
                        label: tab.label,
                        icon: tab.icon,
                        isSelected: selection == tab,
                        badge: badge(for: tab)
                    ) { selection = tab }
                }
            }
            .padding(.horizontal, WP.Spacing.sm)

            Spacer()

            ConnectionFooter()
                .padding(WP.Spacing.md)
        }
        .background(Color.wpSurfaceRaised)
    }

    private func badge(for tab: Tab) -> Int? {
        guard tab == .orders else { return nil }
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let pending = store.filteredOrders
            .filter { !store.isPrinted($0.id) }
            .filter { $0.fulfillmentStatus == .notFulfilled || $0.fulfillmentStatus == .partiallyFulfilled }
            .filter { $0.paymentStatus == .paid || $0.paymentStatus == .partiallyPaid }
            .filter { $0.createdDate >= cutoff }
            .count
        return pending > 0 ? pending : nil
    }

    private var detail: some View {
        ZStack {
            Color.wpSurface.ignoresSafeArea()
            VStack(spacing: 0) {
                if let err = store.lastError, store.hasCredentials {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.wpDanger)
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        Button("Retry") { Task { await store.refresh() } }
                            .buttonStyle(.wpGhost)
                            .controlSize(.small)
                    }
                    .padding(.horizontal, WP.Spacing.lg)
                    .padding(.vertical, WP.Spacing.sm)
                    .background(Color.wpDanger.opacity(0.08))
                    .overlay(Rectangle().fill(Color.wpHairline).frame(height: 0.5), alignment: .bottom)
                }
                Group {
                    // Settings is ALWAYS reachable so the user can configure
                    // credentials on first launch. Orders/Analytics show the
                    // onboarding splash until credentials are provided.
                    switch selection {
                    case .settings:
                        SettingsView()
                    case .orders, .analytics:
                        if store.hasCredentials {
                            if selection == .orders { OrdersView() } else { AnalyticsView() }
                        } else {
                            OnboardingView(onGetStarted: { selection = .settings })
                        }
                    }
                }
            }
        }
        .navigationTitle(selection.label)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refresh() }
                } label: {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .disabled(!store.hasCredentials || store.isRefreshing)
                .help("Refresh now")
            }
        }
    }
}

private struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [Color.wpAccent, Color.wpAccent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.wpAccent.opacity(0.3), radius: 4, y: 2)
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("WixPulse").font(.system(.headline, design: .rounded, weight: .bold))
                Text("Order tracker").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct SidebarItem: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.wpAccent : .secondary)
                    .frame(width: 22)
                Text(label)
                    .font(.system(.callout, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
                if let badge {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.wpAccent.opacity(0.18), in: Capsule())
                        .foregroundStyle(Color.wpAccent)
                }
            }
            .padding(.horizontal, WP.Spacing.md)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.wpAccent.opacity(0.12) : (hovering ? Color.primary.opacity(0.05) : .clear))
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule().fill(Color.wpAccent).frame(width: 3, height: 14).offset(x: -2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct ConnectionFooter: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack(spacing: WP.Spacing.sm) {
            WPDot(store.hasCredentials ? .positive : .neutral)
            VStack(alignment: .leading, spacing: 0) {
                Text(store.hasCredentials ? "Connected" : "Not connected")
                    .font(.caption.weight(.semibold))
                if let date = store.snapshot?.summary.updatedAt {
                    HStack(spacing: 3) {
                        Text("Updated")
                        Text(date, style: .relative)
                        Text("ago")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(WP.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
    }
}

struct OnboardingView: View {
    var onGetStarted: () -> Void = {}

    var body: some View {
        VStack(spacing: WP.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.wpAccent.opacity(0.3), Color.wpAccent.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 132, height: 132)
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.wpAccent)
            }
            VStack(spacing: WP.Spacing.sm) {
                Text("Welcome to WixPulse")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Connect your Wix shop to start tracking orders, revenue, and your print queue right from your desktop.")
                    .font(.wpBody())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            Button(action: onGetStarted) {
                Label("Get started", systemImage: "arrow.right.circle.fill")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.wpPrimary)
            .keyboardShortcut(.defaultAction)
            Link(destination: URL(string: "https://dev.wix.com/docs/rest/articles/getting-started/api-keys")!) {
                Label("How to create an API key", systemImage: "arrow.up.right.square")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.wpAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
