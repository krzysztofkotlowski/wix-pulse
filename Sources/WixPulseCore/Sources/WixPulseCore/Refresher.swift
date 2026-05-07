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

        let summary = Analytics.summarize(orders: orders)
        let snapshot = CachedSnapshot(orders: orders, summary: summary, traffic: traffic)
        SharedStorage.shared.saveSnapshot(snapshot)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        return snapshot
    }
}
