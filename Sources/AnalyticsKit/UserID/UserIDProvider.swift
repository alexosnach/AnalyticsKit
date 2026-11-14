//
//  UserIDProvider.swift
//  AnalyticsKit
//

import Foundation

/// Gives the user ID analytics sends, already hashed.
///
/// Today the ID is anonymous, made on the device. When the app gets accounts,
/// a provider that hashes the backend's ID replaces this one in the
/// Composition Root; the code that sends the ID does not change.
public protocol UserIDProvider: Sendable {
    func currentUserID() -> HashedUserID
}

/// A random ID made on first launch and kept in the store from then on.
///
/// It identifies this app on this device: a new install keeps it (Keychain),
/// another device of the same person gets its own.
public struct AnonymousUserIDProvider: UserIDProvider {
    private let store: UserIDStore
    private let hasher: IdentifierHasher

    public init(store: UserIDStore, hasher: IdentifierHasher) {
        self.store = store
        self.hasher = hasher
    }

    public func currentUserID() -> HashedUserID {
        hasher.hash(rawID())
    }

    /// The saved ID, or a new one saved now. If saving fails, the new ID still
    /// serves this launch and the next launch makes another.
    private func rawID() -> String {
        if let saved = store.load() {
            return saved
        }
        // Always lowercase, the same form on every platform.
        let new = UUID().uuidString.lowercased()
        store.save(new)
        return new
    }
}
