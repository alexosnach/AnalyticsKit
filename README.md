# AnalyticsKit

A provider-agnostic analytics layer for Swift apps: one `AnalyticsService` that fans out to any number of analytics SDKs, with per-event routing, revenue tracking, typed `Sendable` parameters and a hashed, persistent user ID.

## Requirements

- Swift 6.2+ (Xcode 26+)
- iOS 17+ / macOS 14+

## Installation

In Xcode: **File → Add Package Dependencies…**, paste `https://github.com/alexosnach/AnalyticsKit.git`.

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/alexosnach/AnalyticsKit.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["AnalyticsKit"]),
]
```

Concrete SDK adapters (Amplitude, Firebase, a console provider, …) are **not** part of this package — they belong to your app. See [Writing a provider](#writing-a-provider).


## Quick start

```swift
import AnalyticsKit

// Composition Root
let analytics: AnalyticsService = CompositeAnalytics(providers: [
    AmplitudeAnalyticsProvider(apiKey: "…"),   // your app's adapter
    ConsoleAnalyticsProvider(),                // your app's adapter
])

let userIDProvider = AnonymousUserIDProvider(
    store: KeychainUserIDStore(onError: { print("\($0)") // or your logger }),
    hasher: SHA256IdentifierHasher()
)
analytics.setUserID(userIDProvider.currentUserID())

// Tracking
analytics.track(AnalyticsEvent(name: "paywall_shown", parameters: ["source": "onboarding"]))
```

## Typed parameters

Parameters and user properties are `AnalyticsParameters` (`[String: AnalyticsValue]`): `string`, `int`, `double` or `bool`. Literals work as before; a value an SDK can't serialise doesn't compile. In an adapter, `parameters.foundationValues` gives `[String: any Sendable]` for SDKs that take `Any`.

## Routing events to providers

Every provider declares its own `ProviderID` next to its adapter — the kit has no list of providers, so adding one never changes it:

```swift
extension ProviderID {
    static let amplitude = ProviderID("amplitude")
    static let appsFlyer = ProviderID("appsflyer")
}
```

An event goes to every provider by default; `destinations` narrows it:

```swift
analytics.track(AnalyticsEvent(name: "af_complete_registration", destinations: .only([.appsFlyer])))
analytics.track(AnalyticsEvent(name: "screen_view", destinations: .except([.appsFlyer])))
```

An ID of a provider that isn't plugged in is simply never matched. User identification (`setUserID`, `setUserProperties`, `reset`) always reaches every provider.

## Revenue

```swift
analytics.trackPurchase(Purchase(
    productID: "premium_yearly",
    transactionID: transaction.id.description,
    price: price,            // Decimal, one unit
    currency: "USD",         // ISO 4217
    destinations: .all       // or .only([...])
))
```

`Purchase` doesn't depend on StoreKit — convert your transaction type in the app. Only providers that also adopt `RevenueTracking` receive purchases; the others don't implement anything:

```swift
extension AmplitudeAnalyticsProvider: RevenueTracking {
    func trackPurchase(_ purchase: Purchase) {
        let revenue = Revenue()
        revenue.productId = purchase.productID
        revenue.price = NSDecimalNumber(decimal: purchase.price).doubleValue
        revenue.quantity = purchase.quantity
        amplitude.revenue(revenue: revenue)
    }
}
```

## SwiftUI

AnalyticsKit adds an `analytics` environment value (defaults to `NoOpAnalytics`, so previews stay silent):

```swift
@main
struct MyApp: App {
    let analytics: AnalyticsService = /* … */
    var body: some Scene {
        WindowGroup {
            RootView().environment(\.analytics, analytics)
        }
    }
}

struct PaywallView: View {
    @Environment(\.analytics) private var analytics
    var body: some View {
        Button("Subscribe") {
            analytics.track(AnalyticsEvent(name: "subscribe_tapped"))
        }
    }
}
```

Views get only `EventTracking` (`track`); identifying the user (`UserIdentification`) stays in the Composition Root.

## Writing a provider

A provider adapts AnalyticsKit calls to one SDK. Keep it in your app target:

```swift
import AnalyticsKit
import AmplitudeSwift

struct AmplitudeAnalyticsProvider: AnalyticsProvider {
    let id = ProviderID.amplitude
    private let amplitude: Amplitude

    init(apiKey: String) {
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))
    }

    func track(_ event: AnalyticsEvent) {
        amplitude.track(eventType: event.name, eventProperties: event.parameters.foundationValues)
    }
    func setUserID(_ id: HashedUserID) { amplitude.setUserId(userId: id.value) }
    func setUserProperties(_ properties: AnalyticsParameters) {
        let identify = Identify()
        properties.forEach { identify.set(property: $0.key, value: $0.value.foundationValue) }
        amplitude.identify(identify: identify)
    }
    func reset() { amplitude.reset() }
}
```

Adding another analytics system = one more provider (with its `ProviderID`) in the `CompositeAnalytics` list. Nothing in the kit or at call sites changes.

## User ID

- `HashedUserID` can only be created by an `IdentifierHasher`, so a raw ID can never reach analytics by mistake.
- `AnonymousUserIDProvider` generates a random ID on first launch (a lowercase UUID, the same form as in the Android library) and keeps it in a `UserIDStore`.
- `KeychainUserIDStore` survives app reinstalls, is available after first unlock, and does not sync via iCloud. Keychain failures are reported to `onError` and never crash the app.
- When your app gets accounts, replace the provider with one that hashes the backend ID — calling code stays the same.

## Concurrency

Every public type is `Sendable` and nonisolated, so analytics can be called from any actor — UI, StoreKit transaction listeners, background tasks. If an SDK must be called on the main thread, its provider hops there itself.

## API

| Type | Purpose |
|---|---|
| `AnalyticsService` | `EventTracking & RevenueTracking & UserIdentification` — what the app uses |
| `AnalyticsProvider` | What an SDK adapter implements (with its `id`) |
| `RevenueTracking` | `trackPurchase` — adopted by providers whose SDK records revenue |
| `CompositeAnalytics` | Forwards calls to providers, in order, honouring `destinations` |
| `NoOpAnalytics` | Does nothing (tests, previews) |
| `AnalyticsEvent` | `name` + `parameters` + `destinations` |
| `Purchase` | Store-agnostic purchase: product, transaction, price, currency, quantity |
| `AnalyticsValue`, `AnalyticsParameters` | Typed, `Sendable` values |
| `ProviderID`, `Destinations` | Which providers receive an event or purchase |
| `HashedUserID`, `IdentifierHasher`, `SHA256IdentifierHasher` | Safe user IDs |
| `UserIDProvider`, `AnonymousUserIDProvider` | Where the user ID comes from |
| `UserIDStore`, `KeychainUserIDStore` | Where the raw ID is persisted |

## Running tests

```bash
swift test
```

## License

MIT — see [LICENSE](LICENSE).
