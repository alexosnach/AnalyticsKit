//
//  AnalyticsEvent.swift
//  AnalyticsKit
//
//  Created by alex on 10/11/2026.
//

import Foundation

public struct AnalyticsEvent {
    public let name: String
    public let parameters: [String: Any]
    
    public init(name: String, parameters: [String : Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
