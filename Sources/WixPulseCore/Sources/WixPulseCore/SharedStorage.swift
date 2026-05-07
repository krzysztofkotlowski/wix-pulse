import Foundation

public enum AppGroup {
    public static let identifier = "group.com.kkotlowski.wixpulse"
}

public final class SharedStorage {
    public static let shared = SharedStorage()
    private let defaults: UserDefaults?

    private init() {
        self.defaults = UserDefaults(suiteName: AppGroup.identifier)
    }

    private enum Key {
        static let snapshot = "wixpulse.snapshot.v1"
        static let siteId = "wixpulse.siteId"
        static let accountId = "wixpulse.accountId"
        static let refreshInterval = "wixpulse.refreshInterval"
        static let productFilter = "wixpulse.productFilter.v1"
        static let printedOrderIds = "wixpulse.printedOrderIds.v1"
    }

    public var printedOrderIds: Set<String> {
        get {
            guard let data = defaults?.data(forKey: Key.printedOrderIds),
                  let value = try? JSONDecoder().decode(Set<String>.self, from: data)
            else { return [] }
            return value
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults?.set(data, forKey: Key.printedOrderIds)
        }
    }

    public func markPrinted(_ orderId: String) {
        var ids = printedOrderIds
        ids.insert(orderId)
        printedOrderIds = ids
    }

    public func unmarkPrinted(_ orderId: String) {
        var ids = printedOrderIds
        ids.remove(orderId)
        printedOrderIds = ids
    }

    public var siteId: String? {
        get { defaults?.string(forKey: Key.siteId) }
        set { defaults?.set(newValue, forKey: Key.siteId) }
    }

    public var accountId: String? {
        get { defaults?.string(forKey: Key.accountId) }
        set { defaults?.set(newValue, forKey: Key.accountId) }
    }

    public var refreshIntervalMinutes: Int {
        get { (defaults?.object(forKey: Key.refreshInterval) as? Int) ?? 15 }
        set { defaults?.set(newValue, forKey: Key.refreshInterval) }
    }

    public var productFilter: ProductFilter {
        get {
            guard let data = defaults?.data(forKey: Key.productFilter),
                  let value = try? JSONDecoder().decode(ProductFilter.self, from: data)
            else { return .none }
            return value
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults?.set(data, forKey: Key.productFilter)
        }
    }

    public func saveSnapshot(_ snapshot: CachedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: Key.snapshot)
    }

    public func loadSnapshot() -> CachedSnapshot? {
        guard let data = defaults?.data(forKey: Key.snapshot) else { return nil }
        return try? JSONDecoder().decode(CachedSnapshot.self, from: data)
    }
}
