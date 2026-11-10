//
//  NoOpAnalytics.swift
//  AnalyticsKit
//
//  Created by alex on 10/11/2026.
//

import Foundation

public struct NoOpAnalytics: AnalyticsService {
    public init() {}

    public func track(_ event: AnalyticsEvent) {}
    
    public func setUserID(_ id: HashedUserID) {}
    
    public func setUserProperties(_ properties: [String : Any]) {}
    
    public func reset() {}
}
