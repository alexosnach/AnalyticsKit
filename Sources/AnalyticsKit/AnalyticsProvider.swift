//
//  AnalyticsProvider.swift
//  AnalyticsKit
//

import Foundation

/// One analytics system plugged into the app: Amplitude, Firebase, the console.
///
/// Only ``CompositeAnalytics`` calls it; the rest of the app uses
/// ``AnalyticsService``. The two have similar methods today, but they serve
/// different callers, so each can grow without touching the other.
///
/// An implementation adapts these calls to its SDK: names, value types and
/// limits of the SDK stay inside that one file. Keep adapters in the app (or
/// a module of their own), not in this package.
///
/// To add an analytics system:
/// 1. Declare its ID: `extension ProviderID { static let mixpanel = ProviderID("mixpanel") }`.
/// 2. Write a type that adopts `AnalyticsProvider`; add ``RevenueTracking``
///    if its SDK records revenue, ``ScreenTracking`` if it has a screen API
///    (otherwise screens arrive in ``track(_:)`` as `screen_view` events).
/// 3. Add it to the `CompositeAnalytics` list in the Composition Root.
///
/// Nothing else changes. Methods are called from any thread; if the SDK
/// requires the main thread, hop there inside the method.
public protocol AnalyticsProvider: Sendable {
    /// Which ``Destinations`` this provider matches. Declare it as a static
    /// ``ProviderID`` next to the adapter and return it here; it must be
    /// unique among the providers of one composite.
    var id: ProviderID { get }

    /// Sends the event to the SDK. Called only for events whose destinations
    /// include ``id``. Map ``AnalyticsEvent/parameters`` with
    /// `foundationValues` if the SDK takes `[String: Any]`.
    func track(_ event: AnalyticsEvent)

    /// Sets the SDK's user ID. `id.value` is the hash, never the raw ID.
    func setUserID(_ id: HashedUserID)

    /// Sets the SDK's user properties, or does nothing if it has none.
    func setUserProperties(_ properties: AnalyticsParameters)

    /// Clears the SDK's user ID and properties, or does nothing if it can't.
    func reset()
}
