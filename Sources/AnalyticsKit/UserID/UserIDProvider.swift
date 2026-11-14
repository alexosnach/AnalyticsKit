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
    /// The hashed ID to pass to ``UserIdentification/setUserID(_:)``.
    /// Call it at launch; it returns the same ID every time.
    func currentUserID() -> HashedUserID
}

/// A random ID made on first launch and kept in the store from then on.
///
/// It identifies this app on this device: a new install keeps it (Keychain),
/// another device of the same person gets its own.
public struct AnonymousUserIDProvider: UserIDProvider {
    private let store: UserIDStore
    private let hasher: IdentifierHasher

    /// - Parameters:
    ///   - store: Where the raw ID lives; ``KeychainUserIDStore`` in production.
    ///   - hasher: How it is hashed; ``SHA256IdentifierHasher`` matches the other platforms.
    public init(store: UserIDStore, hasher: IdentifierHasher) {
        self.store = store
        self.hasher = hasher
    }

    /// The saved ID, hashed; on first launch a new lowercase UUID is made and saved.
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
