//
//  NoOpAnalytics.swift
//  AnalyticsKit
//

import Foundation

/// Analytics that ignores every call.
///
/// Use it in SwiftUI previews, tests that don't check analytics, and builds
/// that must send nothing (e.g. debug). It is the default of the
/// `\.analytics` environment value.
public struct NoOpAnalytics: AnalyticsService {
    public init() {}

    /// Does nothing.
    public func track(_ event: AnalyticsEvent) {}

    /// Does nothing.
    public func trackScreen(_ screen: ScreenView) {}

    /// Does nothing.
    public func trackPurchase(_ purchase: Purchase) {}

    /// Does nothing.
    public func setUserID(_ id: HashedUserID) {}

    /// Does nothing.
    public func setUserProperties(_ properties: AnalyticsParameters) {}

    /// Does nothing.
    public func reset() {}
}
