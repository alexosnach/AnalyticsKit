//
//  AnalyticsEvent.swift
//  AnalyticsKit
//

import Foundation

/// Something that happened in the app: a name, typed parameters and the
/// providers it goes to.
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: AnalyticsParameters
    public let destinations: Destinations

    /// - Parameter destinations: Which providers receive the event; every one by default.
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
