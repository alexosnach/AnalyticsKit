//
//  ProviderID.swift
//  AnalyticsKit
//

import Foundation

/// Names one analytics provider, so events can be routed to it.
///
/// The kit ships no list of providers: each provider declares its own ID next
/// to its adapter, so adding a provider never touches this package.
///
/// ```swift
/// extension ProviderID {
///     static let amplitude = ProviderID("amplitude")
/// }
/// ```
public struct ProviderID: Sendable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}
