# AnalyticsKit

A provider-agnostic analytics layer for Swift apps: one `AnalyticsService` that fans out to any number of analytics SDKs, plus a hashed, persistent user ID.

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
    private let amplitude: Amplitude

    init(apiKey: String) {
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))
    }

    func track(_ event: AnalyticsEvent) {
        amplitude.track(eventType: event.name, eventProperties: event.parameters)
    }
    func setUserID(_ id: HashedUserID) { amplitude.setUserId(userId: id.value) }
    func setUserProperties(_ properties: [String: Any]) {
        let identify = Identify()
        properties.forEach { identify.set(property: $0.key, value: $0.value) }
        amplitude.identify(identify: identify)
    }
    func reset() { amplitude.reset() }
}
```

Adding another analytics system = adding one more provider to the `CompositeAnalytics` list. Nothing else changes.

## User ID

- `HashedUserID` can only be created by an `IdentifierHasher`, so a raw ID can never reach analytics by mistake.
- `AnonymousUserIDProvider` generates a random ID on first launch and keeps it in a `UserIDStore`.
- `KeychainUserIDStore` survives app reinstalls, is available after first unlock, and does not sync via iCloud. Keychain failures are reported to `onError` and never crash the app.
- When your app gets accounts, replace the provider with one that hashes the backend ID — calling code stays the same.

## Concurrency

AnalyticsKit is compiled with `MainActor` default isolation (it's called from UI).

## API

| Type | Purpose |
|---|---|
| `AnalyticsService` | `EventTracking & UserIdentification` — what the app uses |
| `AnalyticsProvider` | What an SDK adapter implements |
| `CompositeAnalytics` | Forwards every call to all providers, in order |
| `NoOpAnalytics` | Does nothing (tests, previews) |
| `AnalyticsEvent` | `name` + `parameters` |
| `HashedUserID`, `IdentifierHasher`, `SHA256IdentifierHasher` | Safe user IDs |
| `UserIDProvider`, `AnonymousUserIDProvider` | Where the user ID comes from |
| `UserIDStore`, `KeychainUserIDStore` | Where the raw ID is persisted |

## Running tests

```bash
swift test
```

## License

MIT — see [LICENSE](LICENSE).
