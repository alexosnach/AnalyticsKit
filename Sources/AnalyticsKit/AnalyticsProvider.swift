//
//  AnalyticsProvider.swift
//  AnalyticsKit
//

import Foundation

/// One analytics system plugged into the app: Amplitude, Firebase, the console.
///
/// Only the composite analytics calls it; the rest of the app uses
/// ``AnalyticsService``. The two protocols have the same methods today, but
/// they serve different callers, so each can grow without touching the other.
///
/// An implementation adapts these calls to its SDK: names, value types and
/// limits of the SDK stay inside that one file.
public protocol AnalyticsProvider: Sendable {
    /// Matched against an event's ``Destinations``; declare it next to the adapter.
    var id: ProviderID { get }

    func track(_ event: AnalyticsEvent)
    func setUserID(_ id: HashedUserID)
    func setUserProperties(_ properties: AnalyticsParameters)
    func reset()
}
