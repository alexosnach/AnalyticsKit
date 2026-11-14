//
//  AnalyticsService.swift
//  AnalyticsKit
//
//  Created by alex on 10/11/2026.
//

import Foundation

public typealias AnalyticsService = EventTracking & UserIdentification

public protocol EventTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

public protocol UserIdentification: Sendable {
    func setUserID(_ id: HashedUserID)
    func setUserProperties(_ properties: AnalyticsParameters)
    func reset()
}
