import WidgetKit
import SwiftUI
import WixPulseCore

struct OrdersWidget: Widget {
    let kind = "OrdersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrdersProvider()) { entry in
            OrdersWidgetView(entry: entry)
                .containerBackground(for: .widget) { WPWidgetBackground() }
        }
        .configurationDisplayName("Recent Orders")
        .description("Track your latest WIX orders.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct OrdersWidgetBundle: WidgetBundle {
    var body: some Widget { OrdersWidget() }
}

struct OrdersEntry: TimelineEntry {
    let date: Date
    let orders: [WixOrder]
    let summary: OrderSummary
    let isPlaceholder: Bool
    let isFiltered: Bool
}

struct OrdersProvider: TimelineProvider {
    func placeholder(in context: Context) -> OrdersEntry {
        let snap = CachedSnapshot.placeholder
        return OrdersEntry(date: Date(), orders: snap.orders, summary: snap.summary, isPlaceholder: true, isFiltered: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (OrdersEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrdersEntry>) -> Void) {
        let entry = makeEntry()
        let refreshMinutes = max(5, SharedStorage.shared.refreshIntervalMinutes)
        let next = Date().addingTimeInterval(TimeInterval(refreshMinutes * 60))
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> OrdersEntry {
        let stored = SharedStorage.shared.loadSnapshot()
        let snap = stored ?? .placeholder
        let filter = SharedStorage.shared.productFilter
        let printed = SharedStorage.shared.printedOrderIds
        let allFiltered = filter.apply(to: snap.orders)
        // Production queue: orders to print AND send.
        // - Not already printed
        // - Not already fulfilled (shipped) or canceled in WIX
        // - Created within the last 14 days — older orders are assumed handled
        //   offline (many shops don't keep WIX fulfillment status in sync).
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let pending = allFiltered
            .filter { !printed.contains($0.id) }
            // Whitelist: only orders that explicitly still need fulfillment.
            // Anything fulfilled / canceled / shipped / unknown is excluded.
            .filter { $0.fulfillmentStatus == .notFulfilled || $0.fulfillmentStatus == .partiallyFulfilled }
            .filter { $0.paymentStatus == .paid || $0.paymentStatus == .partiallyPaid }
            .filter { $0.createdDate >= cutoff }
            .sorted { $0.createdDate < $1.createdDate }
        let summary = filter.isActive
            ? Analytics.summarize(orders: allFiltered, fallbackCurrency: snap.summary.currency)
            : snap.summary
        return OrdersEntry(
            date: Date(),
            orders: pending,
            summary: summary,
            isPlaceholder: stored == nil,
            isFiltered: filter.isActive
        )
    }
}
