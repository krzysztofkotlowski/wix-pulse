import Foundation

public enum Analytics {
    public static func summarize(orders: [WixOrder], now: Date = Date(), calendar: Calendar = .current, fallbackCurrency: String = "USD") -> OrderSummary {
        // Pick the most common currency across all orders, not just the first.
        let currency: String = {
            let codes = orders.map { $0.total.currency }.filter { !$0.isEmpty }
            guard !codes.isEmpty else { return fallbackCurrency }
            let counts = Dictionary(codes.map { ($0, 1) }, uniquingKeysWith: +)
            return counts.max(by: { $0.value < $1.value })?.key ?? fallbackCurrency
        }()
        let totalRevenue = orders.reduce(Decimal(0)) { $0 + $1.total.amount }

        let startOfToday = calendar.startOfDay(for: now)
        let todayOrders = orders.filter { $0.createdDate >= startOfToday }
        let revenueToday = todayOrders.reduce(Decimal(0)) { $0 + $1.total.amount }

        var daily: [OrderSummary.DailyRevenue] = []
        for dayOffset in (0..<7).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else { continue }
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayOrders = orders.filter { $0.createdDate >= dayStart && $0.createdDate < dayEnd }
            let revenue = dayOrders.reduce(Decimal(0)) { $0 + $1.total.amount }
            daily.append(OrderSummary.DailyRevenue(date: dayStart, revenue: revenue, orderCount: dayOrders.count))
        }

        return OrderSummary(
            totalOrders: orders.count,
            totalRevenue: totalRevenue,
            currency: currency,
            newOrdersToday: todayOrders.count,
            revenueToday: revenueToday,
            dailyRevenue: daily,
            updatedAt: now
        )
    }
}
