import XCTest
@testable import WixPulseCore

final class AnalyticsTests: XCTestCase {
    func testSummaryAggregatesRevenueAndToday() {
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        let orders: [WixOrder] = [
            makeOrder(id: "1", date: today.addingTimeInterval(60), amount: 100),
            makeOrder(id: "2", date: today.addingTimeInterval(120), amount: 50),
            makeOrder(id: "3", date: yesterday.addingTimeInterval(60), amount: 200)
        ]
        let summary = Analytics.summarize(orders: orders, now: now, calendar: cal)

        XCTAssertEqual(summary.totalOrders, 3)
        XCTAssertEqual(summary.totalRevenue, 350)
        XCTAssertEqual(summary.newOrdersToday, 2)
        XCTAssertEqual(summary.revenueToday, 150)
        XCTAssertEqual(summary.dailyRevenue.count, 7)
    }

    func testProductFilterMatchesAnyLineItem() {
        let now = Date()
        let mug = makeOrder(id: "1", date: now, amount: 10, products: [("p1", "Mug")])
        let tee = makeOrder(id: "2", date: now, amount: 20, products: [("p2", "Tee")])
        let mixed = makeOrder(id: "3", date: now, amount: 30, products: [("p1", "Mug"), ("p2", "Tee")])

        let filter = ProductFilter(enabled: true, selectedProductIds: ["p1"])
        let result = filter.apply(to: [mug, tee, mixed])
        XCTAssertEqual(Set(result.map(\.id)), ["1", "3"])
    }

    func testProductDiscoveryRanksByOrderCount() {
        let orders = [
            makeOrder(id: "1", date: Date(), amount: 10, products: [("p1", "Mug")]),
            makeOrder(id: "2", date: Date(), amount: 20, products: [("p1", "Mug"), ("p2", "Tee")]),
            makeOrder(id: "3", date: Date(), amount: 30, products: [("p2", "Tee")])
        ]
        let products = ProductCatalog.discover(in: orders)
        XCTAssertEqual(products.first?.id, "p1")
        XCTAssertEqual(products.count, 2)
    }

    func testSummaryPicksMostCommonCurrency() {
        let now = Date()
        let orders = [
            makeOrder(id: "1", date: now, amount: 10, currency: "USD"),
            makeOrder(id: "2", date: now, amount: 20, currency: "PLN"),
            makeOrder(id: "3", date: now, amount: 30, currency: "PLN")
        ]
        let summary = Analytics.summarize(orders: orders, now: now)
        XCTAssertEqual(summary.currency, "PLN", "Most common currency should win, not the first")
    }

    func testSummaryFallsBackToProvidedCurrencyWhenEmpty() {
        let summary = Analytics.summarize(orders: [], now: Date(), fallbackCurrency: "EUR")
        XCTAssertEqual(summary.currency, "EUR")
    }

    func testMoneyFormattedHandlesGarbageCurrencyCode() {
        // WIX sometimes returns "undefined" or empty currency strings.
        XCTAssertFalse(Money(amount: 12.50, currency: "undefined").formatted.contains("undefined"))
        XCTAssertFalse(Money(amount: 12.50, currency: "").formatted.contains("undefined"))
    }

    private func makeOrder(id: String, date: Date, amount: Decimal,
                           products: [(String, String)] = [("p", "Item")],
                           currency: String = "USD") -> WixOrder {
        WixOrder(
            id: id, number: id, createdDate: date,
            status: .approved, paymentStatus: .paid, fulfillmentStatus: .fulfilled,
            total: Money(amount: amount, currency: currency),
            lineItems: products.map { WixOrder.LineItem(productId: $0.0, name: $0.1, quantity: 1) },
            buyerName: nil, buyerEmail: nil
        )
    }
}
