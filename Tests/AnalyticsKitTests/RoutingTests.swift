//
//  RoutingTests.swift
//  AnalyticsKitTests
//

import Testing
@testable import AnalyticsKit

private extension ProviderID {
    static let amplitude = ProviderID("amplitude")
    static let appsFlyer = ProviderID("appsflyer")
    static let firebase = ProviderID("firebase")
    static let notPluggedIn = ProviderID("not_plugged_in")
}

@Suite("Destinations")
struct DestinationsTests {
    @Test func allIncludesEveryProvider() {
        #expect(Destinations.all.includes(.amplitude))
        #expect(Destinations.all.includes(.notPluggedIn))
    }

    @Test func onlyIncludesJustTheListedProviders() {
        let destinations = Destinations.only([.appsFlyer])

        #expect(destinations.includes(.appsFlyer))
        #expect(!destinations.includes(.amplitude))
    }

    @Test func exceptIncludesEveryProviderButTheListed() {
        let destinations = Destinations.except([.appsFlyer])

        #expect(!destinations.includes(.appsFlyer))
        #expect(destinations.includes(.amplitude))
    }

    @Test func emptyOnlyIncludesNoProvider() {
        #expect(!Destinations.only([]).includes(.amplitude))
    }
}

@Suite("CompositeAnalytics routing")
struct CompositeRoutingTests {
    private let amplitude = SpyAnalyticsProvider(id: .amplitude)
    private let appsFlyer = SpyAnalyticsProvider(id: .appsFlyer)
    private let firebase = SpyAnalyticsProvider(id: .firebase)

    private var analytics: CompositeAnalytics {
        CompositeAnalytics(providers: [amplitude, appsFlyer, firebase])
    }

    @Test func eventsGoEverywhereByDefault() {
        let event = AnalyticsEvent(name: "app_opened")

        analytics.track(event)

        for spy in [amplitude, appsFlyer, firebase] {
            #expect(spy.calls == [.track(event)])
        }
    }

    @Test func onlyReachesJustTheListedProviders() {
        let event = AnalyticsEvent(name: "af_complete_registration", destinations: .only([.appsFlyer]))

        analytics.track(event)

        #expect(appsFlyer.calls == [.track(event)])
        #expect(amplitude.calls.isEmpty)
        #expect(firebase.calls.isEmpty)
    }

    @Test func exceptSkipsTheListedProviders() {
        let event = AnalyticsEvent(name: "screen_view", destinations: .except([.appsFlyer]))

        analytics.track(event)

        #expect(amplitude.calls == [.track(event)])
        #expect(firebase.calls == [.track(event)])
        #expect(appsFlyer.calls.isEmpty)
    }

    @Test func aProviderThatIsNotPluggedInIsSilentlyIgnored() {
        let event = AnalyticsEvent(name: "x", destinations: .only([.notPluggedIn]))

        analytics.track(event)

        for spy in [amplitude, appsFlyer, firebase] {
            #expect(spy.calls.isEmpty)
        }
    }

    @Test func routingKeepsTheOrderOfEvents() {
        let first = AnalyticsEvent(name: "first", destinations: .only([.amplitude]))
        let second = AnalyticsEvent(name: "second", destinations: .only([.appsFlyer]))
        let third = AnalyticsEvent(name: "third")

        [first, second, third].forEach(analytics.track)

        #expect(amplitude.calls == [.track(first), .track(third)])
        #expect(appsFlyer.calls == [.track(second), .track(third)])
    }

    @Test func userIdentificationIsNeverFiltered() {
        let id = SHA256IdentifierHasher().hash("user")

        analytics.setUserID(id)
        analytics.setUserProperties(["plan": "premium"])
        analytics.reset()

        let expected: [ProviderCall] = [.setUserID(id.value), .setUserProperties(["plan": "premium"]), .reset]
        for spy in [amplitude, appsFlyer, firebase] {
            #expect(spy.calls == expected)
        }
    }
}
