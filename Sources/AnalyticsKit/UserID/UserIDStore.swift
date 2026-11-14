//
//  UserIDStore.swift
//  AnalyticsKit
//

import Foundation

/// Keeps the app's raw user ID between launches.
///
/// Used by ``AnonymousUserIDProvider``. ``KeychainUserIDStore`` is the
/// production choice; adopt this protocol for another storage or for tests.
public protocol UserIDStore: Sendable {
    /// The saved ID, or `nil` when none was saved yet.
    func load() -> String?
    /// Saves the ID, replacing any earlier one. Must not throw or crash:
    /// a failed save only means the next launch makes a new ID.
    func save(_ id: String)
}
