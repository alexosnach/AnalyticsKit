//
//  Destinations.swift
//  AnalyticsKit
//

import Foundation

/// Which providers receive an event.
///
/// An ID of a provider that isn't plugged in is simply never matched: the
/// event goes nowhere for it and nothing fails, so providers can be added or
/// removed in the Composition Root without touching any call site.
public enum Destinations: Sendable, Hashable {
    /// Every plugged-in provider.
    case all
    /// Only these providers.
    case only(Set<ProviderID>)
    /// Every plugged-in provider except these.
    case except(Set<ProviderID>)

    /// Whether the provider with this ID receives the event.
    public func includes(_ id: ProviderID) -> Bool {
        switch self {
        case .all: true
        case .only(let ids): ids.contains(id)
        case .except(let ids): !ids.contains(id)
        }
    }
}
