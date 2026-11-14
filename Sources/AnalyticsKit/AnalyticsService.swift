//
//  AnalyticsService.swift
//  AnalyticsKit
//

import Foundation

/// Everything the app's Composition Root can do with analytics.
public typealias AnalyticsService = EventTracking & RevenueTracking & UserIdentification

public protocol EventTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

/// Records revenue.
///
/// The app calls it on the service; a provider adopts it only when its SDK
/// records revenue. Providers that don't simply never see purchases.
public protocol RevenueTracking: Sendable {
    func trackPurchase(_ purchase: Purchase)
}

public protocol UserIdentification: Sendable {
    func setUserID(_ id: HashedUserID)
    func setUserProperties(_ properties: AnalyticsParameters)
    func reset()
}
