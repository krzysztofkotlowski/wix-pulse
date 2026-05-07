import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public actor Refresher {
    public static let shared = Refresher()

    public func notifyWidgets() async {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Iterate every saved social account, attempt a fresh follower count,
    /// and persist the new daily snapshot. Best-effort — failures leave the
    /// previous count in place.
    public func refreshSocialAccounts() async {
        var accounts = SharedStorage.shared.socialAccounts
        guard !accounts.isEmpty else { return }
        for index in accounts.indices {
            // Skip accounts the user explicitly set to manual mode.
            guard accounts[index].fetchSource == .auto else { continue }
            if let count = await SocialFetcher.fetchFollowerCount(for: accounts[index]) {
                accounts[index].recordSnapshot(count: count)
            }
        }
        SharedStorage.shared.socialAccounts = accounts
    }

    public func refresh() async throws -> CachedSnapshot {
        guard
            let apiKey = Keychain.loadAPIKey(),
            let siteId = SharedStorage.shared.siteId,
            !apiKey.isEmpty, !siteId.isEmpty
        else {
            throw WixAPIError.missingCredentials
        }
        let creds = WixCredentials(apiKey: apiKey, siteId: siteId, accountId: SharedStorage.shared.accountId)
        let client = WixAPIClient(credentials: creds)

        // Fetch orders + traffic in parallel. Traffic is best-effort and
        // returns nil if the API key lacks Analytics permission, so it can
        // never fail the whole refresh.
        async let ordersTask = client.fetchOrders(limit: 100, since: Calendar.current.date(byAdding: .day, value: -30, to: Date()))
        async let trafficTask = client.fetchSiteTraffic()
        let orders = try await ordersTask
        let traffic = await trafficTask

        // Fire-and-forget social account refresh — never blocks orders flow.
        await refreshSocialAccounts()

        let summary = Analytics.summarize(orders: orders)
        let snapshot = CachedSnapshot(orders: orders, summary: summary, traffic: traffic)
        SharedStorage.shared.saveSnapshot(snapshot)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        return snapshot
    }
}
