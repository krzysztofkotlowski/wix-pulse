import SwiftUI
import WixPulseCore

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var apiKey: String = ""
    @State private var siteId: String = ""
    @State private var accountId: String = ""
    @State private var refreshMinutes: Int = 15
    @State private var showSaved = false
    @State private var productSearch: String = ""
    @State private var apiKeyHasStored: Bool = false

    private static let apiKeyPlaceholder = "••••••••••••••••"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WP.Spacing.lg) {
                connectionCard
                refreshCard
                productFilterCard
                socialAccountsCard
            }
            .padding(WP.Spacing.xl)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            siteId = SharedStorage.shared.siteId ?? ""
            accountId = SharedStorage.shared.accountId ?? ""
            refreshMinutes = SharedStorage.shared.refreshIntervalMinutes
            apiKeyHasStored = Keychain.loadAPIKey() != nil
            if apiKeyHasStored { apiKey = Self.apiKeyPlaceholder }
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(
                icon: "key.fill",
                title: "WIX Connection",
                trailing: store.hasCredentials ? AnyView(WPChip("Connected", style: .positive)) : nil
            )
            VStack(spacing: 10) {
                LabeledField("API Key") {
                    SecureField("Paste your WIX API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledField("Site ID") {
                    TextField("e.g. 9c4f3b2a-…", text: $siteId)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledField("Account ID") {
                    TextField("Optional · only if your key spans multiple sites", text: $accountId)
                        .textFieldStyle(.roundedBorder)
                }
            }
            HStack {
                Link(destination: URL(string: "https://dev.wix.com/docs/rest/articles/getting-started/api-keys")!) {
                    Label("How to create a key", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.wpAccent)
                }
                Spacer()
                if let err = store.lastError {
                    Text(err).font(.caption).foregroundStyle(Color.wpDanger).lineLimit(2)
                }
                if showSaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.wpPositive)
                        .font(.caption.weight(.medium))
                }
                if store.hasCredentials {
                    Button("Disconnect") {
                        store.clearCredentials()
                        apiKey = ""; siteId = ""; accountId = ""
                    }
                    .buttonStyle(.wpDanger)
                }
                Button("Save") {
                    let keyToSave: String? = (apiKey == Self.apiKeyPlaceholder) ? nil : apiKey
                    store.saveCredentials(apiKey: keyToSave, siteId: siteId, accountId: accountId)
                    SharedStorage.shared.refreshIntervalMinutes = refreshMinutes
                    showSaved = true
                    if Keychain.loadAPIKey() != nil {
                        apiKey = Self.apiKeyPlaceholder
                        apiKeyHasStored = true
                    }
                    Task { await store.refresh() }
                }
                .buttonStyle(.wpPrimary)
                .keyboardShortcut(.defaultAction)
                .disabled(siteId.isEmpty || (apiKey.isEmpty && !apiKeyHasStored))
            }
        }
        .wpCard()
    }

    private var refreshCard: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "arrow.clockwise", title: "Refresh interval")
            HStack(spacing: 6) {
                ForEach([5, 15, 30, 60], id: \.self) { mins in
                    IntervalPill(minutes: mins, selected: refreshMinutes == mins) {
                        refreshMinutes = mins
                        SharedStorage.shared.refreshIntervalMinutes = mins
                        store.startAutoRefresh()
                    }
                }
                Spacer()
            }
            Text("Widgets refresh in the background at this interval. macOS may delay refreshes when on battery.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .wpCard()
    }

    private var productFilterCard: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(
                icon: "line.3.horizontal.decrease.circle.fill",
                title: "Product filter",
                trailing: AnyView(
                    Toggle("", isOn: Binding(
                        get: { store.productFilter.enabled },
                        set: { store.updateFilter(ProductFilter(enabled: $0, selectedProductIds: store.productFilter.selectedProductIds)) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                )
            )

            Text(store.productFilter.enabled
                 ? "Only orders containing the selected products will appear in the app and widgets."
                 : "Turn this on to track only the products you care about across the app and widgets.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if store.availableProducts.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "tray").foregroundStyle(.secondary)
                    Text("No products discovered yet. Connect your WIX shop and refresh.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.secondary)
                        TextField("Search products", text: $productSearch).textFieldStyle(.plain).font(.callout)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.wpHairline, lineWidth: 0.5))
                    Spacer()
                    Button("Select all") {
                        let all = Set(store.availableProducts.map(\.id))
                        store.updateFilter(ProductFilter(enabled: true, selectedProductIds: all))
                    }
                    .buttonStyle(.wpGhost)
                    .disabled(store.availableProducts.isEmpty)
                    Button("Clear") {
                        store.updateFilter(ProductFilter(enabled: store.productFilter.enabled, selectedProductIds: []))
                    }
                    .buttonStyle(.wpGhost)
                    .disabled(store.productFilter.selectedProductIds.isEmpty)
                }

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredProducts) { p in
                            ProductFilterRow(
                                product: p,
                                isOn: store.productFilter.selectedProductIds.contains(p.id),
                                disabled: !store.productFilter.enabled
                            ) { newValue in
                                var ids = store.productFilter.selectedProductIds
                                if newValue { ids.insert(p.id) } else { ids.remove(p.id) }
                                store.updateFilter(ProductFilter(enabled: store.productFilter.enabled, selectedProductIds: ids))
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)
                .background(Color.wpSurface, in: RoundedRectangle(cornerRadius: WP.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: WP.Radius.md).strokeBorder(Color.wpHairline, lineWidth: 0.5))
            }
        }
        .wpCard()
    }

    private var filteredProducts: [ProductInfo] {
        guard !productSearch.isEmpty else { return store.availableProducts }
        let q = productSearch.lowercased()
        return store.availableProducts.filter { $0.name.lowercased().contains(q) }
    }

    @State private var newInstagramHandle: String = ""
    @State private var manualCounts: [String: String] = [:]   // account.id -> text input
    @State private var fetchingId: String? = nil
    @State private var fetchFailed: Set<String> = []

    private var socialAccountsCard: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "person.crop.circle.badge.checkmark", title: "Social media")

            Text("Track follower counts and growth alongside your shop analytics. Instagram public-profile scraping is rate-limited; if auto-fetch fails, set the count manually and update it from your phone whenever you check your profile.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Add new Instagram account
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .foregroundStyle(Color.wpAccent)
                    .frame(width: 14)
                Text("@")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextField("instagram username", text: $newInstagramHandle)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let handle = newInstagramHandle.trimmingCharacters(in: CharacterSet(charactersIn: "@ /"))
                    guard !handle.isEmpty else { return }
                    let acct = SocialAccount(platform: .instagram, handle: handle, fetchSource: .auto)
                    store.addSocialAccount(acct)
                    newInstagramHandle = ""
                    Task {
                        fetchingId = acct.id
                        let ok = await store.refreshSocialAccount(acct)
                        if !ok { fetchFailed.insert(acct.id) }
                        fetchingId = nil
                    }
                }
                .buttonStyle(.wpPrimary)
                .disabled(newInstagramHandle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Existing accounts
            if !store.socialAccounts.isEmpty {
                Rectangle().fill(Color.wpHairline).frame(height: 0.5)
                VStack(spacing: 8) {
                    ForEach(store.socialAccounts) { account in
                        socialAccountRow(account)
                    }
                }
            }
        }
        .wpCard()
    }

    @ViewBuilder
    private func socialAccountRow(_ account: SocialAccount) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: account.platform.icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.wpAccent)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let url = account.platform.profileURL(account.handle) {
                        Link("@\(account.handle)", destination: url)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.primary)
                    } else {
                        Text("@\(account.handle)").font(.callout.weight(.semibold))
                    }
                    Text(account.platform.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(account.fetchSource == .auto ? "AUTO" : "MANUAL")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(account.fetchSource == .auto ? Color.wpPositive : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background((account.fetchSource == .auto ? Color.wpPositive : Color.secondary).opacity(0.12), in: Capsule())
                }
                HStack(spacing: 6) {
                    Text("\(account.followerCount)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.wpAccent)
                    Text("followers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let delta = account.dayOverDayChange, delta != 0 {
                        Text(delta > 0 ? "▲ \(delta) since last fetch" : "▼ \(abs(delta)) since last fetch")
                            .font(.caption2)
                            .foregroundStyle(delta > 0 ? Color.wpPositive : Color.wpDanger)
                    }
                }
                // Manual override
                HStack(spacing: 6) {
                    let binding = Binding(
                        get: { manualCounts[account.id] ?? "" },
                        set: { manualCounts[account.id] = $0 }
                    )
                    TextField("Update manually", text: binding)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 160)
                    Button("Set") {
                        if let n = Int(manualCounts[account.id]?.filter(\.isNumber) ?? "") {
                            store.setSocialFollowerCountManually(account, count: n)
                            manualCounts[account.id] = ""
                        }
                    }
                    .buttonStyle(.wpGhost)
                    .disabled((manualCounts[account.id] ?? "").isEmpty)

                    Button {
                        Task {
                            fetchingId = account.id
                            fetchFailed.remove(account.id)
                            let ok = await store.refreshSocialAccount(account)
                            if !ok { fetchFailed.insert(account.id) }
                            fetchingId = nil
                        }
                    } label: {
                        if fetchingId == account.id {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Try fetch", systemImage: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.wpGhost)

                    Spacer()

                    Button("Remove") { store.removeSocialAccount(account) }
                        .buttonStyle(.wpDanger)
                }
                if fetchFailed.contains(account.id) {
                    Text("Auto-fetch failed — Instagram blocked the request. Update the count manually for now.")
                        .font(.caption2)
                        .foregroundStyle(Color.wpWarning)
                }
            }
        }
        .padding(10)
        .background(Color.wpSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
    }
}

private struct LabeledField<Field: View>: View {
    let label: String
    @ViewBuilder let field: () -> Field
    init(_ label: String, @ViewBuilder field: @escaping () -> Field) {
        self.label = label
        self.field = field
    }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .trailing)
            field()
        }
    }
}

private struct IntervalPill: View {
    let minutes: Int
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(selected ? Color.white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(selected ? AnyShapeStyle(Color.wpAccent.gradient) : AnyShapeStyle(hovering ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04)))
                )
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
    private var label: String {
        minutes < 60 ? "\(minutes) min" : "\(minutes / 60) hr"
    }
}

private struct ProductFilterRow: View {
    let product: ProductInfo
    let isOn: Bool
    let disabled: Bool
    let onChange: (Bool) -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isOn ? "checkmark.square.fill" : "square")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isOn ? Color.wpAccent : Color.secondary)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text(product.name).font(.callout)
                Text("\(product.orderCount) order\(product.orderCount == 1 ? "" : "s")")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(hovering && !disabled ? Color.wpAccent.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onTapGesture { if !disabled { onChange(!isOn) } }
        .onHover { hovering = $0 }
        .opacity(disabled ? 0.5 : 1)
    }
}
