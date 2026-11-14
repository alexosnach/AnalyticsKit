//
//  AnalyticsEvent.swift
//  AnalyticsKit
//

import Foundation

/// Something that happened in the app: a name, typed parameters and the
/// providers it goes to.
public struct AnalyticsEvent: Sendable, Equatable {
    /// Event name as providers show it. Use `snake_case`, at most 40 characters
    /// (the strictest common SDK limit), and keep it stable: dashboards and
    /// funnels are built on it.
    public let name: String
    /// Details of this occurrence, e.g. `["source": "onboarding"]`. No personal data.
    public let parameters: AnalyticsParameters
    /// Which providers receive the event.
    public let destinations: Destinations

    /// - Parameters:
    ///   - name: Stable `snake_case` event name.
    ///   - parameters: Details of this occurrence; none by default.
    ///   - destinations: Which providers receive the event; every one by default.
    ///     Narrow it for provider-specific events, e.g. AppsFlyer's `af_*`
    ///     events: `.only([.appsFlyer])`.
    public init(
        name: String,
        parameters: AnalyticsParameters = [:],
        destinations: Destinations = .all
    ) {
        self.name = name
        self.parameters = parameters
        self.destinations = destinations
    }
}
