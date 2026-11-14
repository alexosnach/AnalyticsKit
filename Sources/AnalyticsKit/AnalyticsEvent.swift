//
//  AnalyticsEvent.swift
//  AnalyticsKit
//

import Foundation

/// Something that happened in the app: a name and typed parameters.
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: AnalyticsParameters

    public init(name: String, parameters: AnalyticsParameters = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
