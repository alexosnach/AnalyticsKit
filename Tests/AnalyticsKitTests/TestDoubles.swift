//
//  TestDoubles.swift
//  AnalyticsKitTests
//

import Foundation
@testable import AnalyticsKit

/// One call a provider received, in a form tests can compare.
enum ProviderCall: Equatable {
    case track(AnalyticsEvent)
    case setUserID(String)
    case setUserProperties(AnalyticsParameters)
    case reset
}

/// Thread-safe box for test doubles that are called from any thread.
final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) { self.value = value }

    func withValue<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }

    var current: Value { withValue { $0 } }
}

/// Records every call, in order.
final class SpyAnalyticsProvider: AnalyticsProvider {
    private let recorded = Locked<[ProviderCall]>([])

    var calls: [ProviderCall] { recorded.current }

    func track(_ event: AnalyticsEvent) { record(.track(event)) }
    func setUserID(_ id: HashedUserID) { record(.setUserID(id.value)) }
    func setUserProperties(_ properties: AnalyticsParameters) { record(.setUserProperties(properties)) }
    func reset() { record(.reset) }

    private func record(_ call: ProviderCall) {
        recorded.withValue { $0.append(call) }
    }
}

/// Keeps the ID in memory; can be told to forget every save.
final class InMemoryUserIDStore: UserIDStore {
    private struct State {
        var saved: String?
        var saveCount = 0
    }

    private let state: Locked<State>
    private let keepsSaves: Bool

    var saved: String? { state.current.saved }
    var saveCount: Int { state.current.saveCount }

    /// - Parameter keepsSaves: `false` acts like a Keychain that fails to write.
    init(saved: String? = nil, keepsSaves: Bool = true) {
        self.state = Locked(State(saved: saved))
        self.keepsSaves = keepsSaves
    }

    func load() -> String? { saved }

    func save(_ id: String) {
        state.withValue {
            $0.saveCount += 1
            if keepsSaves { $0.saved = id }
        }
    }
}
