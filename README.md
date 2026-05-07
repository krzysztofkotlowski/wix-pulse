# WixPulse

A native macOS app and desktop widgets that turn a [Wix](https://www.wix.com/) shop's order feed into a fulfillment-ready production queue. Built with SwiftUI + WidgetKit + Swift Charts. The API key never leaves the device — it's stored in the macOS Keychain and the widgets read only locally-cached snapshots.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/license-MIT-green) ![SwiftUI](https://img.shields.io/badge/SwiftUI-WidgetKit-purple)

> Built originally to run a small 3D-printing fulfillment workflow for a Wix shop — the operator opens the laptop, glances at the desktop widget, prints the next item, marks it done, and the queue updates everywhere instantly.

## Screenshots

<p align="center">
  <img src="screenshots/01-widgets.png" alt="WixPulse widgets on the macOS desktop" width="100%" />
  <em>Recent Orders and WIX Analytics widgets pinned to the desktop, alongside macOS native widgets.</em>
</p>

<table>
  <tr>
    <td width="50%"><img src="screenshots/02-orders.png" alt="Orders view — production queue with status filters" /></td>
    <td width="50%"><img src="screenshots/03-analytics.png" alt="Analytics view — revenue hero card and 7-day chart" /></td>
  </tr>
  <tr>
    <td align="center"><b>Orders</b> — production queue with To-print / Printed / Unfulfilled / Unpaid filters and oldest-first sorting.</td>
    <td align="center"><b>Analytics</b> — today's revenue hero, 30-day metrics, and a 7-day Swift Charts breakdown.</td>
  </tr>
  <tr>
    <td colspan="2"><img src="screenshots/04-settings.png" alt="Settings view — API key, refresh interval, product filter" /></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><b>Settings</b> — API key stored in Keychain, refresh interval, and a product filter that scopes both app and widgets to the SKUs you care about.</td>
  </tr>
</table>

> The screenshots above are rendered with seed data from the [`screenshots-mock`](https://github.com/krzysztofkotlowski/wix-pulse/tree/screenshots-mock) branch (a fictional tabletop-miniatures studio). The `main` branch hits the real Wix REST API.

## Features

### Production queue (the main loop)
- **"To print" widget** (Small / Medium / Large / Extra Large) — shows only the orders that still need to be printed and shipped, sorted **oldest-first** so the queue is FIFO. Filters out anything already printed, fulfilled, canceled, or older than 14 days.
- **Mark as printed** — one-click action on every order card (in the app) or in the expanded detail. Printed orders disappear from the widget queue immediately and the sidebar badge updates.
- **Smart staleness warning** — the widget header chip turns orange when the oldest pending order is ≥1 day old, red when ≥3 days. Catches forgotten orders without the operator opening the app.
- **Per-item production detail** — each order in the Large widget shows the quantity badge, color/variant, model identifier, SKU, and structured attributes (Size, compatibility, options) parsed out of Wix's `descriptionLines`. Enough info to print without opening anything.

### Order management
- **Operator-grade detail view** — click any order in the app to expand: full line-items table with × quantity badges, variant info, SKUs, unit price; customer block with copy-to-clipboard email and phone; address rendered as a real shipping label; pricing receipt; buyer notes in a callout; and a meta footer with channel / weight / order ID.
- **Status filters** — `To print`, `All`, `Printed`, `Unfulfilled`, `Unpaid`. Search by order number, customer name, email, or product name.
- **Date grouping** — orders grouped by Today / Yesterday / This week / Earlier with relative date labels ("3 days ago", "Apr 28").
- **Product filter** — Settings discovers every product from your recent orders, ranked by frequency. Pick the ones you care about and both the app and widgets show only those.

### Analytics
- **Hero card** — today's revenue as a large rounded numeral with a sparkline of the past 7 days.
- **Metric grid** — today's orders, 30-day orders, 30-day revenue, average order value, with pace indicators (▲ N% vs avg).
- **Charts** — bar chart of revenue, line+area chart of orders, both Swift Charts.
- **Analytics widget** (Small / Medium / Large / Extra Large) for at-a-glance numbers on the desktop.

### Quality of life
- Refined macOS-Tahoe-friendly palette — cool slate accent, charcoal surface, regular-material cards, hairline borders.
- Auto-ticking "Updated X ago" using `Text(_:style:.relative)`.
- Resilient API decoder — per-order tolerance so one malformed order doesn't kill the whole response. Cleans `"undefined"` / `"null"` strings before they hit the UI. Handles WIX's habit of returning `weightTotal` as a string and line-item images as objects.
- 20s request timeout so a stalled connection can't soft-hang the app.
- App is sandboxed with `network.client` only. App key + Site ID never leave the machine.

## Requirements

- **macOS 14 Sonoma** or later (developed on macOS 26 Tahoe)
- **Xcode 15** or later
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — `brew install xcodegen`
- A Wix account with an [API key](https://manage.wix.com/account/api-keys)

## Quick start

```bash
git clone https://github.com/krzysztofkotlowski/wix-pulse.git
cd wix-pulse
./scripts/bootstrap.sh    # installs xcodegen if needed, generates WixPulse.xcodeproj
open WixPulse.xcodeproj
```

In Xcode:
1. Set your **Team** in Signing & Capabilities for all 3 targets (`WixPulse`, `OrdersWidgetExtension`, `AnalyticsWidgetExtension`).
2. Select the **WixPulse** scheme, destination **My Mac**, run with `⌘R`.
3. Open the in-app **Settings** tab, paste your API key + Site ID, click **Save**.
4. Right-click your desktop → **Edit Widgets** → search **WixPulse** → drag *Recent Orders* and *WIX Analytics* widgets onto the desktop or into Notification Center.

## Getting your Wix credentials

1. Open the [Wix Dashboard → API Keys](https://manage.wix.com/account/api-keys).
2. **Generate API Key**, name it `WixPulse`, grant `Wix Stores → Read Stores` and `Wix eCommerce → Read Orders`.
3. Copy the key once shown — Wix won't display it again.
4. Find your **Site ID** in the dashboard URL: `manage.wix.com/dashboard/<SITE_ID>/...`
5. Paste both into WixPulse → Settings.

## Architecture

```
WixPulse/                                 macOS app target (SwiftUI)
└── Sources/
    ├── WixPulseApp/                      App + sidebar + Orders + Analytics + Settings + design system
    │   ├── AppStore.swift                @MainActor ObservableObject — owns snapshot, filter, printed-tracking
    │   ├── RootView.swift                NavigationSplitView with sidebar + detail + global error banner
    │   ├── OrdersView.swift              Production queue, expandable detail, mark-as-printed
    │   ├── AnalyticsView.swift           Hero card + metric grid + Swift Charts
    │   ├── SettingsView.swift            API credentials, refresh interval, product filter UI
    │   └── AppButtons.swift              ButtonStyle conformances (.wpPrimary, .wpGhost, .wpDanger, .wpIcon)
    │
    ├── WixPulseCore/                     Shared Swift Package (testable, platform-agnostic)
    │   └── Sources/WixPulseCore/
    │       ├── Models.swift              WixOrder, LineItem, Attribute, Address, Money, OrderSummary
    │       ├── WixAPIClient.swift        async/await client for /ecom/v1/orders/search with resilient decoder
    │       ├── Analytics.swift           summarize(orders:) → revenue + 7-day breakdown + most-common currency
    │       ├── ProductFilter.swift       Discovers products from line items, applies filter
    │       ├── SharedStorage.swift       UserDefaults via App Group + printed-order tracking
    │       ├── Keychain.swift            SecItem wrapper for API key
    │       ├── Refresher.swift           Actor that fetches + persists + reloads widget timelines
    │       └── Design.swift              Tokens (WP.Spacing, WP.Radius), colors, fonts, shared SwiftUI primitives
    │
    ├── OrdersWidget/                     WidgetKit extension — production queue
    │   ├── OrdersWidget.swift            WidgetBundle + TimelineProvider with print/ship filtering
    │   └── OrdersWidgetView.swift        Small / Medium / Large / Extra Large layouts
    │
    └── AnalyticsWidget/                  WidgetKit extension — revenue dashboard
        ├── AnalyticsWidget.swift         WidgetBundle + TimelineProvider
        └── AnalyticsWidgetView.swift     Small / Medium / Large with Charts + sparklines
```

**Data flow:** Main app calls Wix REST API → `Refresher` saves a `CachedSnapshot` into the App Group `UserDefaults` → widgets read from the same App Group on each timeline reload. Marking an order printed mutates a `Set<String>` in the App Group and triggers `WidgetCenter.shared.reloadAllTimelines()`. Widgets never make network calls — they work offline using whatever the app last cached.

**Why XcodeGen?** `.xcodeproj` files are XML soup that conflict on every change and bake in personal team identifiers. `project.yml` is human-readable, diffs cleanly, and is the single source of truth.

## Development

```bash
xcodegen generate                                      # regenerate .xcodeproj after editing project.yml
swift test --package-path Sources/WixPulseCore         # run core unit tests
xcodebuild -scheme WixPulse -destination 'platform=macOS' \
  -derivedDataPath /tmp/wixpulse-build build           # CLI build (avoids stomping Xcode's DerivedData)
```

## Configuration

| Item | Where | Default |
|---|---|---|
| Bundle ID prefix | `project.yml` → `bundleIdPrefix` | `com.kkotlowski.wixpulse` (change to your reverse-DNS) |
| App Group | All 3 `.entitlements` files | `group.com.kkotlowski.wixpulse` |
| Refresh interval | App → Settings | 15 min (5/15/30/60 supported) |
| Print-queue cutoff | `OrdersWidget.swift` / `OrdersView.swift` | 14 days |

> **Forking:** Search-and-replace `kkotlowski` with your own reverse-DNS prefix in `project.yml` and the three `.entitlements` files, then re-run `xcodegen generate`.

## Roadmap

- [ ] iOS app + Lock Screen widgets
- [ ] OAuth so users don't have to generate their own API keys
- [ ] Menu-bar companion mode
- [ ] CSV export of pending orders
- [ ] Per-widget product filters
- [ ] Localization (currently English/Polish-friendly)

## License

MIT © 2026 Krzysztof Kotłowski

---

WixPulse is an independent project and is not affiliated with or endorsed by Wix.com, Ltd.
