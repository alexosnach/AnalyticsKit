//
//  KeychainUserIDStore.swift
//  AnalyticsKit
//

import Foundation
import Security

/// Stores the user ID in the Keychain, so it survives reinstalls of the app,
/// unlike `UserDefaults`.
///
/// The item is readable after the first unlock (so background work can use
/// it) and moves to a new device with an encrypted backup. It does not sync
/// through iCloud: each device keeps its own ID until the user signs in.
///
/// A Keychain failure does not stop the app: the ID still serves this launch.
/// The store reports it to `onError`, so the app can log it with its own logger
/// or send it to crash reporting:
///
/// ```swift
/// KeychainUserIDStore(onError: { Log.error("\($0)", category: "analytics") })
/// ```
public struct KeychainUserIDStore: UserIDStore {
    private let service: String
    private let account: String
    private let onError: (Failure) -> Void

    public init(
        service: String = Bundle.main.bundleIdentifier ?? "app",
        account: String = "analytics.user_id",
        onError: @escaping (Failure) -> Void = { _ in }
    ) {
        self.service = service
        self.account = account
        self.onError = onError
    }

    public func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                onError(.read(status))
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func save(_ id: String) {
        let data = Data(id.utf8)

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        guard updateStatus == errSecItemNotFound else {
            if updateStatus != errSecSuccess {
                onError(.update(updateStatus))
            }
            return
        }

        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus != errSecSuccess {
            onError(.add(addStatus))
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

extension KeychainUserIDStore {
    /// A Keychain call that failed, with the status it returned.
    /// The store keeps working after it: the ID serves this launch.
    public enum Failure: Error, Equatable, CustomStringConvertible {
        /// Reading the saved ID failed (a missing ID is not a failure).
        case read(OSStatus)
        /// Replacing the saved ID failed.
        case update(OSStatus)
        /// Saving the first ID failed.
        case add(OSStatus)

        public var status: OSStatus {
            switch self {
            case .read(let status), .update(let status), .add(let status): status
            }
        }

        /// For example: `Keychain add failed: -25308 (User interaction is not allowed.)`.
        public var description: String {
            let operation = switch self {
            case .read: "read"
            case .update: "update"
            case .add: "add"
            }
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown error"
            return "Keychain \(operation) failed: \(status) (\(message))"
        }
    }
}
