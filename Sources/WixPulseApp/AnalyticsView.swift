import SwiftUI
import Charts
import WixPulseCore

struct AnalyticsView: View {
    @EnvironmentObject var store: AppStore

    var orders: [WixOrder] { store.filteredOrders }
    var summary: OrderSummary { Analytics.summarize(orders: orders) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WP.Spacing.lg) {
                heroCard

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: WP.Spacing.md)], spacing: WP.Spacing.md) {
                    WPMetricCard(eyebrow: "Today · orders", value: "\(summary.newOrdersToday)", caption: pace(today: summary.newOrdersToday, daily: summary.dailyRevenue.map(\.orderCount)), icon: "cart.fill", tint: .wpAccent)
                    WPMetricCard(eyebrow: "30 days · orders", value: "\(summary.totalOrders)", caption: nil, icon: "shippingbox.fill", tint: .wpPositive)
                    WPMetricCard(eyebrow: "30 days · revenue", value: Money(amount: summary.totalRevenue, currency: summary.currency).formatted, caption: nil, icon: "creditcard.fill", tint: .wpAccent)
                    WPMetricCard(eyebrow: "Avg order", value: avgOrder, caption: "across \(summary.totalOrders) order\(summary.totalOrders == 1 ? "" : "s")", icon: "function", tint: .wpWarning)
                }

                revenueChart
                orderCountChart

                if let traffic = store.snapshot?.traffic {
                    trafficSection(traffic: traffic)
                } else {
                    trafficUnavailableCard
                }

                if !store.socialAccounts.isEmpty {
                    socialSection
                }
            }
            .padding(WP.Spacing.xl)
        }
    }

    private var trafficUnavailableCard: some View {
        HStack(alignment: .top, spacing: WP.Spacing.md) {
            Image(systemName: "person.2.slash")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.wpAccent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("Site traffic unavailable")
                    .font(.system(.callout, weight: .semibold))
                Text("Add the 'Read Site Analytics' permission to your Wix API key to see sessions and unique visitors here and on the widget. Settings → API Keys → edit → enable Site Analytics → regenerate → paste the new key in WixPulse Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: URL(string: "https://manage.wix.com/account/api-keys")!) {
                    Label("Open Wix API Keys", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.wpAccent)
                }
                .padding(.top, 2)
            }
            Spacer()
        }
        .wpCard()
    }

    @ViewBuilder
    private func trafficSection(traffic: SiteTraffic) -> some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "person.2.fill", title: "Site traffic")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: WP.Spacing.md)], spacing: WP.Spacing.md) {
                WPMetricCard(eyebrow: "Today · sessions",
                             value: "\(traffic.sessionsToday)",
                             caption: pace(today: traffic.sessionsToday, daily: traffic.dailySessions.map(\.value)),
                             icon: "wave.3.right",
                             tint: .wpAccent)
                WPMetricCard(eyebrow: "30 days · sessions",
                             value: "\(traffic.sessions30Days)",
                             caption: nil,
                             icon: "person.2.wave.2.fill",
                             tint: .wpPositive)
                WPMetricCard(eyebrow: "Today · visitors",
                             value: "\(traffic.uniqueVisitorsToday)",
                             caption: pace(today: traffic.uniqueVisitorsToday, daily: traffic.dailyUniqueVisitors.map(\.value)),
                             icon: "person.crop.circle.fill",
                             tint: .wpAccent)
                WPMetricCard(eyebrow: "30 days · visitors",
                             value: "\(traffic.uniqueVisitors30Days)",
                             caption: "unique",
                             icon: "person.3.fill",
                             tint: .wpWarning)
            }

            if traffic.dailySessions.count > 1 {
                VStack(alignment: .leading, spacing: WP.Spacing.sm) {
                    WPSectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Sessions · last 30 days")
                    Chart(traffic.dailySessions) { d in
                        AreaMark(x: .value("Day", d.date, unit: .day),
                                 y: .value("Sessions", d.value))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(LinearGradient(colors: [Color.wpAccent.opacity(0.4), Color.wpAccent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Day", d.date, unit: .day),
                                 y: .value("Sessions", d.value))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(Color.wpAccent)
                            .lineStyle(.init(lineWidth: 2))
                    }
                    .frame(height: 180)
                }
                .wpCard()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.sm) {
            HStack {
                WPSectionHeader(icon: "sparkles", title: "Today")
                if store.productFilter.isActive {
                    WPChip("Filtered", style: .accent, icon: "line.3.horizontal.decrease")
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: WP.Spacing.lg) {
                WPNumber(Money(amount: summary.revenueToday, currency: summary.currency).formatted, size: 48, tinted: true)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(summary.newOrdersToday)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("orders").wpEyebrowStyle()
                }
            }
            sparkline
        }
        .wpCard(padding: WP.Spacing.xl)
    }

    private var sparkline: some View {
        Chart(summary.dailyRevenue) { d in
            AreaMark(
                x: .value("Day", d.date, unit: .day),
                y: .value("Revenue", NSDecimalNumber(decimal: d.revenue).doubleValue)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(LinearGradient(colors: [Color.wpAccent.opacity(0.45), Color.wpAccent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
            LineMark(
                x: .value("Day", d.date, unit: .day),
                y: .value("Revenue", NSDecimalNumber(decimal: d.revenue).doubleValue)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(Color.wpAccent)
            .lineStyle(.init(lineWidth: 2))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 60)
    }

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "chart.bar.fill", title: "Revenue · last 7 days")
            Chart(summary.dailyRevenue) { d in
                BarMark(
                    x: .value("Day", d.date, unit: .day),
                    y: .value("Revenue", NSDecimalNumber(decimal: d.revenue).doubleValue)
                )
                .foregroundStyle(LinearGradient(colors: [Color.wpAccent, Color.wpAccent.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.wpHairline)
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)
        }
        .wpCard()
    }

    private var orderCountChart: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "shippingbox.fill", title: "Orders · last 7 days")
            Chart(summary.dailyRevenue) { d in
                AreaMark(x: .value("Day", d.date, unit: .day), y: .value("Orders", d.orderCount))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [Color.wpAccent.opacity(0.4), Color.wpAccent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Day", d.date, unit: .day), y: .value("Orders", d.orderCount))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.wpAccent)
                    .lineStyle(.init(lineWidth: 2))
                PointMark(x: .value("Day", d.date, unit: .day), y: .value("Orders", d.orderCount))
                    .foregroundStyle(Color.wpAccent)
            }
            .frame(height: 180)
        }
        .wpCard()
    }

    private var avgOrder: String {
        guard summary.totalOrders > 0 else { return "—" }
        let avg = summary.totalRevenue / Decimal(summary.totalOrders)
        return Money(amount: avg, currency: summary.currency).formatted
    }

    private func pace(today: Int, daily: [Int]) -> String {
        guard !daily.isEmpty else { return "" }
        let avg = Double(daily.reduce(0, +)) / Double(daily.count)
        guard avg > 0 else { return "" }
        let pct = Int(((Double(today) - avg) / avg) * 100)
        if pct == 0 { return "on pace" }
        return pct > 0 ? "▲ \(pct)% vs avg" : "▼ \(abs(pct))% vs avg"
    }

    @ViewBuilder
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.md) {
            WPSectionHeader(icon: "person.crop.circle.badge.checkmark", title: "Social presence")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: WP.Spacing.md)], spacing: WP.Spacing.md) {
                ForEach(store.socialAccounts) { account in
                    socialCard(account)
                }
            }
        }
    }

    @ViewBuilder
    private func socialCard(_ account: SocialAccount) -> some View {
        VStack(alignment: .leading, spacing: WP.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: account.platform.icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.wpAccent)
                    .font(.system(size: 16, weight: .semibold))
                if let url = account.platform.profileURL(account.handle) {
                    Link("@\(account.handle)", destination: url)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                } else {
                    Text("@\(account.handle)").font(.callout.weight(.semibold))
                }
                Spacer()
                Text(account.platform.displayName.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(account.followerCount)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.wpAccent)
                Text("followers")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                if let weekly = account.weekOverWeekChange, weekly != 0 {
                    Text(weekly > 0 ? "▲ \(weekly) this week" : "▼ \(abs(weekly)) this week")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(weekly > 0 ? Color.wpPositive : Color.wpDanger)
                }
            }
            if account.history.count > 1 {
                Chart(account.history) { snap in
                    AreaMark(x: .value("Day", snap.date, unit: .day),
                             y: .value("Followers", snap.count))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(LinearGradient(colors: [Color.wpAccent.opacity(0.4), Color.wpAccent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Day", snap.date, unit: .day),
                             y: .value("Followers", snap.count))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.wpAccent)
                        .lineStyle(.init(lineWidth: 2))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 60)
            }
            HStack(spacing: 6) {
                Text("Updated")
                    .font(.caption2).foregroundStyle(.tertiary)
                Text(account.lastUpdated, style: .relative)
                    .font(.caption2).foregroundStyle(.tertiary)
                Text("ago")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .wpCard()
    }
}
