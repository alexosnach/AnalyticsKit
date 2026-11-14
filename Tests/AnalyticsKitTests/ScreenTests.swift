//
//  ScreenTests.swift
//  AnalyticsKitTests
//

import Testing
@testable import AnalyticsKit

private extension ProviderID {
    static let firebase = ProviderID("firebase")
    static let amplitude = ProviderID("amplitude")
    static let uxCam = ProviderID("uxcam")
}

@Suite("ScreenView")
struct ScreenViewTests {
    @Test func defaultsToNoClassNoParametersEveryProvider() {
        let screen = ScreenView(name: "home")

        #expect(screen.screenClass == nil)
        #expect(screen.parameters.isEmpty)
        #expect(screen.destinations == .all)
    }

    @Test func fallbackEventCarriesNameClassAndParameters() {
        let screen = ScreenView(
            name: "paywall",
            screenClass: "PaywallView",
            parameters: ["source": "settings"],
            destinations: .only([.amplitude])
        )

        #expect(screen.fallbackEvent == AnalyticsEvent(
            name: "screen_view",
            parameters: ["screen_name": "paywall", "screen_class": "PaywallView", "source": "settings"],
            destinations: .only([.amplitude])
        ))
    }

    @Test func fallbackEventOmitsAMissingClass() {
        #expect(ScreenView(name: "home").fallbackEvent.parameters == ["screen_name": "home"])
    }

    @Test func screenNameWinsOverAParameterWithTheSameKey() {
        let screen = ScreenView(name: "home", parameters: ["screen_name": "other"])

        #expect(screen.fallbackEvent.parameters["screen_name"] == "home")
    }
}

@Suite("CompositeAnalytics screens")
struct CompositeScreenTests {
    private let firebase = SpyScreenProvider(id: .firebase)
    private let amplitude = SpyAnalyticsProvider(id: .amplitude)
    private let uxCam = SpyScreenProvider(id: .uxCam)

    private var analytics: CompositeAnalytics {
        CompositeAnalytics(providers: [firebase, amplitude, uxCam])
    }

    @Test func providersWithAScreenAPIUseIt() {
        let screen = ScreenView(name: "home", screenClass: "HomeView")

        analytics.trackScreen(screen)

        #expect(firebase.trackedScreens == [screen])
        #expect(uxCam.trackedScreens == [screen])
    }

    @Test func providersWithAScreenAPIDontAlsoGetTheFallbackEvent() {
        analytics.trackScreen(ScreenView(name: "home"))

        #expect(firebase.calls.isEmpty)
        #expect(uxCam.calls.isEmpty)
    }

    @Test func providersWithoutAScreenAPIGetTheFallbackEvent() {
        let screen = ScreenView(name: "home", screenClass: "HomeView")

        analytics.trackScreen(screen)

        #expect(amplitude.calls == [.track(screen.fallbackEvent)])
    }

    @Test func screensFollowTheirDestinations() {
        let screen = ScreenView(name: "home", destinations: .only([.amplitude]))

        analytics.trackScreen(screen)

        #expect(amplitude.calls == [.track(screen.fallbackEvent)])
        #expect(firebase.trackedScreens.isEmpty)
        #expect(uxCam.trackedScreens.isEmpty)
    }

    @Test func exceptSkipsAProviderWithAScreenAPI() {
        let screen = ScreenView(name: "home", destinations: .except([.uxCam]))

        analytics.trackScreen(screen)

        #expect(firebase.trackedScreens == [screen])
        #expect(uxCam.trackedScreens.isEmpty)
        #expect(amplitude.calls.count == 1)
    }

    @Test func canBeTrackedFromAnyThread() async {
        let analytics: AnalyticsService = self.analytics
        let screen = ScreenView(name: "home")

        await Task.detached {
            analytics.trackScreen(screen)
        }.value

        #expect(firebase.trackedScreens == [screen])
    }
}
