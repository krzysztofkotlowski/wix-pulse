import Foundation
import WixPulseCore

/// Mock seed data for portfolio screenshots. Only compiled into the
/// `screenshots-mock` branch — main branch never uses this.
///
/// Produces 18 orders spanning today through 8 days ago with realistic
/// variety: different products, colors, sizes, payment statuses, fulfillment
/// states, line-item counts, addresses, notes, and a sprinkling of orders
/// already marked printed so the queue/printed/all filters all have content.
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
            order(id: "ord-1", number: "10172", date: daysAgo(0, hour: 14, minute: 22),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Anna Kowalska", "anna.kowalska@gmail.com", "+48 601 234 567"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Lava Red", qty: 1,
                         sku: "EQ-EL-LAVA", unit: 690,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: krakowAddress(name: "Anna Kowalska"),
                  note: "Proszę o dyskretne pakowanie, prezent dla córki"),

            order(id: "ord-2", number: "10171", date: daysAgo(0, hour: 11, minute: 5),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Marek Nowak", "marek.nowak@wp.pl", "+48 605 112 998"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Baby Blue", qty: 2,
                         sku: "EQ-CL-BABY", unit: 211,
                         attrs: [("Rozmiar", "cob"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo")]),
                  ],
                  total: 422, addr: warsawAddress(name: "Marek Nowak")),

            order(id: "ord-3", number: "10170", date: daysAgo(0, hour: 9, minute: 41),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Joanna Wiśniewska", "joanna.w@icloud.com", "+48 502 887 332"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Glacial Blue", qty: 1,
                         sku: "EQ-EL-GLAC", unit: 690,
                         attrs: [("Rozmiar", "pony"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo (opcja z saszetką na szyję)"), ("Ilość wejść", "1")]),
                    item(name: "Pas zad pomoc do lonżowania", qty: 1,
                         sku: "ACC-PAS-01", unit: 130,
                         attrs: []),
                  ],
                  total: 820, addr: gdanskAddress(name: "Joanna Wiśniewska"),
                  note: "Proszę zapakować osobno"),

            // Yesterday
            order(id: "ord-4", number: "10169", date: daysAgo(1, hour: 19, minute: 47),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Piotr Lewandowski", "p.lewandowski@gmail.com", "+48 698 441 220"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Lovely Violet", qty: 1,
                         sku: "EQ-CL-VIO", unit: 475,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 475, addr: poznanAddress(name: "Piotr Lewandowski")),

            order(id: "ord-5", number: "10168", date: daysAgo(1, hour: 14, minute: 10),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Karolina Zielińska", "kasienka.zielinska@gmail.com", "+48 535 102 887"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Glacial Blue", qty: 1,
                         sku: "EQ-EL-GLAC", unit: 690,
                         attrs: [("Rozmiar", "cob"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: wroclawAddress(name: "Karolina Zielińska")),

            order(id: "ord-6", number: "10167", date: daysAgo(1, hour: 8, minute: 32),
                  paid: .notPaid, fulfilled: .notFulfilled,
                  customer: ("Tomasz Jankowski", "tomek.j@interia.pl", "+48 511 778 921"),
                  items: [
                    item(name: "Inhalator FLAEM Nebulair+", qty: 1,
                         sku: "INH-FL-NEB", unit: 1091,
                         attrs: []),
                  ],
                  total: 1091, addr: warsawAddress(name: "Tomasz Jankowski")),

            // 2-3 days ago — already marked printed by operator
            order(id: "ord-7", number: "10166", date: daysAgo(2, hour: 16, minute: 18),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Magdalena Szymańska", "m.szymanska@onet.pl", "+48 600 887 112"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Lava Red", qty: 1,
                         sku: "EQ-EL-LAVA", unit: 690,
                         attrs: [("Rozmiar", "pony"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: krakowAddress(name: "Magdalena Szymańska")),

            order(id: "ord-8", number: "10165", date: daysAgo(2, hour: 10, minute: 4),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Jakub Wójcik", "jakub.wojcik@gmail.com", "+48 502 110 887"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Baby Blue", qty: 1,
                         sku: "EQ-CL-BABY", unit: 422,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo")]),
                  ],
                  total: 422, addr: poznanAddress(name: "Jakub Wójcik")),

            order(id: "ord-9", number: "10164", date: daysAgo(3, hour: 18, minute: 51),
                  paid: .paid, fulfilled: .notFulfilled,
                  customer: ("Aleksandra Kamińska", "ola.kaminska@wp.pl", "+48 605 332 778"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Lovely Violet", qty: 2,
                         sku: "EQ-EL-VIO", unit: 690,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 1380, addr: warsawAddress(name: "Aleksandra Kamińska"),
                  note: "Pilne — koń startuje w zawodach w przyszłym tygodniu"),

            order(id: "ord-10", number: "10163", date: daysAgo(3, hour: 12, minute: 25),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Michał Dąbrowski", "michal.dabrowski@gmail.com", "+48 698 221 005"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Glacial Blue", qty: 1,
                         sku: "EQ-CL-GLAC", unit: 422,
                         attrs: [("Rozmiar", "cob"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo")]),
                  ],
                  total: 422, addr: wroclawAddress(name: "Michał Dąbrowski")),

            // 4-5 days ago
            order(id: "ord-11", number: "10162", date: daysAgo(4, hour: 21, minute: 12),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Natalia Pawlak", "natalia.pawlak@gmail.com", "+48 535 998 110"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Baby Blue", qty: 1,
                         sku: "EQ-EL-BABY", unit: 690,
                         attrs: [("Rozmiar", "pony"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: gdanskAddress(name: "Natalia Pawlak")),

            order(id: "ord-12", number: "10161", date: daysAgo(4, hour: 15, minute: 47),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Krzysztof Wojciechowski", "krzysiek.w@interia.pl", "+48 600 445 887"),
                  items: [
                    item(name: "Pas zad pomoc do lonżowania", qty: 1,
                         sku: "ACC-PAS-01", unit: 66,
                         attrs: []),
                  ],
                  total: 66, addr: krakowAddress(name: "Krzysztof Wojciechowski")),

            order(id: "ord-13", number: "10160", date: daysAgo(5, hour: 10, minute: 33),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Ewa Krawczyk", "ewa.krawczyk@onet.pl", "+48 605 778 110"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Glacial Blue", qty: 1,
                         sku: "EQ-EL-GLAC", unit: 621,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo"), ("Ilość wejść", "1")]),
                  ],
                  total: 621, addr: poznanAddress(name: "Ewa Krawczyk")),

            order(id: "ord-14", number: "10159", date: daysAgo(5, hour: 8, minute: 18),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Robert Mazur", "robert.mazur@gmail.com", "+48 502 998 221"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Lovely Violet", qty: 1,
                         sku: "EQ-CL-VIO", unit: 475,
                         attrs: [("Rozmiar", "cob"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh")]),
                  ],
                  total: 475, addr: warsawAddress(name: "Robert Mazur")),

            // 6-8 days ago
            order(id: "ord-15", number: "10158", date: daysAgo(6, hour: 17, minute: 22),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Agnieszka Kaczmarek", "agnieszka.k@wp.pl", "+48 698 110 445"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Lava Red", qty: 1,
                         sku: "EQ-EL-LAVA", unit: 690,
                         attrs: [("Rozmiar", "full"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: gdanskAddress(name: "Agnieszka Kaczmarek")),

            order(id: "ord-16", number: "10157", date: daysAgo(7, hour: 13, minute: 8),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Łukasz Nowicki", "lukasz.nowicki@gmail.com", "+48 535 221 998"),
                  items: [
                    item(name: "Maska do inhalacji dla konia CLASSIC EQUINEINHALER Glacial Blue", qty: 3,
                         sku: "EQ-CL-GLAC", unit: 422,
                         attrs: [("Rozmiar", "pony"), ("Kompatybilny Inhalator", "TM-NEB Micro Mesh")]),
                  ],
                  total: 1266, addr: wroclawAddress(name: "Łukasz Nowicki"),
                  note: "Stadnina koni — 3 sztuki w zestawie"),

            order(id: "ord-17", number: "10156", date: daysAgo(7, hour: 9, minute: 55),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Patrycja Adamczyk", "patrycja.a@onet.pl", "+48 600 778 332"),
                  items: [
                    item(name: "Maska do inhalacji dla konia ELASTIC EQUINEINHALER Baby Blue", qty: 1,
                         sku: "EQ-EL-BABY", unit: 690,
                         attrs: [("Rozmiar", "cob"), ("Kompatybilny Inhalator", "FLAEM Wi.NebGo"), ("Ilość wejść", "1")]),
                  ],
                  total: 690, addr: krakowAddress(name: "Patrycja Adamczyk")),

            order(id: "ord-18", number: "10155", date: daysAgo(8, hour: 16, minute: 4),
                  paid: .paid, fulfilled: .fulfilled,
                  customer: ("Bartosz Górski", "bartek.gorski@gmail.com", "+48 605 110 887"),
                  items: [
                    item(name: "Inhalator FLAEM Nebulair+", qty: 1,
                         sku: "INH-FL-NEB", unit: 1091,
                         attrs: []),
                  ],
                  total: 1091, addr: poznanAddress(name: "Bartosz Górski")),
        ]

        let summary = Analytics.summarize(orders: orders, fallbackCurrency: "PLN")
        return CachedSnapshot(orders: orders, summary: summary)
    }()

    /// IDs of orders pre-marked as printed so the "Printed" filter has content
    /// for screenshots. Two recent ones are printed, leaving the rest pending.
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
            total: Money(amount: Decimal(total), currency: "PLN"),
            subtotal: Money(amount: Decimal(total - 15), currency: "PLN"),
            shipping: Money(amount: 15, currency: "PLN"),
            tax: nil, discount: nil,
            lineItems: items,
            buyerName: customer.name, buyerEmail: customer.email, buyerPhone: customer.phone,
            shippingAddress: addr, billingAddress: addr,
            shippingMethod: "InPost Paczkomat 24/7",
            paymentMethod: nil,
            note: note,
            channel: "web",
            weight: 0.4, weightUnit: "kg"
        )
    }

    private static func item(name: String, qty: Int, sku: String, unit: Int, attrs: [(String, String)]) -> WixOrder.LineItem {
        let attributes = attrs.map { WixOrder.Attribute(label: $0.0, value: $0.1) }
        let variant = attributes.isEmpty ? nil : attributes.map { "\($0.label): \($0.value)" }.joined(separator: " · ")
        return WixOrder.LineItem(
            productId: sku, name: name, quantity: qty,
            sku: sku,
            unitPrice: Money(amount: Decimal(unit), currency: "PLN"),
            lineTotal: Money(amount: Decimal(unit * qty), currency: "PLN"),
            variant: variant,
            attributes: attributes
        )
    }

    private static func krakowAddress(name: String) -> WixOrder.Address {
        WixOrder.Address(line1: "ul. Floriańska 12/4", line2: nil, city: "Kraków", region: "Małopolskie",
                         postalCode: "31-019", country: "Polska", recipient: name, company: nil)
    }
    private static func warsawAddress(name: String) -> WixOrder.Address {
        WixOrder.Address(line1: "ul. Marszałkowska 87", line2: "lok. 22", city: "Warszawa", region: "Mazowieckie",
                         postalCode: "00-683", country: "Polska", recipient: name, company: nil)
    }
    private static func gdanskAddress(name: String) -> WixOrder.Address {
        WixOrder.Address(line1: "ul. Długa 47", line2: nil, city: "Gdańsk", region: "Pomorskie",
                         postalCode: "80-831", country: "Polska", recipient: name, company: nil)
    }
    private static func wroclawAddress(name: String) -> WixOrder.Address {
        WixOrder.Address(line1: "ul. Świdnicka 8c", line2: nil, city: "Wrocław", region: "Dolnośląskie",
                         postalCode: "50-067", country: "Polska", recipient: name, company: nil)
    }
    private static func poznanAddress(name: String) -> WixOrder.Address {
        WixOrder.Address(line1: "ul. Półwiejska 32", line2: nil, city: "Poznań", region: "Wielkopolskie",
                         postalCode: "61-888", country: "Polska", recipient: name, company: nil)
    }
}
