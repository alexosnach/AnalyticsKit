//
//  EventTracking+Environment.swift
//  AnalyticsKit
//

import SwiftUI

extension EnvironmentValues {
    /// Event and screen tracking for views.
    ///
    /// Set it once at the root: `.environment(\.analytics, analytics)`, then
    /// read it with `@Environment(\.analytics)`. Views get only
    /// ``EventTracking`` and ``ScreenTracking``: identifying the user and
    /// revenue stay out of the UI.
    /// Defaults to ``NoOpAnalytics``, so previews send nothing.
    @Entry public var analytics: any EventTracking & ScreenTracking = NoOpAnalytics()
}
