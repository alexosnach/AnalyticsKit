//
//  AnalyticsValue.swift
//  AnalyticsKit
//

import Foundation

/// One value an event or a user property carries.
///
/// Analytics SDKs accept only a handful of scalar types; this enum lists
/// exactly those, so a value an SDK can't serialise never compiles, and every
/// value can cross threads (`Sendable`).
///
/// Literals work directly: `["source": "onboarding", "step": 2, "trial": true]`.
public enum AnalyticsValue: Sendable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    /// The plain Swift value (`String`, `Int`, `Double` or `Bool`), for
    /// SDKs whose APIs take `Any`. Use it inside providers only.
    public var foundationValue: any Sendable {
        switch self {
        case .string(let value): value
        case .int(let value): value
        case .double(let value): value
        case .bool(let value): value
        }
    }
}

/// Parameters of an event, or a set of user properties.
public typealias AnalyticsParameters = [String: AnalyticsValue]

extension Dictionary where Key == String, Value == AnalyticsValue {
    /// The same dictionary with plain Swift values, for SDKs whose APIs take `[String: Any]`.
    public var foundationValues: [String: any Sendable] {
        mapValues(\.foundationValue)
    }
}

extension AnalyticsValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension AnalyticsValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension AnalyticsValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension AnalyticsValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}
