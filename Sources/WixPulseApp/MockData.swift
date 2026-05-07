import Foundation
import WixPulseCore

/// Mock seed data for portfolio screenshots. Only compiled into the
/// `screenshots-mock` branch — main branch never uses this.
///
/// Models a fictional 3D-printing business: "Forgewright Miniatures",
/// a tabletop-gaming miniatures studio. Products have natural variants
/// (Scale, Material, Finish, Base) that show off the structured-attribute
/// rendering in the widgets without overflowing the layout.
enum MockData {

    static let snapshot: CachedSnapshot = {
        let now = Date()
        let cal = Calendar.current
        func daysAgo(_ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
            let day = cal.date(byAdding: .day, value: -d, to: now) ?? now
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let orders: [WixOrder] = [
            // Today
            order(id: "ord-1", number: "20247", date: daysAgo(0, hour: 14, minute: 22),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Sarah Chen", "sarah.chen@gmail.com", "+1 415 555 0142"),
                  items: [
                    item(name: "Ancient Red Dragon", qty: 1, sku: "DRG-RED-75",
                         unit: 45,
                         attrs: [("Scale", "75mm"), ("Material", "Resin"), ("Finish", "Unpainted")]),
                  ],
                  total: 45, addr: usAddress("Sarah Chen", "1247 Castro St", "San Francisco", "CA", "94114")),

            order(id: "ord-2", number: "20246", date: daysAgo(0, hour: 11, minute: 5),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("James Whitmore", "j.whitmore@protonmail.com", "+44 20 7946 0119"),
                  items: [
                    item(name: "Skeleton Warrior Squad", qty: 2, sku: "UND-SKL-32",
                         unit: 18,
                         attrs: [("Scale", "32mm"), ("Material", "PLA+"), ("Finish", "Primed")]),
                  ],
                  total: 36, addr: ukAddress("James Whitmore", "47 Goodge Street, Flat 3", "London", "W1T 1TB")),

            order(id: "ord-3", number: "20245", date: daysAgo(0, hour: 9, minute: 41),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Maria González", "maria.g@icloud.com", "+34 91 555 8842"),
                  items: [
                    item(name: "Ranger of the North", qty: 1, sku: "HRO-RNG-32",
                         unit: 22,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Base", "Forest")]),
                    item(name: "Forest Terrain Pack", qty: 1, sku: "TER-FRS-PCK",
                         unit: 28,
                         attrs: [("Scale", "32mm"), ("Material", "PLA+")]),
                  ],
                  total: 50, addr: euAddress("Maria González", "Calle de Serrano 88", "Madrid", "28006", "Spain"),
                  note: "Birthday gift — please pack carefully"),

            // Yesterday
            order(id: "ord-4", number: "20244", date: daysAgo(1, hour: 19, minute: 47),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("David Klein", "d.klein@gmx.de", "+49 30 5550 1187"),
                  items: [
                    item(name: "Goblin Raider Pack", qty: 1, sku: "GOB-RDR-28",
                         unit: 24,
                         attrs: [("Scale", "28mm"), ("Material", "PLA+"), ("Finish", "Unpainted")]),
                  ],
                  total: 24, addr: euAddress("David Klein", "Friedrichstraße 112", "Berlin", "10117", "Germany")),

            order(id: "ord-5", number: "20243", date: daysAgo(1, hour: 14, minute: 10),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Emily Park", "emily.park@gmail.com", "+1 312 555 0288"),
                  items: [
                    item(name: "Dwarven Forge Set", qty: 1, sku: "DWF-SET-32",
                         unit: 65,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Finish", "Pre-supported")]),
                    item(name: "Magnetic Movement Tray", qty: 2, sku: "ACC-MAG-TRY",
                         unit: 12,
                         attrs: [("Size", "Medium"), ("Color", "Black")]),
                  ],
                  total: 89, addr: usAddress("Emily Park", "2204 N Lincoln Ave", "Chicago", "IL", "60614")),

            order(id: "ord-6", number: "20242", date: daysAgo(1, hour: 8, minute: 32),
                  paid: .notPaid, fulfilled: .notFulfilled,
                  customer: ("Thomas O'Brien", "t.obrien@gmail.com", "+1 617 555 0993"),
                  items: [
                    item(name: "Patreon · Hero Bundle (March)", qty: 1, sku: "SUB-HRO-MAR",
                         unit: 35,
                         attrs: [("Tier", "Hero"), ("Scale", "32mm"), ("Material", "Resin")]),
                  ],
                  total: 35, addr: usAddress("Thomas O'Brien", "184 Beacon Street", "Boston", "MA", "02116")),

            // 2-3 days ago — already marked printed
            order(id: "ord-7", number: "20241", date: daysAgo(2, hour: 16, minute: 18),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Sophie Martin", "sophie.martin@orange.fr", "+33 1 4555 7821"),
                  items: [
                    item(name: "Elven Archer Squad", qty: 1, sku: "ELF-ARC-32",
                         unit: 32,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Finish", "Primed")]),
                  ],
                  total: 32, addr: euAddress("Sophie Martin", "12 rue de Rivoli", "Paris", "75004", "France")),

            order(id: "ord-8", number: "20240", date: daysAgo(2, hour: 10, minute: 4),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Marcus Williams", "m.williams@yahoo.com", "+1 213 555 4471"),
                  items: [
                    item(name: "Frost Giant", qty: 1, sku: "GNT-FST-75",
                         unit: 42,
                         attrs: [("Scale", "75mm"), ("Material", "Resin"), ("Base", "Snow")]),
                  ],
                  total: 42, addr: usAddress("Marcus Williams", "8420 Sunset Blvd", "Los Angeles", "CA", "90069")),

            order(id: "ord-9", number: "20239", date: daysAgo(3, hour: 18, minute: 51),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Laura Schneider", "l.schneider@web.de", "+49 89 5550 2244"),
                  items: [
                    item(name: "Goblin Raider Pack", qty: 4, sku: "GOB-RDR-28",
                         unit: 24,
                         attrs: [("Scale", "28mm"), ("Material", "PLA+"), ("Finish", "Unpainted")]),
                  ],
                  total: 96, addr: euAddress("Laura Schneider", "Maximilianstraße 24", "München", "80539", "Germany"),
                  note: "Game club bulk order — invoice to billing@laurasdesign.de"),

            order(id: "ord-10", number: "20238", date: daysAgo(3, hour: 12, minute: 25),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Olivia Foster", "olivia.foster@gmail.com", "+1 503 555 6677"),
                  items: [
                    item(name: "Wizard of the Tower", qty: 1, sku: "HRO-WIZ-32",
                         unit: 22,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Finish", "Pre-supported")]),
                  ],
                  total: 22, addr: usAddress("Olivia Foster", "1822 NW Glisan St", "Portland", "OR", "97209")),

            // 4-5 days ago
            order(id: "ord-11", number: "20237", date: daysAgo(4, hour: 21, minute: 12),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Daniel Reyes", "d.reyes@gmail.com", "+1 786 555 1100"),
                  items: [
                    item(name: "Ancient Red Dragon", qty: 1, sku: "DRG-RED-75",
                         unit: 45,
                         attrs: [("Scale", "75mm"), ("Material", "Resin"), ("Finish", "Unpainted")]),
                  ],
                  total: 45, addr: usAddress("Daniel Reyes", "1500 Brickell Ave", "Miami", "FL", "33129")),

            order(id: "ord-12", number: "20236", date: daysAgo(4, hour: 15, minute: 47),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Charlotte Adams", "charlotte.adams@btinternet.com", "+44 161 555 7890"),
                  items: [
                    item(name: "Magnetic Movement Tray", qty: 3, sku: "ACC-MAG-TRY",
                         unit: 12,
                         attrs: [("Size", "Large"), ("Color", "Black")]),
                  ],
                  total: 36, addr: ukAddress("Charlotte Adams", "32 Deansgate", "Manchester", "M3 2RH")),

            order(id: "ord-13", number: "20235", date: daysAgo(5, hour: 10, minute: 33),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Henry Thompson", "h.thompson@gmail.com", "+1 720 555 3344"),
                  items: [
                    item(name: "Ranger of the North", qty: 1, sku: "HRO-RNG-32",
                         unit: 22,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Base", "Forest")]),
                    item(name: "Forest Terrain Pack", qty: 1, sku: "TER-FRS-PCK",
                         unit: 28,
                         attrs: [("Scale", "32mm"), ("Material", "PLA+")]),
                  ],
                  total: 50, addr: usAddress("Henry Thompson", "1500 Pearl Street", "Boulder", "CO", "80302")),

            order(id: "ord-14", number: "20234", date: daysAgo(5, hour: 8, minute: 18),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Anaïs Dubois", "anais.dubois@laposte.net", "+33 4 9255 0782"),
                  items: [
                    item(name: "Skeleton Warrior Squad", qty: 1, sku: "UND-SKL-32",
                         unit: 18,
                         attrs: [("Scale", "32mm"), ("Material", "PLA+"), ("Finish", "Primed")]),
                  ],
                  total: 18, addr: euAddress("Anaïs Dubois", "47 Cours Mirabeau", "Aix-en-Provence", "13100", "France")),

            // 6-8 days ago
            order(id: "ord-15", number: "20233", date: daysAgo(6, hour: 17, minute: 22),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Robert Patel", "robert.patel@outlook.com", "+1 425 555 8821"),
                  items: [
                    item(name: "Patreon · Hero Bundle (March)", qty: 1, sku: "SUB-HRO-MAR",
                         unit: 35,
                         attrs: [("Tier", "Hero"), ("Scale", "32mm"), ("Material", "Resin")]),
                  ],
                  total: 35, addr: usAddress("Robert Patel", "550 106th Ave NE", "Bellevue", "WA", "98004")),

            order(id: "ord-16", number: "20232", date: daysAgo(7, hour: 13, minute: 8),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Isabella Rossi", "isabella.rossi@libero.it", "+39 02 5550 4477"),
                  items: [
                    item(name: "Dwarven Forge Set", qty: 2, sku: "DWF-SET-32",
                         unit: 65,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Finish", "Pre-supported")]),
                  ],
                  total: 130, addr: euAddress("Isabella Rossi", "Via Brera 28", "Milano", "20121", "Italy"),
                  note: "Wholesale account — bulk pricing applied"),

            order(id: "ord-17", number: "20231", date: daysAgo(7, hour: 9, minute: 55),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("William Carter", "w.carter@gmail.com", "+1 678 555 1199"),
                  items: [
                    item(name: "Frost Giant", qty: 2, sku: "GNT-FST-75",
                         unit: 42,
                         attrs: [("Scale", "75mm"), ("Material", "Resin"), ("Base", "Snow")]),
                  ],
                  total: 84, addr: usAddress("William Carter", "1280 Peachtree St NE", "Atlanta", "GA", "30309")),

            order(id: "ord-18", number: "20230", date: daysAgo(8, hour: 16, minute: 4),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Grace Bennett", "grace.bennett@me.com", "+1 206 555 0099"),
                  items: [
                    item(name: "Wizard of the Tower", qty: 1, sku: "HRO-WIZ-32",
                         unit: 22,
                         attrs: [("Scale", "32mm"), ("Material", "Resin"), ("Finish", "Pre-supported")]),
                  ],
                  total: 22, addr: usAddress("Grace Bennett", "2100 Westlake Ave N", "Seattle", "WA", "98109")),
        ]

        let summary = Analytics.summarize(orders: orders, fallbackCurrency: "USD")
        return CachedSnapshot(orders: orders, summary: summary)
    }()

    /// IDs of orders pre-marked as printed so the "Printed" filter has content
    /// for screenshots. Three recent ones are printed, leaving the rest pending.
    static let printedOrderIds: Set<String> = ["ord-7", "ord-8", "ord-10"]

    // MARK: - Builders

    private static func order(
        id: String, number: String, date: Date,
        paid: WixOrder.PaymentStatus, fulfilled: WixOrder.FulfillmentStatus,
        customer: (name: String, email: String, phone: String),
        items: [WixOrder.LineItem],
        total: Int, addr: WixOrder.Address,
        note: String? = nil
    ) -> WixOrder {
        WixOrder(
            id: id, number: number, createdDate: date,
            status: .approved, paymentStatus: paid, fulfillmentStatus: fulfilled,
            total: Money(amount: Decimal(total), currency: "USD"),
            subtotal: Money(amount: Decimal(max(total - 6, 0)), currency: "USD"),
            shipping: Money(amount: 6, currency: "USD"),
            tax: nil, discount: nil,
            lineItems: items,
            buyerName: customer.name, buyerEmail: customer.email, buyerPhone: customer.phone,
            shippingAddress: addr, billingAddress: addr,
            shippingMethod: "USPS Priority Mail",
            paymentMethod: nil,
            note: note,
            channel: "web",
            weight: 0.5, weightUnit: "lb"
        )
    }

    private static func item(name: String, qty: Int, sku: String, unit: Int, attrs: [(String, String)]) -> WixOrder.LineItem {
        let attributes = attrs.map { WixOrder.Attribute(label: $0.0, value: $0.1) }
        let variant = attributes.isEmpty ? nil : attributes.map { "\($0.label): \($0.value)" }.joined(separator: " · ")
        return WixOrder.LineItem(
            productId: sku, name: name, quantity: qty,
            sku: sku,
            unitPrice: Money(amount: Decimal(unit), currency: "USD"),
            lineTotal: Money(amount: Decimal(unit * qty), currency: "USD"),
            variant: variant,
            attributes: attributes
        )
    }

    private static func usAddress(_ name: String, _ line1: String, _ city: String, _ state: String, _ zip: String) -> WixOrder.Address {
        WixOrder.Address(line1: line1, line2: nil, city: city, region: state,
                         postalCode: zip, country: "United States", recipient: name, company: nil)
    }
    private static func ukAddress(_ name: String, _ line1: String, _ city: String, _ postcode: String) -> WixOrder.Address {
        WixOrder.Address(line1: line1, line2: nil, city: city, region: "England",
                         postalCode: postcode, country: "United Kingdom", recipient: name, company: nil)
    }
    private static func euAddress(_ name: String, _ line1: String, _ city: String, _ postcode: String, _ country: String) -> WixOrder.Address {
        WixOrder.Address(line1: line1, line2: nil, city: city, region: nil,
                         postalCode: postcode, country: country, recipient: name, company: nil)
    }
}
