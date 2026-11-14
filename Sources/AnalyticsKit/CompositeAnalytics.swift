//
//  CompositeAnalytics.swift
//  AnalyticsKit
//

import Foundation

/// The analytics the whole app uses: one ``AnalyticsService`` that forwards
/// calls to its providers, in their order.
///
/// An event goes only to the providers its ``AnalyticsEvent/destinations``
/// include. User identification goes to every provider, so the user is the
/// same person in each analytics system.
///
/// A new analytics system is a new provider in the list the Composition Root
/// builds; this type and the code that calls it do not change.
///
/// ```swift
/// let analytics: AnalyticsService = CompositeAnalytics(providers: [
///     AmplitudeAnalyticsProvider(apiKey: "…"),
///     MyConsoleProvider(),
/// ])
/// ```
public struct CompositeAnalytics: AnalyticsService {
    private let providers: [AnalyticsProvider]
    private let revenueProviders: [RevenueProvider]
    private let screenProviders: [ScreenProvider]

    /// Builds the service from the providers the app plugs in.
    ///
    /// Create one instance in the Composition Root and inject it everywhere.
    /// Leave a provider out (for example in debug builds or before consent)
    /// and events routed to it are simply dropped.
    ///
    /// - Parameter providers: Called in this order. Providers that also adopt
    ///   ``RevenueTracking`` receive purchases; the rest only receive events.
    ///   Providers that adopt ``ScreenTracking`` receive screens through it;
    ///   the rest receive them as ``ScreenView/fallbackEvent``.
    public init(providers: [AnalyticsProvider]) {
        self.providers = providers
        self.revenueProviders = providers.compactMap(RevenueProvider.init)
        self.screenProviders = providers.map(ScreenProvider.init)
    }

    /// Forwards the event to every provider its destinations include, in order.
    public func track(_ event: AnalyticsEvent) {
        for provider in providers where event.destinations.includes(provider.id) {
            provider.track(event)
        }
    }

    /// Forwards the screen to every provider its destinations include: through
    /// the provider's own screen API, or as ``ScreenView/fallbackEvent``.
    public func trackScreen(_ screen: ScreenView) {
        for provider in screenProviders where screen.destinations.includes(provider.id) {
            provider.track(screen)
        }
    }

    /// Forwards the purchase to every revenue-tracking provider its destinations include.
    public func trackPurchase(_ purchase: Purchase) {
        for provider in revenueProviders where purchase.destinations.includes(provider.id) {
            provider.tracker.trackPurchase(purchase)
        }
    }

    /// Forwards the ID to every provider.
    public func setUserID(_ id: HashedUserID) {
        for provider in providers {
            provider.setUserID(id)
        }
    }

    /// Forwards the properties to every provider.
    public func setUserProperties(_ properties: AnalyticsParameters) {
        for provider in providers {
            provider.setUserProperties(properties)
        }
    }

    /// Resets every provider.
    public func reset() {
        for provider in providers {
            provider.reset()
        }
    }
}

/// A provider that records revenue, found once when the composite is built.
private struct RevenueProvider: Sendable {
    let id: ProviderID
    let tracker: RevenueTracking

    init?(_ provider: AnalyticsProvider) {
        guard let tracker = provider as? RevenueTracking else { return nil }
        self.id = provider.id
        self.tracker = tracker
    }
}

/// How one provider receives screens, decided once when the composite is built.
private struct ScreenProvider: Sendable {
    let id: ProviderID
    private let provider: AnalyticsProvider

    init(_ provider: AnalyticsProvider) {
        self.id = provider.id
        self.provider = provider
    }

    func track(_ screen: ScreenView) {
        if let tracker = provider as? ScreenTracking {
            tracker.trackScreen(screen)
        } else {
            provider.track(screen.fallbackEvent)
        }
    }
}
