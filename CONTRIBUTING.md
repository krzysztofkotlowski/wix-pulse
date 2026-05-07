# Contributing

Thanks for your interest! WixPulse is a small project — PRs and issues are welcome.

## Setup

```bash
./scripts/bootstrap.sh
open WixPulse.xcodeproj
```

## Project layout

- `project.yml` — XcodeGen spec. Edit this (not the generated `.xcodeproj`) and run `xcodegen generate`.
- `Sources/WixPulseCore/` — platform-agnostic Swift package. API client, models, analytics. Unit-tested.
- `Sources/WixPulseApp/` — main macOS app (SwiftUI).
- `Sources/OrdersWidget/`, `Sources/AnalyticsWidget/` — WidgetKit extensions.

## Before opening a PR

- `swift test --package-path Sources/WixPulseCore` passes.
- `xcodebuild -scheme WixPulse build` succeeds.
- New behavior in `WixPulseCore` has a test.

## Don't commit

- Real API keys / site IDs.
- The generated `WixPulse.xcodeproj/` (it's in `.gitignore`).
