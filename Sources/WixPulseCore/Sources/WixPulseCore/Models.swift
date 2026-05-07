import Foundation

public struct WixOrder: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let number: String
    public let createdDate: Date
    public let status: Status
    public let paymentStatus: PaymentStatus
    public let fulfillmentStatus: FulfillmentStatus
    public let total: Money
    public let subtotal: Money?
    public let shipping: Money?
    public let tax: Money?
    public let discount: Money?
    public let lineItems: [LineItem]
    public let buyerName: String?
    public let buyerEmail: String?
    public let buyerPhone: String?
    public let shippingAddress: Address?
    public let billingAddress: Address?
    public let shippingMethod: String?
    public let paymentMethod: String?
    public let note: String?
    public let channel: String?
    public let weight: Double?
    public let weightUnit: String?

    public var itemCount: Int { lineItems.reduce(0) { $0 + $1.quantity } }

    public init(
        id: String, number: String, createdDate: Date,
        status: Status, paymentStatus: PaymentStatus, fulfillmentStatus: FulfillmentStatus,
        total: Money,
        subtotal: Money? = nil, shipping: Money? = nil, tax: Money? = nil, discount: Money? = nil,
        lineItems: [LineItem],
        buyerName: String?, buyerEmail: String?, buyerPhone: String? = nil,
        shippingAddress: Address? = nil, billingAddress: Address? = nil,
        shippingMethod: String? = nil, paymentMethod: String? = nil,
        note: String? = nil, channel: String? = nil,
        weight: Double? = nil, weightUnit: String? = nil
    ) {
        self.id = id; self.number = number; self.createdDate = createdDate
        self.status = status; self.paymentStatus = paymentStatus; self.fulfillmentStatus = fulfillmentStatus
        self.total = total
        self.subtotal = subtotal; self.shipping = shipping; self.tax = tax; self.discount = discount
        self.lineItems = lineItems
        self.buyerName = buyerName; self.buyerEmail = buyerEmail; self.buyerPhone = buyerPhone
        self.shippingAddress = shippingAddress; self.billingAddress = billingAddress
        self.shippingMethod = shippingMethod; self.paymentMethod = paymentMethod
        self.note = note; self.channel = channel
        self.weight = weight; self.weightUnit = weightUnit
    }

    public struct Address: Codable, Hashable, Sendable {
        public let line1: String?
        public let line2: String?
        public let city: String?
        public let region: String?
        public let postalCode: String?
        public let country: String?
        public let recipient: String?
        public let company: String?

        public init(line1: String?, line2: String?, city: String?, region: String?, postalCode: String?, country: String?, recipient: String? = nil, company: String? = nil) {
            self.line1 = line1; self.line2 = line2; self.city = city; self.region = region
            self.postalCode = postalCode; self.country = country
            self.recipient = recipient; self.company = company
        }

        public var oneLine: String {
            [line1, line2, [postalCode, city].compactMap { $0 }.joined(separator: " "), region, country]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: ", ")
        }
    }

    public struct Attribute: Codable, Hashable, Sendable, Identifiable {
        public let label: String
        public let value: String
        public var id: String { label + "|" + value }
        public init(label: String, value: String) {
            self.label = label
            self.value = value
        }
    }

    public struct LineItem: Codable, Hashable, Sendable, Identifiable {
        public let productId: String
        public let name: String
        public let quantity: Int
        public let sku: String?
        public let unitPrice: Money?
        public let lineTotal: Money?
        public let variant: String?
        public let attributes: [Attribute]
        public let imageURL: String?
        public var id: String { productId + "|" + name + "|" + (sku ?? "") }

        public init(productId: String, name: String, quantity: Int,
                    sku: String? = nil, unitPrice: Money? = nil, lineTotal: Money? = nil,
                    variant: String? = nil, attributes: [Attribute] = [],
                    imageURL: String? = nil) {
            self.productId = productId; self.name = name; self.quantity = quantity
            self.sku = sku; self.unitPrice = unitPrice; self.lineTotal = lineTotal
            self.variant = variant; self.attributes = attributes; self.imageURL = imageURL
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.productId = try c.decode(String.self, forKey: .productId)
            self.name = try c.decode(String.self, forKey: .name)
            self.quantity = try c.decode(Int.self, forKey: .quantity)
            self.sku = try c.decodeIfPresent(String.self, forKey: .sku)
            self.unitPrice = try c.decodeIfPresent(Money.self, forKey: .unitPrice)
            self.lineTotal = try c.decodeIfPresent(Money.self, forKey: .lineTotal)
            self.variant = try c.decodeIfPresent(String.self, forKey: .variant)
            // attributes is optional for backwards compat with old cached snapshots
            self.attributes = (try? c.decodeIfPresent([Attribute].self, forKey: .attributes)) ?? []
            self.imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        }

        private enum CodingKeys: String, CodingKey {
            case productId, name, quantity, sku, unitPrice, lineTotal, variant, attributes, imageURL
        }
    }

    public enum Status: String, Codable, Sendable {
        case initialized = "INITIALIZED"
        case approved = "APPROVED"
        case canceled = "CANCELED"
        case unknown
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Status(rawValue: raw) ?? .unknown
        }
    }

    public enum PaymentStatus: String, Codable, Sendable {
        case paid = "PAID"
        case notPaid = "NOT_PAID"
        case partiallyPaid = "PARTIALLY_PAID"
        case refunded = "FULLY_REFUNDED"
        case partiallyRefunded = "PARTIALLY_REFUNDED"
        case pending = "PENDING"
        case unknown
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = PaymentStatus(rawValue: raw) ?? .unknown
        }
    }

    public enum FulfillmentStatus: String, Codable, Sendable {
        case notFulfilled = "NOT_FULFILLED"
        case fulfilled = "FULFILLED"
        case partiallyFulfilled = "PARTIALLY_FULFILLED"
        case canceled = "CANCELED"
        case unknown
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = FulfillmentStatus(rawValue: raw) ?? .unknown
        }
    }
}

public struct Money: Codable, Hashable, Sendable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String) {
        self.amount = amount; self.currency = currency
    }

    public var formatted: String {
        let safeCurrency = Self.normalize(currency: currency)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = safeCurrency
        formatter.maximumFractionDigits = 2
        if let str = formatter.string(from: amount as NSDecimalNumber) { return str }
        let plain = NumberFormatter()
        plain.numberStyle = .decimal
        plain.maximumFractionDigits = 2
        let n = plain.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(n) \(safeCurrency)"
    }

    private static func normalize(currency raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if trimmed.count == 3, trimmed.allSatisfy({ $0.isLetter }) { return trimmed }
        return "USD"
    }
}

/// Human-readable age label for an order date relative to "now".
/// Returns "Today", "Yesterday", "N days ago", or formatted absolute date for older.
public enum OrderDate {
    public static func ageLabel(for date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

public struct OrderSummary: Codable, Hashable, Sendable {
    public let totalOrders: Int
    public let totalRevenue: Decimal
    public let currency: String
    public let newOrdersToday: Int
    public let revenueToday: Decimal
    public let dailyRevenue: [DailyRevenue]
    public let updatedAt: Date

    public struct DailyRevenue: Codable, Hashable, Sendable, Identifiable {
        public var id: Date { date }
        public let date: Date
        public let revenue: Decimal
        public let orderCount: Int
        public init(date: Date, revenue: Decimal, orderCount: Int) {
            self.date = date; self.revenue = revenue; self.orderCount = orderCount
        }
    }

    public init(totalOrders: Int, totalRevenue: Decimal, currency: String, newOrdersToday: Int, revenueToday: Decimal, dailyRevenue: [DailyRevenue], updatedAt: Date) {
        self.totalOrders = totalOrders; self.totalRevenue = totalRevenue; self.currency = currency
        self.newOrdersToday = newOrdersToday; self.revenueToday = revenueToday
        self.dailyRevenue = dailyRevenue; self.updatedAt = updatedAt
    }

    public static let placeholder = OrderSummary(
        totalOrders: 128, totalRevenue: 4820, currency: "USD",
        newOrdersToday: 4, revenueToday: 312,
        dailyRevenue: (0..<7).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            return DailyRevenue(date: date, revenue: Decimal(100 + i * 40), orderCount: 3 + i)
        }.reversed(),
        updatedAt: Date()
    )
}

public struct CachedSnapshot: Codable, Sendable {
    public let orders: [WixOrder]
    public let summary: OrderSummary

    public init(orders: [WixOrder], summary: OrderSummary) {
        self.orders = orders; self.summary = summary
    }

    public static let placeholder: CachedSnapshot = {
        let sampleProducts = ["Linen Tee", "Ceramic Mug", "Hand Cream", "Tote Bag"]
        let orders: [WixOrder] = (1...8).map { i in
            let item = WixOrder.LineItem(
                productId: "p-\(i % sampleProducts.count)",
                name: sampleProducts[i % sampleProducts.count],
                quantity: 1 + (i % 3)
            )
            return WixOrder(
                id: "sample-\(i)",
                number: "\(1000 + i)",
                createdDate: Calendar.current.date(byAdding: .hour, value: -i * 3, to: Date()) ?? Date(),
                status: .approved,
                paymentStatus: .paid,
                fulfillmentStatus: i.isMultiple(of: 2) ? .fulfilled : .notFulfilled,
                total: Money(amount: Decimal(20 + i * 15), currency: "USD"),
                lineItems: [item],
                buyerName: "Sample Buyer \(i)",
                buyerEmail: "buyer\(i)@example.com"
            )
        }
        return CachedSnapshot(orders: orders, summary: .placeholder)
    }()
}
