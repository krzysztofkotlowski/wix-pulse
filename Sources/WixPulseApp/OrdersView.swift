import SwiftUI
import WixPulseCore

struct OrdersView: View {
    @EnvironmentObject var store: AppStore
    @State private var statusFilter: StatusFilter = .toPrint
    @State private var search: String = ""

    enum StatusFilter: String, CaseIterable, Identifiable {
        case toPrint = "To print"
        case all = "All"
        case printed = "Printed"
        case unfulfilled = "Unfulfilled"
        case unpaid = "Unpaid"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .toPrint: return "printer"
            case .all: return "tray.full"
            case .printed: return "checkmark.seal"
            case .unfulfilled: return "shippingbox"
            case .unpaid: return "exclamationmark.circle"
            }
        }
    }

    var orders: [WixOrder] {
        let filtered: [WixOrder] = {
            switch statusFilter {
            case .toPrint:
                let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
                return store.filteredOrders
                    .filter { !store.isPrinted($0.id) }
                    .filter { $0.fulfillmentStatus == .notFulfilled || $0.fulfillmentStatus == .partiallyFulfilled }
                    .filter { $0.paymentStatus == .paid || $0.paymentStatus == .partiallyPaid }
                    .filter { $0.createdDate >= cutoff }
            case .all: return store.filteredOrders
            case .printed: return store.filteredOrders.filter { store.isPrinted($0.id) }
            case .unfulfilled: return store.filteredOrders.filter { $0.fulfillmentStatus == .notFulfilled || $0.fulfillmentStatus == .partiallyFulfilled }
            case .unpaid: return store.filteredOrders.filter { $0.paymentStatus == .notPaid || $0.paymentStatus == .pending }
            }
        }()
        guard !search.isEmpty else { return filtered }
        let q = search.lowercased()
        return filtered.filter {
            $0.number.lowercased().contains(q)
                || ($0.buyerName?.lowercased().contains(q) ?? false)
                || ($0.buyerEmail?.lowercased().contains(q) ?? false)
                || $0.lineItems.contains { $0.name.lowercased().contains(q) }
        }
    }

    var groupedOrders: [(String, [WixOrder])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: orders) { order -> String in
            if calendar.isDateInToday(order.createdDate) { return "Today" }
            if calendar.isDateInYesterday(order.createdDate) { return "Yesterday" }
            if let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
               order.createdDate >= weekStart { return "This week" }
            return "Earlier"
        }
        let order = ["Today", "Yesterday", "This week", "Earlier"]
        // For "To print" view, sort by oldest-first so operators clear the queue FIFO.
        let ascending = statusFilter == .toPrint
        return order.compactMap { key in
            guard let items = groups[key], !items.isEmpty else { return nil }
            let sorted = ascending
                ? items.sorted { $0.createdDate < $1.createdDate }
                : items.sorted { $0.createdDate > $1.createdDate }
            return (key, sorted)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, WP.Spacing.xl)
                .padding(.top, WP.Spacing.md)
                .padding(.bottom, WP.Spacing.md)

            if orders.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: WP.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedOrders, id: \.0) { (group, items) in
                            Section {
                                VStack(spacing: WP.Spacing.sm) {
                                    ForEach(items) { order in
                                        OrderCard(order: order)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group).wpEyebrowStyle()
                                    Spacer()
                                    Text("\(items.count) order\(items.count == 1 ? "" : "s")")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .background(Color.wpSurface.opacity(0.95))
                            }
                        }
                    }
                    .padding(.horizontal, WP.Spacing.xl)
                    .padding(.bottom, WP.Spacing.xl)
                }
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: WP.Spacing.md) {
            HStack(spacing: 4) {
                ForEach(StatusFilter.allCases) { f in
                    FilterPill(filter: f, selected: statusFilter == f) { statusFilter = f }
                }
            }

            if store.productFilter.isActive {
                WPChip("\(store.productFilter.selectedProductIds.count) products", style: .accent, icon: "line.3.horizontal.decrease")
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(.secondary)
                TextField("Search", text: $search)
                    .textFieldStyle(.plain)
                    .font(.callout)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
            .frame(maxWidth: 240)
        }
    }

    private var emptyState: some View {
        VStack(spacing: WP.Spacing.md) {
            Spacer()
            Image(systemName: statusFilter == .toPrint ? "checkmark.seal.fill" : "tray")
                .font(.system(size: 48, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(statusFilter == .toPrint ? Color.wpPositive : .secondary)
            Text(statusFilter == .toPrint ? "All caught up" : "No matching orders").font(.wpTitle())
            Text(statusFilter == .toPrint
                 ? "Every visible order has been printed."
                 : "Adjust the filter or refresh to load the latest orders.")
                .font(.wpBody())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FilterPill: View {
    let filter: OrdersView.StatusFilter
    let selected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: filter.icon).font(.system(size: 10, weight: .semibold))
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? Color.white : .primary)
            .background(
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.wpAccent.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(hovering ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
            .fixedSize()
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct OrderCard: View {
    @EnvironmentObject var store: AppStore
    let order: WixOrder
    @State private var expanded = false
    @State private var hovering = false

    private var isPrinted: Bool { store.isPrinted(order.id) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                summaryRow
                    .padding(WP.Spacing.lg)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Rectangle().fill(Color.wpHairline).frame(height: 0.5)
                detailBody
                    .padding(WP.Spacing.lg)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: WP.Radius.md, style: .continuous)
                .strokeBorder(
                    isPrinted ? Color.wpPositive.opacity(0.4)
                              : (hovering ? Color.wpAccent.opacity(0.5) : Color.wpHairline),
                    lineWidth: (isPrinted || hovering) ? 1 : 0.5
                )
        )
        .opacity(isPrinted ? 0.55 : 1.0)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .overlay(alignment: .topLeading) {
            if isPrinted {
                Text("PRINTED")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.wpPositive)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.wpPositive.opacity(0.15), in: Capsule())
                    .padding(8)
            }
        }
    }

    private var summaryRow: some View {
        HStack(alignment: .center, spacing: WP.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("#\(order.number)")
                        .font(.system(.callout, design: .monospaced, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(orderDateLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(order.createdDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if order.itemCount > 0 {
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(order.itemCount) item\(order.itemCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Text(order.buyerName ?? order.buyerEmail ?? "Guest")
                    .font(.system(.body, weight: .semibold))
                    .lineLimit(1)
                    .strikethrough(isPrinted, color: .secondary)
                Text(order.lineItems.map { $0.quantity > 1 ? "\($0.name) ×\($0.quantity)" : $0.name }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                Text(order.total.formatted)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                HStack(spacing: 4) {
                    paymentChip
                    fulfillmentChip
                }
            }
            // Quick-print toggle — works without expanding the card
            Button {
                store.togglePrinted(order.id)
            } label: {
                Image(systemName: isPrinted ? "checkmark.circle.fill" : "printer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isPrinted ? Color.wpPositive : .secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isPrinted ? "Mark as unprinted" : "Mark as printed")
            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
    }

    /// "Today" / "Yesterday" / "3 days ago" / "Apr 28" — relative date label.
    private var orderDateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(order.createdDate) { return "Today" }
        if cal.isDateInYesterday(order.createdDate) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: order.createdDate), to: cal.startOfDay(for: Date())).day ?? 0
        if days < 7 { return "\(days) days ago" }
        return order.createdDate.formatted(.dateTime.day().month(.abbreviated))
    }

    private var detailBody: some View {
        VStack(alignment: .leading, spacing: WP.Spacing.lg) {
            // Mark as printed action — at the top so it's the first thing operators reach
            HStack {
                Button {
                    store.togglePrinted(order.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPrinted ? "checkmark.circle.fill" : "printer.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(isPrinted ? "Mark as unprinted" : "Mark as printed")
                            .font(.callout.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .foregroundStyle(isPrinted ? Color.wpPositive : .white)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isPrinted
                                  ? AnyShapeStyle(Color.wpPositive.opacity(0.15))
                                  : AnyShapeStyle(Color.wpAccent.gradient))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isPrinted ? Color.wpPositive.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }

            // Items — invoice-style table
            DetailSection(title: "Items to pack", icon: "shippingbox.fill", count: "\(order.itemCount)") {
                VStack(spacing: 0) {
                    ForEach(Array(order.lineItems.enumerated()), id: \.element.id) { idx, item in
                        if idx > 0 {
                            Rectangle().fill(Color.wpHairline).frame(height: 0.5).padding(.leading, 44)
                        }
                        LineItemRow(item: item)
                    }
                }
                .background(Color.wpSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
            }

            // Customer + Ship to side-by-side
            HStack(alignment: .top, spacing: WP.Spacing.lg) {
                if order.buyerName != nil || order.buyerEmail != nil || order.buyerPhone != nil {
                    DetailSection(title: "Customer", icon: "person.crop.circle.fill") {
                        VStack(alignment: .leading, spacing: 6) {
                            if let n = order.buyerName {
                                infoLine(text: n, icon: "person.fill")
                            }
                            if let e = order.buyerEmail {
                                infoLine(text: e, icon: "envelope.fill", copyable: true)
                            }
                            if let p = order.buyerPhone {
                                infoLine(text: p, icon: "phone.fill", copyable: true, mono: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let addr = order.shippingAddress, !addr.oneLine.isEmpty {
                    DetailSection(title: "Ship to", icon: "mappin.and.ellipse") {
                        shippingLabel(addr: addr)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Pricing receipt
            DetailSection(title: "Pricing", icon: "creditcard.fill") {
                receiptBlock
            }

            // Buyer note callout
            if let note = order.note {
                DetailSection(title: "Buyer note", icon: "text.bubble.fill") {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle().fill(Color.wpAccent).frame(width: 3)
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                    }
                    .padding(10)
                    .background(Color.wpAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous))
                }
            }

            // Meta footer
            HStack(spacing: 16) {
                if let ch = order.channel { metaTag("Channel", ch.capitalized, icon: "antenna.radiowaves.left.and.right") }
                if let m = order.shippingMethod { metaTag("Shipping", m, icon: "shippingbox.and.arrow.backward.fill") }
                if let w = order.weight, w > 0 {
                    let unit = order.weightUnit?.lowercased() ?? "kg"
                    metaTag("Weight", "\(formatWeight(w)) \(unit)", icon: "scalemass.fill")
                }
                metaTag("Order ID", order.id, icon: "number", monospaced: true)
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var receiptBlock: some View {
        VStack(spacing: 4) {
            if let s = order.subtotal { receiptRow("Subtotal", s.formatted) }
            if let d = order.discount { receiptRow("Discount", "−" + d.formatted, tone: .wpPositive) }
            if let s = order.shipping { receiptRow("Shipping", s.formatted) }
            if let t = order.tax { receiptRow("Tax", t.formatted) }
            Rectangle().fill(Color.wpHairline).frame(height: 0.5).padding(.vertical, 4)
            receiptRow("Total", order.total.formatted, bold: true)
        }
        .padding(12)
        .background(Color.wpSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
    }

    @ViewBuilder
    private func receiptRow(_ label: String, _ value: String, bold: Bool = false, tone: Color = .primary) -> some View {
        HStack {
            Text(label)
                .font(bold ? .system(.callout, weight: .bold) : .system(.callout))
                .foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(.system(bold ? .body : .callout, design: .rounded, weight: bold ? .bold : .medium))
                .monospacedDigit()
                .foregroundStyle(tone)
        }
    }

    @ViewBuilder
    private func infoLine(text: String, icon: String, copyable: Bool = false, mono: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 14)
            Text(text)
                .font(mono ? .system(.callout, design: .monospaced) : .callout)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            if copyable {
                Button {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Copy")
            }
        }
    }

    @ViewBuilder
    private func shippingLabel(addr: WixOrder.Address) -> some View {
        let cityLine = [addr.postalCode, addr.city].compactMap { $0 }.joined(separator: " ")
        VStack(alignment: .leading, spacing: 1) {
            if let r = addr.recipient {
                Text(r).font(.system(.callout, weight: .semibold))
            }
            if let c = addr.company {
                Text(c).font(.callout).foregroundStyle(.secondary)
            }
            if let l1 = addr.line1 {
                Text(l1).font(.callout).foregroundStyle(.primary)
            }
            if let l2 = addr.line2 {
                Text(l2).font(.callout).foregroundStyle(.primary)
            }
            if !cityLine.isEmpty {
                Text(cityLine).font(.callout).foregroundStyle(.primary)
            }
            if let r = addr.region, addr.region != addr.country {
                Text(r).font(.callout).foregroundStyle(.secondary)
            }
            if let c = addr.country {
                Text(c).font(.callout).foregroundStyle(.secondary).fontWeight(.medium)
            }
        }
        .textSelection(.enabled)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.wpSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: WP.Radius.sm, style: .continuous).strokeBorder(Color.wpHairline, lineWidth: 0.5))
        .overlay(alignment: .topTrailing) {
            Button {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(addr.oneLine, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .help("Copy address")
        }
    }

    @ViewBuilder
    private func metaTag(_ label: String, _ value: String, icon: String, monospaced: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.wpAccent)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.system(monospaced ? .caption : .caption, design: monospaced ? .monospaced : .default))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private func formatWeight(_ w: Double) -> String {
        let f = NumberFormatter()
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f.string(from: w as NSNumber) ?? "\(w)"
    }

    private var paymentChip: WPChip {
        switch order.paymentStatus {
        case .paid: return WPChip("Paid", style: .positive)
        case .notPaid, .pending: return WPChip("Unpaid", style: .warning)
        case .refunded, .partiallyRefunded: return WPChip("Refunded", style: .danger)
        case .partiallyPaid: return WPChip("Partial", style: .warning)
        case .unknown: return WPChip("—", style: .neutral)
        }
    }

    private var fulfillmentChip: WPChip {
        switch order.fulfillmentStatus {
        case .fulfilled: return WPChip("Shipped", style: .positive)
        case .notFulfilled: return WPChip("Pending", style: .warning)
        case .partiallyFulfilled: return WPChip("Partial", style: .warning)
        case .canceled: return WPChip("Canceled", style: .danger)
        case .unknown: return WPChip("—", style: .neutral)
        }
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    var count: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.wpAccent)
                    .font(.system(size: 12, weight: .semibold))
                Text(title).wpEyebrowStyle()
                if let count {
                    Text(count)
                        .font(.system(size: 9, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.wpAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.wpAccent.opacity(0.14), in: Capsule())
                }
                Spacer()
            }
            content()
        }
    }
}

private struct LineItemRow: View {
    let item: WixOrder.LineItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            qtyBadge
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.callout, weight: .semibold))
                    .lineLimit(2)
                    .textSelection(.enabled)

                // Structured attributes — one chip per descriptionLine for legibility
                if !item.attributes.isEmpty {
                    FlowAttributes(attributes: item.attributes)
                        .padding(.top, 1)
                }

                HStack(spacing: 6) {
                    if let sku = item.sku {
                        HStack(spacing: 3) {
                            Image(systemName: "barcode")
                                .font(.system(size: 9, weight: .semibold))
                            Text(sku)
                                .font(.system(.caption2, design: .monospaced, weight: .medium))
                                .textSelection(.enabled)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05), in: Capsule())
                    }
                    if let unit = item.unitPrice {
                        Text("\(unit.formatted) × \(item.quantity)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
                .padding(.top, 1)
            }
            Spacer(minLength: 8)
            if let total = item.lineTotal {
                Text(total.formatted)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            } else if let unit = item.unitPrice {
                Text(unit.formatted)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var qtyBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.wpAccent.gradient)
                .frame(width: 32, height: 32)
            Text("×\(item.quantity)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
    }
}

/// Renders product attributes as label-value chip pairs that wrap onto multiple
/// lines, like inline tags. Each chip shows "LABEL value" so a 3D-print operator
/// can see size/compatibility/color at a glance.
private struct FlowAttributes: View {
    let attributes: [WixOrder.Attribute]

    var body: some View {
        // SwiftUI doesn't have a built-in flow layout, but a Layout works on macOS 13+.
        // Use a simple wrapping HStack via Layout protocol.
        AttributeFlow(spacing: 6, lineSpacing: 4) {
            ForEach(attributes) { attr in
                HStack(spacing: 4) {
                    Text(attr.label)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(attr.value)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.wpAccent)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.wpAccent.opacity(0.08), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.wpAccent.opacity(0.18), lineWidth: 0.5))
            }
        }
    }
}

/// Simple flow layout that wraps children to a new line when they exceed the
/// proposed width. macOS 13+.
private struct AttributeFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                maxLineWidth = max(maxLineWidth, x - spacing)
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, x - spacing)
        return CGSize(width: maxLineWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x - bounds.minX + size.width > maxWidth, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
