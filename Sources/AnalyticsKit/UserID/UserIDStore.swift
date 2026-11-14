//
//  UserIDStore.swift
//  AnalyticsKit
//

import Foundation

/// Keeps the app's raw user ID between launches.
public protocol UserIDStore: Sendable {
    /// The saved ID, or `nil` when none was saved yet.
    func load() -> String?
    func save(_ id: String)
}
