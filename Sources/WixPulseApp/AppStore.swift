import Foundation
import WixPulseCore

@MainActor
final class AppStore: ObservableObject {
    @Published var snapshot: CachedSnapshot?
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var hasCredentials: Bool = false
    @Published var productFilter: ProductFilter = .none
    @Published var printedOrderIds: Set<String> = []
    @Published var socialAccounts: [SocialAccount] = []

    /// Background refresh loop. Cancelled when interval changes or credentials clear.
    private var autoRefreshTask: Task<Void, Never>?

    func bootstrap() async {
        // SCREENSHOTS-MOCK BRANCH ONLY — load seed data and skip the network.
        // Reverted to real WIX API on the `main` branch.
        snapshot = MockData.snapshot
        SharedStorage.shared.saveSnapshot(MockData.snapshot)
        printedOrderIds = MockData.printedOrderIds
        for id in MockData.printedOrderIds { SharedStorage.shared.markPrinted(id) }
        productFilter = SharedStorage.shared.productFilter
        // Seed mock social accounts so the Analytics tab's Social presence
        // section renders for screenshots.
        socialAccounts = MockData.socialAccounts
        SharedStorage.shared.socialAccounts = MockData.socialAccounts
        hasCredentials = true
        await Refresher.shared.notifyWidgets()
    }

    func addSocialAccount(_ account: SocialAccount) {
        var existing = socialAccounts.filter { $0.id != account.id }
        existing.append(account)
        socialAccounts = existing
        SharedStorage.shared.socialAccounts = existing
    }

    func removeSocialAccount(_ account: SocialAccount) {
        socialAccounts.removeAll { $0.id == account.id }
        SharedStorage.shared.socialAccounts = socialAccounts
    }

    func setSocialFollowerCountManually(_ account: SocialAccount, count: Int) {
        guard var updated = socialAccounts.first(where: { $0.id == account.id }) else { return }
        updated.fetchSource = .manual
        updated.recordSnapshot(count: count)
        addSocialAccount(updated)
    }

    func refreshSocialAccount(_ account: SocialAccount) async -> Bool {
        guard let count = await SocialFetcher.fetchFollowerCount(for: account) else { return false }
        var updated = account
        updated.fetchSource = .auto
        updated.recordSnapshot(count: count)
        await MainActor.run { addSocialAccount(updated) }
        return true
    }

    /// Starts a Task loop that periodically calls `refresh()` at the user's
    /// configured `SharedStorage.refreshIntervalMinutes`. Idempotent — calling
    /// it again cancels the previous loop and starts a new one (used when the
    /// interval changes in Settings).
    func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let minutes = max(1, SharedStorage.shared.refreshIntervalMinutes)
                let nanos = UInt64(minutes) * 60 * 1_000_000_000
                try? await Task.sleep(nanoseconds: nanos)
                if Task.isCancelled { return }
                guard let self else { return }
                let stillConnected = await MainActor.run { self.hasCredentials }
                guard stillConnected else { return }
                await self.refresh()
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func togglePrinted(_ orderId: String) {
        if printedOrderIds.contains(orderId) {
            printedOrderIds.remove(orderId)
            SharedStorage.shared.unmarkPrinted(orderId)
        } else {
            printedOrderIds.insert(orderId)
            SharedStorage.shared.markPrinted(orderId)
        }
        Task { await Refresher.shared.notifyWidgets() }
    }

    func isPrinted(_ orderId: String) -> Bool {
        printedOrderIds.contains(orderId)
    }

    /// Pending (not-printed) orders, sorted oldest-first — what the widget queue uses.
    var pendingOrders: [WixOrder] {
        filteredOrders
            .filter { !printedOrderIds.contains($0.id) }
            .sorted { $0.createdDate < $1.createdDate }
    }

    func refresh() async {
        // SCREENSHOTS-MOCK BRANCH ONLY — refreshing just re-applies the seed
        // snapshot with a brief spinner so the UI feels alive for screenshots.
        isRefreshing = true
        defer { isRefreshing = false }
        try? await Task.sleep(nanoseconds: 600_000_000)
        snapshot = MockData.snapshot
        SharedStorage.shared.saveSnapshot(MockData.snapshot)
        lastError = nil
        await Refresher.shared.notifyWidgets()
    }

    func saveCredentials(apiKey: String?, siteId: String, accountId: String?) {
        if let apiKey, !apiKey.isEmpty {
            Keychain.saveAPIKey(apiKey)
        }
        SharedStorage.shared.siteId = siteId
        SharedStorage.shared.accountId = accountId?.isEmpty == true ? nil : accountId
        hasCredentials = (Keychain.loadAPIKey()?.isEmpty == false) && !siteId.isEmpty
        if hasCredentials {
            startAutoRefresh()
        } else {
            stopAutoRefresh()
        }
    }

    func clearCredentials() {
        Keychain.deleteAPIKey()
        SharedStorage.shared.siteId = nil
        SharedStorage.shared.accountId = nil
        hasCredentials = false
        snapshot = nil
        stopAutoRefresh()
    }

    func updateFilter(_ new: ProductFilter) {
        productFilter = new
        SharedStorage.shared.productFilter = new
        Task { await Refresher.shared.notifyWidgets() }
    }

    var availableProducts: [ProductInfo] {
        ProductCatalog.discover(in: snapshot?.orders ?? [])
    }

    var filteredOrders: [WixOrder] {
        productFilter.apply(to: snapshot?.orders ?? [])
    }
}
