//
//  IdentifierHasher.swift
//  AnalyticsKit
//

import CryptoKit
import Foundation

/// A user ID that has been hashed and is safe to send to analytics.
///
/// Only a hasher in this file can create it: its `init` is `fileprivate`,
/// so a raw ID can never be passed where a `HashedUserID` is expected.
public struct HashedUserID: Sendable, Hashable {
    public let value: String

    fileprivate init(value: String) {
        self.value = value
    }
}

/// Turns a raw identifier into the one analytics receives.
///
/// Use it directly when the app already has a user ID, e.g. from its backend
/// after sign-in: `analytics.setUserID(hasher.hash(user.id))`.
public protocol IdentifierHasher: Sendable {
    /// The hashed form of `identifier`; the same input always gives the same result.
    func hash(_ identifier: String) -> HashedUserID
}

/// SHA-256 as a lowercase hex string of 64 characters.
///
/// The same algorithm and format as the Android and Flutter libraries, so one
/// user gets the same ID on every platform.
public struct SHA256IdentifierHasher: IdentifierHasher {
    public init() {}

    /// SHA-256 of the identifier's UTF-8 bytes, as lowercase hex.
    public func hash(_ identifier: String) -> HashedUserID {
        let digest = SHA256.hash(data: Data(identifier.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return HashedUserID(value: hex)
    }
}
