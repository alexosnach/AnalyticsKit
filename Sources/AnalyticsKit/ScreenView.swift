//
//  ScreenView.swift
//  AnalyticsKit
//

import Foundation

/// The user has opened a screen.
///
/// SDKs' automatic screen tracking sees UIKit/SwiftUI hosting classes, not the
/// screens the product team talks about, so the app reports them itself.
public struct ScreenView: Sendable, Equatable {
    /// Event name used for providers that have no screen API of their own.
    public static let fallbackEventName = "screen_view"
    /// Fallback parameter key for ``name``; the same key Firebase uses.
    public static let nameParameter = "screen_name"
    /// Fallback parameter key for ``screenClass``; the same key Firebase uses.
    public static let classParameter = "screen_class"

    /// Stable `snake_case` screen name, e.g. `"paywall"`. Funnels are built on it.
    public let name: String
    /// The type that shows the screen, e.g. `"PaywallView"`; optional.
    public let screenClass: String?
    /// Details of this visit, e.g. `["source": "settings"]`. No personal data.
    public let parameters: AnalyticsParameters
    /// Which providers receive it.
    public let destinations: Destinations

    /// - Parameters:
    ///   - name: Stable `snake_case` screen name.
    ///   - screenClass: The type that shows the screen; none by default.
    ///   - parameters: Details of this visit; none by default.
    ///   - destinations: Which providers receive it; every one by default.
    public init(
        name: String,
        screenClass: String? = nil,
        parameters: AnalyticsParameters = [:],
        destinations: Destinations = .all
    ) {
        self.name = name
        self.screenClass = screenClass
        self.parameters = parameters
        self.destinations = destinations
    }

    /// The screen as a plain event, for providers without a screen API:
    /// `screen_view` with `screen_name`, `screen_class` (if set) and ``parameters``.
    /// The screen's own keys win over parameters with the same names.
    public var fallbackEvent: AnalyticsEvent {
        var all = parameters
        all[Self.nameParameter] = .string(name)
        if let screenClass {
            all[Self.classParameter] = .string(screenClass)
        }
        return AnalyticsEvent(name: Self.fallbackEventName, parameters: all, destinations: destinations)
    }
}
