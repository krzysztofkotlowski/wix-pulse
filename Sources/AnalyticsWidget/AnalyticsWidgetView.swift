import SwiftUI
import Charts
import WidgetKit
import WixPulseCore

struct AnalyticsWidgetView: View {
    let entry: AnalyticsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if entry.isPlaceholder {
                WidgetEmptyState(message: "Connect WixPulse to see revenue")
            } else {
                switch family {
                case .systemSmall: SmallView(entry: entry)
                case .systemMedium: MediumView(entry: entry)
                case .systemLarge, .systemExtraLarge: LargeView(entry: entry)
                default: MediumView(entry: entry)
                }
            }
        }
    }
}

private struct WidgetEyebrow: View {
    let icon: String
    let title: String
    var chip: AnyView? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.wpAccent)
                .font(.system(size: 11, weight: .semibold))
            Text(title).wpEyebrowStyle()
            Spacer(minLength: 4)
            if let chip { chip }
        }
    }
}

private struct SmallView: View {
    let entry: AnalyticsEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetEyebrow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Revenue today",
                chip: entry.isFiltered ? AnyView(WPChip("Filtered", style: .accent)) : nil
            )
            WPNumber(
                Money(amount: entry.summary.revenueToday, currency: entry.summary.currency).formatted,
                size: 26,
                tinted: true
            )
            HStack(spacing: 4) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.wpAccent)
                Text("\(entry.summary.newOrdersToday) order\(entry.summary.newOrdersToday == 1 ? "" : "s")")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            Sparkline(data: entry.summary.dailyRevenue)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let entry: AnalyticsEntry
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                WidgetEyebrow(
                    icon: "sparkles",
                    title: "Today",
                    chip: entry.isFiltered ? AnyView(WPChip("Filtered", style: .accent)) : nil
                )
                WPNumber(
                    Money(amount: entry.summary.revenueToday, currency: entry.summary.currency).formatted,
                    size: 26,
                    tinted: true
                )
                Text("\(entry.summary.newOrdersToday) order\(entry.summary.newOrdersToday == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("30 days").wpEyebrowStyle()
                Text(Money(amount: entry.summary.totalRevenue, currency: entry.summary.currency).formatted)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("Last 7 days").wpEyebrowStyle()
                RevenueBars(data: entry.summary.dailyRevenue)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct LargeView: View {
    let entry: AnalyticsEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetEyebrow(
                icon: "chart.bar.fill",
                title: "Analytics",
                chip: entry.isFiltered ? AnyView(WPChip("Filtered", style: .accent)) : nil
            )
            HStack(spacing: 10) {
                WidgetStatTile(
                    eyebrow: "Today",
                    value: Money(amount: entry.summary.revenueToday, currency: entry.summary.currency).formatted,
                    caption: "\(entry.summary.newOrdersToday) order\(entry.summary.newOrdersToday == 1 ? "" : "s")",
                    icon: "sparkles",
                    tinted: true
                )
                WidgetStatTile(
                    eyebrow: "30 days",
                    value: Money(amount: entry.summary.totalRevenue, currency: entry.summary.currency).formatted,
                    caption: "\(entry.summary.totalOrders) orders",
                    icon: "calendar",
                    tinted: false
                )
            }
            HStack {
                Text("Revenue · last 7 days").wpEyebrowStyle()
                Spacer()
            }
            RevenueBars(data: entry.summary.dailyRevenue, showAxis: true)
                .frame(minHeight: 120)
            Spacer(minLength: 0)
            Text("Updated \(entry.summary.updatedAt.formatted(.relative(presentation: .numeric)))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

private struct WidgetStatTile: View {
    let eyebrow: String
    let value: String
    let caption: String
    let icon: String
    let tinted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.wpAccent)
                    .font(.system(size: 11, weight: .semibold))
                Text(eyebrow).wpEyebrowStyle()
            }
            WPNumber(value, size: 20, tinted: tinted)
            Text(caption).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
    }
}

private struct RevenueBars: View {
    let data: [OrderSummary.DailyRevenue]
    var showAxis: Bool = false

    @ViewBuilder
    var body: some View {
        if showAxis {
            Chart(data) { d in
                BarMark(
                    x: .value("Day", d.date, unit: .day),
                    y: .value("Revenue", NSDecimalNumber(decimal: d.revenue).doubleValue)
                )
                .foregroundStyle(LinearGradient(colors: [Color.wpAccent, Color.wpAccent.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis(.hidden)
        } else {
            Chart(data) { d in
                BarMark(
                    x: .value("Day", d.date, unit: .day),
                    y: .value("Revenue", NSDecimalNumber(decimal: d.revenue).doubleValue)
                )
                .foregroundStyle(LinearGradient(colors: [Color.wpAccent, Color.wpAccent.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }
}

private struct Sparkline: View {
    let data: [OrderSummary.DailyRevenue]
    var body: some View {
        GeometryReader { geo in
            let values = data.map { NSDecimalNumber(decimal: $0.revenue).doubleValue }
            let maxV = max(values.max() ?? 1, 1)
            let stepX = data.count > 1 ? geo.size.width / CGFloat(data.count - 1) : 0
            let points: [CGPoint] = values.enumerated().map { idx, v in
                let x = CGFloat(idx) * stepX
                let y = geo.size.height - (CGFloat(v / maxV) * geo.size.height)
                return CGPoint(x: x, y: y)
            }
            ZStack {
                if points.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                        for pt in points { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Color.wpAccent.opacity(0.5), Color.wpAccent.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                    Path { p in
                        p.move(to: points[0])
                        for pt in points.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(Color.wpAccent, lineWidth: 1.5)
                }
            }
        }
    }
}

private struct WidgetEmptyState: View {
    var message: String
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "chart.bar.xaxis")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .font(.title3)
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

#Preview(as: .systemMedium) {
    AnalyticsWidget()
} timeline: {
    AnalyticsEntry(date: .now, summary: .placeholder, isFiltered: false, isPlaceholder: false)
}
