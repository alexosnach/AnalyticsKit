//
//  EventTracking+Environment.swift
//  AnalyticsKit
//
//  Created by alex on 10/11/2026.
//

import SwiftUI

extension EnvironmentValues {
    @Entry public var analytics: EventTracking = NoOpAnalytics()
}
