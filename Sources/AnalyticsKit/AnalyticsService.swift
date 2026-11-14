//
//  AnalyticsService.swift
//  AnalyticsKit
//

import Foundation

/// Everything the app can do with analytics, as one dependency.
///
/// Build it once in the Composition Root (usually a ``CompositeAnalytics``)
/// and inject it. Give each caller only the role it needs: a view or view
/// model that reports events depends on ``EventTracking`` (and
/// ``ScreenTracking`` if it reports screens), the purchase flow
/// on ``RevenueTracking``, sign-in/sign-out code on ``UserIdentification``.
public typealias AnalyticsService = EventTracking & ScreenTracking & RevenueTracking & UserIdentification

/// Reports what happens in the app.
public protocol EventTracking: Sendable {
    /// Sends one event to the providers its ``AnalyticsEvent/destinations`` include.
    ///
    /// Call it at the moment the thing happened — a screen shown, a button
    /// tapped, a step finished. Safe from any thread; returns immediately
    /// and never throws: delivery is the SDKs' job.
    ///
    /// ```swift
    /// analytics.track(AnalyticsEvent(name: "paywall_shown", parameters: ["source": "onboarding"]))
    /// ```
    func track(_ event: AnalyticsEvent)
}

/// Reports which screens the user opens.
///
/// The app calls it on the service. A provider adopts it only when its SDK
/// has its own screen API (Firebase's `screen_view`, UXCam's screen tags);
/// every other provider receives ``ScreenView/fallbackEvent`` through
/// ``EventTracking/track(_:)``, so no provider misses a screen.
public protocol ScreenTracking: Sendable {
    /// Records that the user opened a screen.
    ///
    /// Call it once each time the screen becomes visible — from SwiftUI's
    /// `onAppear` or the view model's appear handler — including when the
    /// user comes back to it. Don't call it for sheets or alerts that aren't
    /// screens in your funnels, and don't send a separate event for the same
    /// visit.
    ///
    /// ```swift
    /// analytics.trackScreen(ScreenView(name: "paywall", screenClass: "PaywallView"))
    /// ```
    func trackScreen(_ screen: ScreenView)
}

/// Records revenue.
///
/// The app calls it on the service; a provider adopts it only when its SDK
/// records revenue. Providers that don't simply never see purchases.
public protocol RevenueTracking: Sendable {
    /// Records one completed purchase as revenue.
    ///
    /// Call it once per transaction, after the store has verified it — for
    /// StoreKit, from the `Transaction.updates` listener and after
    /// `purchase()` returns a verified transaction, before `finish()`.
    /// Don't call it for restores or renewals the store re-delivers, or
    /// revenue is counted twice. Don't also send a separate "purchase" event
    /// for the same revenue: providers record it from this call.
    func trackPurchase(_ purchase: Purchase)
}

/// Says who the user is, so every provider attributes events to the same person.
///
/// Calls go to every provider, regardless of any destinations.
public protocol UserIdentification: Sendable {
    /// Ties the events that follow to this user.
    ///
    /// Call it at launch with the ID you already have (anonymous or signed-in)
    /// and again right after sign-in. The ID must be hashed: create it with an
    /// ``IdentifierHasher`` or get it from a ``UserIDProvider``.
    func setUserID(_ id: HashedUserID)

    /// Sets attributes of the user that providers attach to all later events,
    /// such as a plan or a cohort. Keys not passed keep their earlier values.
    ///
    /// Call it when an attribute changes, not before every event. Never put
    /// personal data (email, name, health data) in properties.
    func setUserProperties(_ properties: AnalyticsParameters)

    /// Forgets the current user: their ID and properties.
    ///
    /// Call it on sign-out or account deletion, so the next person's events
    /// aren't attributed to them. Then call ``setUserID(_:)`` with the new ID.
    func reset()
}
