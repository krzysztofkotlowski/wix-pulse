import SwiftUI
import WidgetKit
import WixPulseCore

struct OrdersWidgetView: View {
    let entry: OrdersEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if entry.isPlaceholder && entry.orders.isEmpty {
                WidgetEmptyState(message: "Connect WixPulse to track orders")
            } else {
                switch family {
                case .systemSmall: SmallView(entry: entry)
                case .systemMedium: MediumView(entry: entry)
                case .systemLarge: LargeView(entry: entry, maxOrders: 3)
                case .systemExtraLarge: LargeView(entry: entry, maxOrders: 5)
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
    let entry: OrdersEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetEyebrow(
                icon: "printer.fill",
                title: "To print",
                chip: entry.isFiltered ? AnyView(WPChip("Filtered", style: .accent)) : nil
            )
            WPNumber("\(entry.orders.count)", size: 44, tinted: true)
            // Next-up preview — oldest pending order
            if let next = entry.orders.first {
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEXT UP")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)
                    Text("#\(next.number)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.wpAccent)
                    Text(OrderDate.ageLabel(for: next.createdDate))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("All caught up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let entry: OrdersEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetEyebrow(
                icon: "shippingbox.fill",
                title: "Recent orders",
                chip: entry.isFiltered
                    ? AnyView(WPChip("Filtered", style: .accent))
                    : AnyView(WPChip("\(entry.summary.newOrdersToday) today", style: .neutral))
            )
            if entry.orders.isEmpty {
                WidgetEmptyState(message: "No orders yet")
            } else {
                VStack(spacing: 4) {
                    ForEach(entry.orders.prefix(3)) { OrderCardRow(order: $0, compact: true) }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct LargeView: View {
    let entry: OrdersEntry
    let maxOrders: Int

    private var queueDepthChip: WPChip {
        let count = entry.orders.count
        if count == 0 { return WPChip("Empty", style: .positive) }
        // If oldest pending order is >2 days old, surface a warning chip.
        let oldestAge = entry.orders.first.map { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: $0.createdDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0 } ?? 0
        if oldestAge >= 3 { return WPChip("\(count) · oldest \(oldestAge)d", style: .danger) }
        if oldestAge >= 1 { return WPChip("\(count) pending", style: .warning) }
        return WPChip("\(count) pending", style: .accent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            WidgetEyebrow(
                icon: "printer.fill",
                title: "To print",
                chip: AnyView(queueDepthChip)
            )
            if entry.orders.isEmpty {
                WidgetEmptyState(message: "All caught up — nothing to print")
            } else {
                VStack(spacing: 4) {
                    ForEach(entry.orders.prefix(maxOrders)) { OrderProductionCard(order: $0) }
                    if entry.orders.count > maxOrders {
                        Text("+ \(entry.orders.count - maxOrders) more order\(entry.orders.count - maxOrders == 1 ? "" : "s") in the app")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Date age helpers shared between widget rows.
private enum OrderDate {
    /// "TODAY" / "YESTERDAY" / "3D AGO" / "MAR 28" — ultra-compact for widget badges.
    static func ageLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "TODAY" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        if days < 7 { return "\(days)D AGO" }
        return date.formatted(.dateTime.day().month(.abbreviated)).uppercased()
    }
}

/// Detailed per-order card for the Large widget. Prioritizes per-item info
/// (name, color/size variant, SKU, quantity) so production operators can read
/// off everything they need to print without opening the app.
private struct OrderProductionCard: View {
    let order: WixOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header: age badge + order#, time, customer, total, status dots
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(OrderDate.ageLabel(for: order.createdDate))
                    .font(.system(size: 8, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .foregroundStyle(ageColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(ageColor.opacity(0.15), in: Capsule())
                Text("#\(order.number)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.wpAccent)
                Text(order.createdDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                Text(order.buyerName ?? order.buyerEmail ?? "Guest")
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Spacer(minLength: 4)
                statusDots
                Text(order.total.formatted)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Per-item production rows
            ForEach(order.lineItems.prefix(2)) { item in
                ProductionItemRow(item: item)
            }
            if order.lineItems.count > 2 {
                Text("+ \(order.lineItems.count - 2) more")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 24)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.wpHairline, lineWidth: 0.5)
        )
    }

    private var statusDots: some View {
        HStack(spacing: 3) {
            Circle().fill(paymentColor).frame(width: 5, height: 5)
            Circle().fill(fulfillmentColor).frame(width: 5, height: 5)
        }
    }

    private var paymentColor: Color {
        switch order.paymentStatus {
        case .paid: return .wpPositive
        case .notPaid, .pending, .partiallyPaid: return .wpWarning
        case .refunded, .partiallyRefunded: return .wpDanger
        case .unknown: return .secondary
        }
    }
    private var fulfillmentColor: Color {
        switch order.fulfillmentStatus {
        case .fulfilled: return .wpPositive
        case .notFulfilled, .partiallyFulfilled: return .wpWarning
        case .canceled: return .wpDanger
        case .unknown: return .secondary
        }
    }

    /// Older = redder, so the operator can spot stale orders at a glance.
    private var ageColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: order.createdDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        if days >= 3 { return .wpDanger }
        if days >= 1 { return .wpWarning }
        return .wpPositive
    }
}

/// Single line-item row optimized for production: tiny qty pill + variant +
/// model badge + ALL attributes inlined as label·value chunks on one wrapping line.
/// This keeps each item to ~2-3 lines max so multiple orders fit per widget.
private struct ProductionItemRow: View {
    let item: WixOrder.LineItem

    var body: some View {
        let parsed = ProductNameParser.parse(name: item.name, apiVariant: nil)

        return HStack(alignment: .top, spacing: 6) {
            // Quantity pill — fixed-size, no frame after background
            Text("×\(item.quantity)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.wpAccent)
                )

            VStack(alignment: .leading, spacing: 1) {
                // Top: variant (color) + model + SKU all on one line
                HStack(spacing: 4) {
                    if let nameVariant = parsed.variant {
                        Text(nameVariant)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.wpAccent)
                            .lineLimit(1)
                    }
                    if let model = parsed.model {
                        Text(model)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 0)
                            .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                            .lineLimit(1)
                    }
                    if parsed.variant == nil && parsed.model == nil {
                        Text(item.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    if let sku = item.sku {
                        Text(sku)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }

                // Attributes inlined as one Text with bold values, wraps as needed
                if !item.attributes.isEmpty || item.variant != nil {
                    attributeText
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// Builds a single Text that concatenates "LABEL value · LABEL value · …"
    /// with values bolded in accent color. Renders as a single wrapping
    /// paragraph instead of a stack of separate views — guaranteed to flow
    /// inline regardless of widget width.
    private var attributeText: Text {
        if item.attributes.isEmpty {
            // Fallback for older cached snapshots that only have the joined string.
            if let v = item.variant {
                return Text(v)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color.wpAccent)
            }
            return Text("")
        }
        var result = Text("")
        for (idx, attr) in item.attributes.enumerated() {
            if idx > 0 {
                result = result + Text("  •  ")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.secondary.opacity(0.5))
            }
            result = result
                + Text(shortLabel(attr.label).uppercased() + ": ")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                + Text(attr.value)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color.wpAccent)
        }
        return result
    }
}

/// Shortens long attribute labels so they fit in a constrained widget row.
/// "Kompatybilny Inhalator" -> "INHALATOR", "Ilość wejść na inhalator w masce" -> "WEJŚĆ", etc.
private func shortLabel(_ label: String) -> String {
    let lower = label.lowercased()
    if lower.contains("rozmiar") || lower.contains("size") { return "Size" }
    if lower.contains("kolor") || lower.contains("color") || lower.contains("colour") { return "Color" }
    if lower.contains("inhalator") && !lower.contains("ilość") && !lower.contains("wejść") { return "Inhalator" }
    if lower.contains("ilość") || lower.contains("count") || lower.contains("qty") { return "Inputs" }
    // Fallback: take the first significant word (>3 chars), capped at 12 chars.
    let words = label.split(separator: " ").map(String.init)
    let pick = words.first(where: { $0.count > 3 }) ?? words.first ?? label
    return String(pick.prefix(12))
}

/// Splits a product display name into (base description · model · variant).
/// The heuristic: the LAST run of all-uppercase tokens (length ≥ 4) is the
/// "model" (e.g. EQUINEINHALER, ELASTIC). Anything after the model = variant
/// (color/size). Anything before = base description.
///
/// If the API gave us an explicit `apiVariant`, use that as the variant
/// regardless of what's in the name and trim it out.
enum ProductNameParser {
    struct Parsed {
        let base: String?
        let model: String?
        let variant: String?
    }

    static func parse(name: String, apiVariant: String?) -> Parsed {
        let words = name.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return Parsed(base: nil, model: nil, variant: nil) }

        // Locate the contiguous run of uppercase tokens (len >= 3) that ends latest in the name.
        var modelStart: Int? = nil
        var modelEnd: Int? = nil
        var i = 0
        while i < words.count {
            if isUpperToken(words[i]) {
                let start = i
                var j = i
                while j < words.count, isUpperToken(words[j]) { j += 1 }
                let end = j - 1
                if (modelEnd == nil) || end > modelEnd! {
                    modelStart = start
                    modelEnd = end
                }
                i = j
            } else {
                i += 1
            }
        }

        if let s = modelStart, let e = modelEnd {
            let model = words[s...e].joined(separator: " ")
            let baseWords = Array(words.prefix(s))
            let trailingWords = Array(words.suffix(from: e + 1))
            let base = baseWords.isEmpty ? nil : baseWords.joined(separator: " ")
            let variantFromName = trailingWords.isEmpty ? nil : trailingWords.joined(separator: " ")
            let variant = clean(apiVariant) ?? variantFromName
            return Parsed(base: base, model: model, variant: variant)
        }

        // No uppercase model found — surface the API variant if any, no model.
        if let v = clean(apiVariant) {
            // Trim variant from the end of the name to avoid duplicating it.
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasSuffix(v.lowercased()) {
                let base = String(trimmed.dropLast(v.count)).trimmingCharacters(in: CharacterSet(charactersIn: " ·-:,"))
                return Parsed(base: base.isEmpty ? nil : base, model: nil, variant: v)
            }
            return Parsed(base: name, model: nil, variant: v)
        }

        return Parsed(base: name, model: nil, variant: nil)
    }

    private static func isUpperToken(_ s: String) -> Bool {
        guard s.count >= 3 else { return false }
        return s.allSatisfy { $0.isUppercase || $0.isNumber || $0 == "-" || $0 == "_" }
            && s.contains(where: { $0.isLetter })
    }

    private static func clean(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s.trimmingCharacters(in: .whitespaces)
    }
}

private struct OrderCardRow: View {
    let order: WixOrder
    let compact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Quantity badge — first thing operator sees
            qtyBadge

            // Main info column
            VStack(alignment: .leading, spacing: 1) {
                // Header line: #number · time · payment dot
                HStack(spacing: 4) {
                    Text("#\(order.number)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary).font(.system(size: 9))
                    Text(order.createdDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                    paymentDot
                    fulfillmentDot
                }
                // Customer
                Text(order.buyerName ?? order.buyerEmail ?? "Guest")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                // Product summary — cleaner formatting
                productSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Total — bold, right-aligned, prominent
            Text(order.total.formatted)
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.wpHairline, lineWidth: 0.5)
        )
    }

    private var qtyBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.wpAccent.gradient)
                .frame(width: 26, height: 26)
            Text("×\(order.itemCount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
    }

    @ViewBuilder
    private var productSummary: some View {
        if compact {
            // Medium widget: one-line product list
            Text(order.lineItems.map { "\($0.name) ×\($0.quantity)" }.joined(separator: " · "))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } else {
            // Large widget: list each product on its own line with SKU
            VStack(alignment: .leading, spacing: 0) {
                ForEach(order.lineItems.prefix(2)) { item in
                    HStack(spacing: 4) {
                        Text("×\(item.quantity)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.wpAccent)
                        Text(item.name)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if let sku = item.sku {
                            Text("· \(sku)")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
                if order.lineItems.count > 2 {
                    Text("+ \(order.lineItems.count - 2) more")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var paymentDot: some View {
        Circle()
            .fill(paymentColor)
            .frame(width: 5, height: 5)
            .help("Payment")
    }

    private var fulfillmentDot: some View {
        Circle()
            .fill(fulfillmentColor)
            .frame(width: 5, height: 5)
            .help("Fulfillment")
    }

    private var paymentColor: Color {
        switch order.paymentStatus {
        case .paid: return .wpPositive
        case .notPaid, .pending, .partiallyPaid: return .wpWarning
        case .refunded, .partiallyRefunded: return .wpDanger
        case .unknown: return .secondary
        }
    }

    private var fulfillmentColor: Color {
        switch order.fulfillmentStatus {
        case .fulfilled: return .wpPositive
        case .notFulfilled, .partiallyFulfilled: return .wpWarning
        case .canceled: return .wpDanger
        case .unknown: return .secondary
        }
    }
}

private struct OrderSparkline: View {
    let data: [OrderSummary.DailyRevenue]
    var body: some View {
        GeometryReader { geo in
            let counts = data.map { Double($0.orderCount) }
            let maxV = max(counts.max() ?? 1, 1)
            let stepX = data.count > 1 ? geo.size.width / CGFloat(data.count - 1) : 0
            let points: [CGPoint] = counts.enumerated().map { idx, v in
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
                    .fill(LinearGradient(colors: [Color.wpAccent.opacity(0.45), Color.wpAccent.opacity(0.02)], startPoint: .top, endPoint: .bottom))
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
    var message: String = "Open WixPulse to connect"
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "tray")
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
    OrdersWidget()
} timeline: {
    OrdersEntry(date: .now, orders: CachedSnapshot.placeholder.orders, summary: .placeholder, isPlaceholder: true, isFiltered: false)
}
