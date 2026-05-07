import WidgetKit
import SwiftUI
import WixPulseCore

struct AnalyticsWidget: Widget {
    let kind = "AnalyticsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnalyticsProvider()) { entry in
            AnalyticsWidgetView(entry: entry)
                .containerBackground(for: .widget) { WPWidgetBackground() }
        }
        .configurationDisplayName("WIX Analytics")
        .description("Revenue and order trends.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct AnalyticsWidgetBundle: WidgetBundle {
    var body: some Widget { AnalyticsWidget() }
}

struct AnalyticsEntry: TimelineEntry {
    let date: Date
    let summary: OrderSummary
    let traffic: SiteTraffic?
    let isFiltered: Bool
    let isPlaceholder: Bool
}

struct AnalyticsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalyticsEntry {
        AnalyticsEntry(date: Date(), summary: .placeholder, traffic: nil, isFiltered: false, isPlaceholder: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (AnalyticsEntry) -> Void) {
        completion(makeEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalyticsEntry>) -> Void) {
        let entry = makeEntry()
        let refreshMinutes = max(5, SharedStorage.shared.refreshIntervalMinutes)
        let next = Date().addingTimeInterval(TimeInterval(refreshMinutes * 60))
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> AnalyticsEntry {
        let stored = SharedStorage.shared.loadSnapshot()
        let snap = stored ?? .placeholder
        let filter = SharedStorage.shared.productFilter
        if filter.isActive {
            let filtered = filter.apply(to: snap.orders)
            return AnalyticsEntry(date: Date(),
                                  summary: Analytics.summarize(orders: filtered, fallbackCurrency: snap.summary.currency),
                                  traffic: snap.traffic,
                                  isFiltered: true,
                                  isPlaceholder: stored == nil)
        } else {
            return AnalyticsEntry(date: Date(),
                                  summary: snap.summary,
                                  traffic: snap.traffic,
                                  isFiltered: false,
                                  isPlaceholder: stored == nil)
        }
    }
}
