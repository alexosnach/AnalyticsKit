//
//  AnalyticsKitTests.swift
//  AppFoundation
//

import Foundation
import SwiftUI
import Testing
@testable import AnalyticsKit

@Suite("AnalyticsEvent")
struct AnalyticsEventTests {
    @Test func hasNoParametersByDefault() {
        let event = AnalyticsEvent(name: "app_opened")

        #expect(event.name == "app_opened")
        #expect(event.parameters.isEmpty)
    }

    @Test func keepsTheGivenParameters() {
        let event = AnalyticsEvent(name: "paywall_shown", parameters: ["source": "onboarding"])

        #expect(event.parameters["source"] == .string("onboarding"))
    }
}

@Suite("AnalyticsValue")
struct AnalyticsValueTests {
    @Test func literalsBecomeTheMatchingCase() {
        let parameters: AnalyticsParameters = ["s": "text", "i": 2, "d": 1.5, "b": true]

        #expect(parameters == ["s": .string("text"), "i": .int(2), "d": .double(1.5), "b": .bool(true)])
    }

    @Test func foundationValueIsThePlainSwiftValue() {
        #expect(AnalyticsValue.string("text").foundationValue as? String == "text")
        #expect(AnalyticsValue.int(2).foundationValue as? Int == 2)
        #expect(AnalyticsValue.double(1.5).foundationValue as? Double == 1.5)
        #expect(AnalyticsValue.bool(true).foundationValue as? Bool == true)
    }

    @Test func foundationValuesKeepsEveryKey() {
        let plain = (["source": "paywall", "step": 3] as AnalyticsParameters).foundationValues

        #expect(plain.count == 2)
        #expect(plain["source"] as? String == "paywall")
        #expect(plain["step"] as? Int == 3)
    }
}

@Suite("CompositeAnalytics")
struct CompositeAnalyticsTests {
    private let hasher = SHA256IdentifierHasher()

    @Test func sendsEveryCallToEveryProviderInOrder() {
        let first = SpyAnalyticsProvider()
        let second = SpyAnalyticsProvider()
        let analytics = CompositeAnalytics(providers: [first, second])
        let id = hasher.hash("user")

        analytics.track(AnalyticsEvent(name: "app_opened", parameters: ["n": 1]))
        analytics.setUserID(id)
        analytics.setUserProperties(["is_premium": true])
        analytics.reset()

        let expected: [ProviderCall] = [
            .track(AnalyticsEvent(name: "app_opened", parameters: ["n": 1])),
            .setUserID(id.value),
            .setUserProperties(["is_premium": true]),
            .reset,
        ]
        #expect(first.calls == expected)
        #expect(second.calls == expected)
    }

    @Test func canBeCalledFromAnyThread() async {
        let spy = SpyAnalyticsProvider()
        let analytics: AnalyticsService = CompositeAnalytics(providers: [spy])

        await Task.detached {
            analytics.track(AnalyticsEvent(name: "background_event"))
        }.value

        #expect(spy.calls == [.track(AnalyticsEvent(name: "background_event"))])
    }

    @Test func worksWithNoProviders() {
        let analytics = CompositeAnalytics(providers: [])

        analytics.track(AnalyticsEvent(name: "app_opened"))
        analytics.reset()
    }

    @Test func eachProviderGetsTheSameUnchangedEvent() {
        let spies = (0..<3).map { _ in SpyAnalyticsProvider() }
        let analytics = CompositeAnalytics(providers: spies)

        analytics.track(AnalyticsEvent(name: "purchase", parameters: ["price": 9.99]))

        for spy in spies {
            #expect(spy.calls == [.track(AnalyticsEvent(name: "purchase", parameters: ["price": 9.99]))])
        }
    }
}

@Suite("SHA256IdentifierHasher")
struct SHA256IdentifierHasherTests {
    private let hasher = SHA256IdentifierHasher()

    @Test func matchesTheKnownSHA256OfABC() {
        #expect(hasher.hash("abc").value == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func isLowercaseHexOf64Characters() {
        let value = hasher.hash("8FC10609-B5A6-4C45-A2A0-8B340468E611").value

        #expect(value.count == 64)
        #expect(value.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test func sameInputGivesSameHash() {
        #expect(hasher.hash("user") == hasher.hash("user"))
    }

    @Test func differentInputsGiveDifferentHashes() {
        #expect(hasher.hash("user-1") != hasher.hash("user-2"))
    }

    @Test func neverReturnsTheRawID() {
        #expect(hasher.hash("raw-id").value != "raw-id")
    }
}

@Suite("AnonymousUserIDProvider")
struct AnonymousUserIDProviderTests {
    private let hasher = SHA256IdentifierHasher()

    @Test func createsAndSavesAnIDOnFirstLaunch() throws {
        let store = InMemoryUserIDStore()
        let provider = AnonymousUserIDProvider(store: store, hasher: hasher)

        let id = provider.currentUserID()

        let saved = try #require(store.saved)
        #expect(UUID(uuidString: saved) != nil)
        #expect(id == hasher.hash(saved))
    }

    /// The same form on every platform: `8fc10609-b5a6-4c45-a2a0-8b340468e611`.
    @Test func savesTheIDAsALowercaseUUID() throws {
        let store = InMemoryUserIDStore()

        _ = AnonymousUserIDProvider(store: store, hasher: hasher).currentUserID()

        let saved = try #require(store.saved)
        #expect(UUID(uuidString: saved) != nil)
        #expect(saved == saved.lowercased())
        #expect(saved.count == 36)
    }

    @Test func reusesTheSavedID() {
        let store = InMemoryUserIDStore(saved: "existing-id")
        let provider = AnonymousUserIDProvider(store: store, hasher: hasher)

        #expect(provider.currentUserID() == hasher.hash("existing-id"))
        #expect(store.saveCount == 0)
    }

    @Test func givesTheSameIDOnEveryCall() {
        let store = InMemoryUserIDStore()
        let provider = AnonymousUserIDProvider(store: store, hasher: hasher)

        let first = provider.currentUserID()
        let second = provider.currentUserID()

        #expect(first == second)
        #expect(store.saveCount == 1)
    }

    @Test func stillGivesAnIDWhenSavingFails() {
        let store = InMemoryUserIDStore(keepsSaves: false)
        let provider = AnonymousUserIDProvider(store: store, hasher: hasher)

        let id = provider.currentUserID()

        #expect(id.value.count == 64)
        #expect(store.saveCount == 1)
    }

    @Test func sendsOnlyTheHashNotTheRawID() {
        let store = InMemoryUserIDStore(saved: "raw-id")
        let provider = AnonymousUserIDProvider(store: store, hasher: hasher)

        #expect(provider.currentUserID().value != "raw-id")
    }
}

/// Uses the real Keychain, under a service of its own that each test removes.
@Suite("KeychainUserIDStore", .serialized)
struct KeychainUserIDStoreTests {
    @Test func hasNoIDBeforeTheFirstSave() {
        let failures = Locked<[KeychainUserIDStore.Failure]>([])
        let store = KeychainUserIDStore(
            service: "tests.analyticskit.\(UUID().uuidString)",
            account: "user_id",
            onError: { failure in failures.withValue { $0.append(failure) } }
        )

        #expect(store.load() == nil)
        #expect(failures.current.isEmpty, "A missing ID is not a failure")
    }

    @Test func loadsWhatWasSaved() {
        let service = "tests.analyticskit.\(UUID().uuidString)"
        let store = KeychainUserIDStore(service: service, account: "user_id")
        defer { deleteItem(service: service) }

        store.save("first-id")

        #expect(store.load() == "first-id")
    }

    @Test func replacesASavedID() {
        let service = "tests.analyticskit.\(UUID().uuidString)"
        let store = KeychainUserIDStore(service: service, account: "user_id")
        defer { deleteItem(service: service) }

        store.save("first-id")
        store.save("second-id")

        #expect(store.load() == "second-id")
    }

    @Test func anotherStoreWithTheSameServiceSeesTheID() {
        let service = "tests.analyticskit.\(UUID().uuidString)"
        defer { deleteItem(service: service) }

        KeychainUserIDStore(service: service, account: "user_id").save("shared-id")

        #expect(KeychainUserIDStore(service: service, account: "user_id").load() == "shared-id")
    }

    private func deleteItem(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@Suite("KeychainUserIDStore.Failure")
struct KeychainFailureTests {
    @Test func keepsTheStatus() {
        #expect(KeychainUserIDStore.Failure.read(-25300).status == -25300)
        #expect(KeychainUserIDStore.Failure.update(-25299).status == -25299)
        #expect(KeychainUserIDStore.Failure.add(-25308).status == -25308)
    }

    @Test func describesTheOperationAndTheSystemMessage() {
        let description = KeychainUserIDStore.Failure.add(errSecInteractionNotAllowed).description

        #expect(description.hasPrefix("Keychain add failed: -25308 ("))
        #expect(description != "Keychain add failed: -25308 (unknown error)")
    }
}

@Suite("NoOpAnalytics")
struct NoOpAnalyticsTests {
    @Test func acceptsEveryCall() {
        let analytics: AnalyticsService = NoOpAnalytics()

        analytics.track(AnalyticsEvent(name: "app_opened"))
        analytics.setUserID(SHA256IdentifierHasher().hash("user"))
        analytics.setUserProperties(["is_premium": true])
        analytics.reset()
    }

    @Test func isTheEnvironmentDefault() {
        #expect(EnvironmentValues().analytics is NoOpAnalytics)
    }
}
