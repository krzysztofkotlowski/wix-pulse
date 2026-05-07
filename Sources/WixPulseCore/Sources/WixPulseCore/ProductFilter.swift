import Foundation

public struct ProductInfo: Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let orderCount: Int
    public init(id: String, name: String, orderCount: Int) {
        self.id = id; self.name = name; self.orderCount = orderCount
    }
}

public enum ProductCatalog {
    public static func discover(in orders: [WixOrder]) -> [ProductInfo] {
        var counts: [String: (name: String, count: Int)] = [:]
        for order in orders {
            var seen = Set<String>()
            for item in order.lineItems {
                guard !seen.contains(item.productId) else { continue }
                seen.insert(item.productId)
                let existing = counts[item.productId]
                counts[item.productId] = (existing?.name ?? item.name, (existing?.count ?? 0) + 1)
            }
        }
        return counts
            .map { ProductInfo(id: $0.key, name: $0.value.name, orderCount: $0.value.count) }
            .sorted { lhs, rhs in
                lhs.orderCount == rhs.orderCount
                    ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    : lhs.orderCount > rhs.orderCount
            }
    }
}

public struct ProductFilter: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var selectedProductIds: Set<String>

    public init(enabled: Bool = false, selectedProductIds: Set<String> = []) {
        self.enabled = enabled
        self.selectedProductIds = selectedProductIds
    }

    public static let none = ProductFilter()

    public var isActive: Bool { enabled && !selectedProductIds.isEmpty }

    public func apply(to orders: [WixOrder]) -> [WixOrder] {
        guard isActive else { return orders }
        return orders.filter { order in
            order.lineItems.contains { selectedProductIds.contains($0.productId) }
        }
    }
}
