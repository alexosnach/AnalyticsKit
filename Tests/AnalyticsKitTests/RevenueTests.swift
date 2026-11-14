//
//  RevenueTests.swift
//  AnalyticsKitTests
//

import Foundation
import Testing
@testable import AnalyticsKit

private extension ProviderID {
    static let amplitude = ProviderID("amplitude")
    static let appsFlyer = ProviderID("appsflyer")
    static let uxCam = ProviderID("uxcam")
}

private func makePurchase(destinations: Destinations = .all) -> Purchase {
    Purchase(
        productID: "premium_yearly",
        transactionID: "2000000123",
        price: Decimal(string: "39.99") ?? 0,
        currency: "USD",
        destinations: destinations
    )
}

@Suite("Purchase")
struct PurchaseTests {
    @Test func defaultsToOneUnitWithoutExtrasForEveryProvider() {
        let purchase = makePurchase()

        #expect(purchase.quantity == 1)
        #expect(purchase.parameters.isEmpty)
        #expect(purchase.destinations == .all)
    }

    @Test func revenueIsPriceTimesQuantity() {
        let purchase = Purchase(productID: "coins", transactionID: "t", price: 2.5, currency: "EUR", quantity: 3)

        #expect(purchase.revenue == 7.5)
    }

    @Test func keepsTheExactDecimalPrice() {
        #expect(makePurchase().price == Decimal(string: "39.99"))
    }
}

@Suite("CompositeAnalytics revenue")
struct CompositeRevenueTests {
    private let amplitude = SpyRevenueProvider(id: .amplitude)
    private let appsFlyer = SpyRevenueProvider(id: .appsFlyer)
    private let uxCam = SpyAnalyticsProvider(id: .uxCam)

    private var analytics: CompositeAnalytics {
        CompositeAnalytics(providers: [amplitude, uxCam, appsFlyer])
    }

    @Test func purchasesReachEveryRevenueProvider() {
        let purchase = makePurchase()

        analytics.trackPurchase(purchase)

        #expect(amplitude.trackedPurchases == [purchase])
        #expect(appsFlyer.trackedPurchases == [purchase])
    }

    @Test func aProviderWithoutRevenueNeverSeesPurchasesButStillGetsEvents() {
        let event = AnalyticsEvent(name: "paywall_shown")

        analytics.trackPurchase(makePurchase())
        analytics.track(event)

        #expect(uxCam.calls == [.track(event)])
    }

    @Test func purchasesFollowTheirDestinations() {
        let purchase = makePurchase(destinations: .only([.appsFlyer]))

        analytics.trackPurchase(purchase)

        #expect(appsFlyer.trackedPurchases == [purchase])
        #expect(amplitude.trackedPurchases.isEmpty)
    }

    @Test func aPurchaseIsNotAlsoSentAsAnEvent() {
        analytics.trackPurchase(makePurchase())

        #expect(amplitude.calls.isEmpty)
        #expect(appsFlyer.calls.isEmpty)
    }

    @Test func worksWithoutAnyRevenueProvider() {
        let uxCamOnly = CompositeAnalytics(providers: [uxCam])

        uxCamOnly.trackPurchase(makePurchase())

        #expect(uxCam.calls.isEmpty)
    }

    @Test func canBeTrackedFromAnyThread() async {
        let analytics: AnalyticsService = self.analytics
        let purchase = makePurchase()

        await Task.detached {
            analytics.trackPurchase(purchase)
        }.value

        #expect(amplitude.trackedPurchases == [purchase])
    }
}
