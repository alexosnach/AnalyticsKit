//
//  Purchase.swift
//  AnalyticsKit
//

import Foundation

/// A completed purchase, as revenue analytics records it.
///
/// Independent of any store SDK: the app converts its own transaction type
/// (StoreKit, a web checkout, …) into a `Purchase` at its boundary.
public struct Purchase: Sendable, Equatable {
    /// The store's product identifier, e.g. `"premium_yearly"`.
    public let productID: String
    /// The store's unique ID of this transaction; lets providers drop duplicates.
    public let transactionID: String
    /// Price of one unit.
    public let price: Decimal
    /// ISO 4217 currency code, e.g. `"USD"`.
    public let currency: String
    /// Units bought; 1 for subscriptions.
    public let quantity: Int
    /// Extra values for providers that accept them, e.g. `["is_trial": true]`.
    public let parameters: AnalyticsParameters
    /// Which revenue-tracking providers receive it; every one by default.
    public let destinations: Destinations

    /// Create it from a verified store transaction. Don't create one for a
    /// free trial with no charge: report that as an event.
    ///
    /// - Parameters:
    ///   - price: Price of one unit, as `Decimal` so cents aren't rounded.
    ///   - currency: ISO 4217 code of `price`, e.g. `"USD"`.
    ///   - quantity: Units bought; 1 by default.
    ///   - parameters: Extra values; none by default.
    ///   - destinations: Which revenue providers receive it; every one by default.
    public init(
        productID: String,
        transactionID: String,
        price: Decimal,
        currency: String,
        quantity: Int = 1,
        parameters: AnalyticsParameters = [:],
        destinations: Destinations = .all
    ) {
        self.productID = productID
        self.transactionID = transactionID
        self.price = price
        self.currency = currency
        self.quantity = quantity
        self.parameters = parameters
        self.destinations = destinations
    }

    /// `price × quantity`.
    public var revenue: Decimal {
        price * Decimal(quantity)
    }
}
