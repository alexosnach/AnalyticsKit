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
public struct HashedUserID: Equatable {
    public let value: String

    fileprivate init(value: String) {
        self.value = value
    }
}

/// Turns a raw identifier into the one analytics receives.
public protocol IdentifierHasher {
    func hash(_ identifier: String) -> HashedUserID
}

/// SHA-256 as a lowercase hex string of 64 characters.
public struct SHA256IdentifierHasher: IdentifierHasher {
    public init() {}

    public func hash(_ identifier: String) -> HashedUserID {
        let digest = SHA256.hash(data: Data(identifier.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return HashedUserID(value: hex)
    }
}
