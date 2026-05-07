import Foundation

public struct WixCredentials: Equatable, Sendable {
    public let apiKey: String
    public let siteId: String
    public let accountId: String?

    public init(apiKey: String, siteId: String, accountId: String? = nil) {
        self.apiKey = apiKey
        self.siteId = siteId
        self.accountId = accountId
    }
}

public enum WixAPIError: LocalizedError {
    case missingCredentials
    case invalidResponse
    case http(status: Int, body: String)
    case decoding(Error)
    case transport(Error)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials: return "WIX API key or Site ID is missing. Open Settings to configure."
        case .invalidResponse: return "The WIX API returned an unexpected response."
        case .http(let status, let body): return "WIX API error (\(status)): \(body)"
        case .decoding(let err): return "Failed to decode WIX response: \(err.localizedDescription)"
        case .transport(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}

public protocol WixAPIClientProtocol: Sendable {
    func fetchOrders(limit: Int, since: Date?) async throws -> [WixOrder]
}

public final class WixAPIClient: WixAPIClientProtocol, @unchecked Sendable {
    private let credentials: WixCredentials
    private let session: URLSession
    private let baseURL = URL(string: "https://www.wixapis.com")!

    public init(credentials: WixCredentials, session: URLSession? = nil) {
        self.credentials = credentials
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 20
            config.timeoutIntervalForResource = 30
            config.waitsForConnectivity = false
            self.session = URLSession(configuration: config)
        }
    }

    public func fetchOrders(limit: Int = 50, since: Date? = nil) async throws -> [WixOrder] {
        var request = URLRequest(url: baseURL.appendingPathComponent("ecom/v1/orders/search"))
        request.httpMethod = "POST"
        request.setValue(credentials.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue(credentials.siteId, forHTTPHeaderField: "wix-site-id")
        if let accountId = credentials.accountId {
            request.setValue(accountId, forHTTPHeaderField: "wix-account-id")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var filter: [String: Any] = [:]
        if let since {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            filter["createdDate"] = ["$gte": iso.string(from: since)]
        }
        let body: [String: Any] = [
            "search": [
                "filter": filter,
                "sort": [["fieldName": "createdDate", "order": "DESC"]],
                "cursorPaging": ["limit": limit]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw WixAPIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else { throw WixAPIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw WixAPIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        do {
            let envelope = try JSONDecoder.wix.decode(OrdersEnvelope.self, from: data)
            return envelope.orders.map { $0.toDomain() }
        } catch {
            throw WixAPIError.decoding(error)
        }
    }
}

extension JSONDecoder {
    static let wix: JSONDecoder = {
        let decoder = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { d in
            let c = try d.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = iso.date(from: s) ?? isoFallback.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unparseable date: \(s)")
        }
        return decoder
    }()
}

/// Decodes a value that the WIX API sends as either a number or a string.
private struct FlexibleNumber: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { self.value = d; return }
        if let i = try? c.decode(Int.self) { self.value = Double(i); return }
        if let s = try? c.decode(String.self) { self.value = Double(s); return }
        self.value = nil
    }
}

/// Decodes a value that may be a plain string or an object with a `url` field
/// (WIX line-item images sometimes come as `"wix:image://..."` strings, sometimes as objects).
private struct FlexibleString: Decodable {
    let value: String?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self.value = s; return }
        if let obj = try? c.decode([String: AnyCodableValue].self) {
            self.value = obj["url"]?.stringValue ?? obj["src"]?.stringValue
            return
        }
        self.value = nil
    }
}

private struct AnyCodableValue: Decodable {
    let stringValue: String?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self.stringValue = s; return }
        if let i = try? c.decode(Int.self) { self.stringValue = String(i); return }
        if let d = try? c.decode(Double.self) { self.stringValue = String(d); return }
        self.stringValue = nil
    }
}

private struct OrdersEnvelope: Decodable {
    let orders: [APIOrder]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Decode each order independently so one malformed order can't kill the whole response.
        var rawOrders = try c.nestedUnkeyedContainer(forKey: .orders)
        var collected: [APIOrder] = []
        while !rawOrders.isAtEnd {
            if let one = try? rawOrders.decode(APIOrder.self) {
                collected.append(one)
            } else {
                _ = try? rawOrders.decode(EmptyDecodable.self)
            }
        }
        self.orders = collected
    }

    private enum CodingKeys: String, CodingKey { case orders }
    private struct EmptyDecodable: Decodable {}
}

private struct APIOrder: Decodable {
    let id: String
    let number: String?
    let createdDate: Date
    let status: String?
    let paymentStatus: String?
    let fulfillmentStatus: String?
    let priceSummary: PriceSummary?
    let lineItems: [LineItem]?
    let buyerInfo: BuyerInfo?
    let recipientInfo: RecipientInfo?
    let billingInfo: BillingInfo?
    let shippingInfo: ShippingInfo?
    let additionalInfo: AdditionalInfo?
    let channelInfo: ChannelInfo?
    let weightTotal: FlexibleNumber?
    let weightUnit: String?
    let currency: String?

    struct PriceSummary: Decodable {
        let total: PriceAmount?
        let subtotal: PriceAmount?
        let shipping: PriceAmount?
        let tax: PriceAmount?
        let discount: PriceAmount?
    }
    struct PriceAmount: Decodable {
        let amount: String?
        let currency: String?
    }
    struct LineItem: Decodable {
        let quantity: Int?
        let productName: ProductName?
        let catalogReference: CatalogReference?
        let price: PriceAmount?
        let totalPriceAfterTax: PriceAmount?
        let physicalProperties: PhysicalProperties?
        let descriptionLines: [DescriptionLine]?
        let image: FlexibleString?
        struct ProductName: Decodable { let original: String?; let translated: String? }
        struct CatalogReference: Decodable { let catalogItemId: String? }
        struct PhysicalProperties: Decodable { let sku: String? }
        struct DescriptionLine: Decodable {
            let name: LocalizedString?
            let plainText: LocalizedString?
            let colorInfo: ColorInfo?
            struct LocalizedString: Decodable { let original: String?; let translated: String? }
            struct ColorInfo: Decodable { let original: String?; let translated: String? }
        }
    }
    struct BuyerInfo: Decodable {
        let email: String?
        let firstName: String?
        let lastName: String?
        let phone: String?
        let contactDetails: ContactDetails?
        struct ContactDetails: Decodable {
            let firstName: String?
            let lastName: String?
            let phone: String?
            let company: String?
        }
    }
    struct RecipientInfo: Decodable {
        let address: Address?
        let contactDetails: BuyerInfo.ContactDetails?
    }
    struct BillingInfo: Decodable {
        let address: Address?
        let contactDetails: BuyerInfo.ContactDetails?
    }
    struct Address: Decodable {
        let addressLine: String?
        let addressLine2: String?
        let city: String?
        let postalCode: String?
        let country: String?
        let countryFullname: String?
        let subdivision: String?
        let subdivisionFullname: String?
    }
    struct ShippingInfo: Decodable {
        let title: String?
        let logistics: Logistics?
        struct Logistics: Decodable {
            let deliveryTime: String?
            let shippingDestination: ShippingDestination?
            struct ShippingDestination: Decodable { let address: Address? }
        }
    }
    struct AdditionalInfo: Decodable {
        let buyerNote: String?
    }
    struct ChannelInfo: Decodable {
        let type: String?
    }

    func toDomain() -> WixOrder {
        let rawCurrency = clean(priceSummary?.total?.currency) ?? clean(self.currency) ?? "USD"
        let totalAmount = Decimal(string: priceSummary?.total?.amount ?? "0") ?? 0
        let items: [WixOrder.LineItem] = (lineItems ?? []).map { li in
            let name = clean(li.productName?.translated)
                ?? clean(li.productName?.original)
                ?? "Item"
            let pid = clean(li.catalogReference?.catalogItemId) ?? name
            let unitAmt = li.price?.amount.flatMap { Decimal(string: $0) }
            let lineAmt = li.totalPriceAfterTax?.amount.flatMap { Decimal(string: $0) }
            let lineCurrency = clean(li.price?.currency) ?? clean(li.totalPriceAfterTax?.currency) ?? rawCurrency
            let attributes: [WixOrder.Attribute] = (li.descriptionLines ?? []).compactMap { line in
                // Strip trailing colons that some shops put in the label name,
                // so "Ilość wejść:" doesn't render as "Ilość wejść:: value".
                let rawLabel = clean(line.name?.translated) ?? clean(line.name?.original)
                let label = rawLabel?.trimmingCharacters(in: CharacterSet(charactersIn: ": ").union(.whitespaces))
                let value = clean(line.plainText?.translated)
                    ?? clean(line.plainText?.original)
                    ?? clean(line.colorInfo?.translated)
                    ?? clean(line.colorInfo?.original)
                guard let label, !label.isEmpty, let value else { return nil }
                return WixOrder.Attribute(label: label, value: value)
            }
            let variant: String? = attributes.isEmpty
                ? nil
                : attributes.map { "\($0.label): \($0.value)" }.joined(separator: " · ")
            let imageURL = clean(li.image?.value)
            return WixOrder.LineItem(
                productId: pid,
                name: name,
                quantity: li.quantity ?? 1,
                sku: clean(li.physicalProperties?.sku),
                unitPrice: unitAmt.map { Money(amount: $0, currency: lineCurrency) },
                lineTotal: lineAmt.map { Money(amount: $0, currency: lineCurrency) },
                variant: variant,
                attributes: attributes,
                imageURL: imageURL
            )
        }
        let firstName = clean(buyerInfo?.firstName) ?? clean(buyerInfo?.contactDetails?.firstName)
        let lastName = clean(buyerInfo?.lastName) ?? clean(buyerInfo?.contactDetails?.lastName)
        let displayName = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        let phone = clean(buyerInfo?.phone)
            ?? clean(buyerInfo?.contactDetails?.phone)
            ?? clean(recipientInfo?.contactDetails?.phone)
        let displayNumber = clean(number) ?? String(id.prefix(6))

        let shipAddrSrc = recipientInfo?.address ?? shippingInfo?.logistics?.shippingDestination?.address
        let shipping: WixOrder.Address? = shipAddrSrc.map { addr in
            WixOrder.Address(
                line1: clean(addr.addressLine),
                line2: clean(addr.addressLine2),
                city: clean(addr.city),
                region: clean(addr.subdivisionFullname) ?? clean(addr.subdivision),
                postalCode: clean(addr.postalCode),
                country: clean(addr.countryFullname) ?? clean(addr.country),
                recipient: displayName.isEmpty ? nil : displayName,
                company: clean(buyerInfo?.contactDetails?.company)
            )
        }
        let billing: WixOrder.Address? = billingInfo?.address.map { addr in
            WixOrder.Address(
                line1: clean(addr.addressLine),
                line2: clean(addr.addressLine2),
                city: clean(addr.city),
                region: clean(addr.subdivisionFullname) ?? clean(addr.subdivision),
                postalCode: clean(addr.postalCode),
                country: clean(addr.countryFullname) ?? clean(addr.country)
            )
        }

        func money(_ p: PriceAmount?) -> Money? {
            guard let amt = p?.amount, let dec = Decimal(string: amt), dec != 0 else { return nil }
            return Money(amount: dec, currency: clean(p?.currency) ?? rawCurrency)
        }

        return WixOrder(
            id: id,
            number: displayNumber,
            createdDate: createdDate,
            status: WixOrder.Status(rawValue: status ?? "") ?? .unknown,
            paymentStatus: WixOrder.PaymentStatus(rawValue: paymentStatus ?? "") ?? .unknown,
            fulfillmentStatus: WixOrder.FulfillmentStatus(rawValue: fulfillmentStatus ?? "") ?? .unknown,
            total: Money(amount: totalAmount, currency: rawCurrency),
            subtotal: money(priceSummary?.subtotal),
            shipping: money(priceSummary?.shipping),
            tax: money(priceSummary?.tax),
            discount: money(priceSummary?.discount),
            lineItems: items,
            buyerName: displayName.isEmpty ? nil : displayName,
            buyerEmail: clean(buyerInfo?.email),
            buyerPhone: phone,
            shippingAddress: shipping,
            billingAddress: billing,
            shippingMethod: clean(shippingInfo?.title),
            paymentMethod: nil,
            note: clean(additionalInfo?.buyerNote),
            channel: clean(channelInfo?.type),
            weight: weightTotal?.value,
            weightUnit: clean(weightUnit)
        )
    }

    private func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let lower = trimmed.lowercased()
        if lower == "undefined" || lower == "null" || lower == "nan" { return nil }
        return trimmed
    }
}
