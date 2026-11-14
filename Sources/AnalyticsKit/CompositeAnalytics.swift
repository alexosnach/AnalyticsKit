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

    /// - Parameter providers: Providers that also adopt ``RevenueTracking`` receive purchases.
    public init(providers: [AnalyticsProvider]) {
        self.providers = providers
        self.revenueProviders = providers.compactMap(RevenueProvider.init)
    }

    public func track(_ event: AnalyticsEvent) {
        for provider in providers where event.destinations.includes(provider.id) {
            provider.track(event)
        }
    }

    public func trackPurchase(_ purchase: Purchase) {
        for provider in revenueProviders where purchase.destinations.includes(provider.id) {
            provider.tracker.trackPurchase(purchase)
        }
    }

    public func setUserID(_ id: HashedUserID) {
        for provider in providers {
            provider.setUserID(id)
        }
    }

    public func setUserProperties(_ properties: AnalyticsParameters) {
        for provider in providers {
            provider.setUserProperties(properties)
        }
    }

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
