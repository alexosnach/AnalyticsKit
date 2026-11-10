//
//  TestDoubles.swift
//  AppFoundation
//

import Foundation
@testable import AnalyticsKit

/// One call a provider received, in a form tests can compare.
enum ProviderCall: Equatable {
    case track(name: String, parameters: NSDictionary)
    case setUserID(String)
    case setUserProperties(NSDictionary)
    case reset
}

/// Records every call, in order.
final class SpyAnalyticsProvider: AnalyticsProvider {
    private(set) var calls: [ProviderCall] = []

    func track(_ event: AnalyticsEvent) {
        calls.append(.track(name: event.name, parameters: event.parameters as NSDictionary))
    }

    func setUserID(_ id: HashedUserID) {
        calls.append(.setUserID(id.value))
    }

    func setUserProperties(_ properties: [String: Any]) {
        calls.append(.setUserProperties(properties as NSDictionary))
    }

    func reset() {
        calls.append(.reset)
    }
}

/// Keeps the ID in memory; can be told to forget every save.
final class InMemoryUserIDStore: UserIDStore {
    private(set) var saved: String?
    private(set) var saveCount = 0
    private let keepsSaves: Bool

    /// - Parameter keepsSaves: `false` acts like a Keychain that fails to write.
    init(saved: String? = nil, keepsSaves: Bool = true) {
        self.saved = saved
        self.keepsSaves = keepsSaves
    }

    func load() -> String? {
        saved
    }

    func save(_ id: String) {
        saveCount += 1
        if keepsSaves {
            saved = id
        }
    }
}
