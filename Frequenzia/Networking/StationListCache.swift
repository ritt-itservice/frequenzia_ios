//
//  StationListCache.swift
//  Frequenzia
//
//  Zwischenspeicher für die zuletzt erfolgreich geladene "Beliebte Sender"-
//  Liste, damit bei einem API-Ausfall nicht einfach eine leere Liste
//  gezeigt wird (siehe CLAUDE.md, Offline-Fallback).
//

import Foundation

struct StationListCache: Sendable {
    private let key = "cached_top_stations_v1"
    // UserDefaults ist laut Apple-Doku thread-safe, aber (noch) nicht als
    // Sendable markiert.
    private nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ stations: [RadioStation]) {
        guard let data = try? JSONEncoder().encode(stations) else { return }
        defaults.set(data, forKey: key)
    }

    func load() -> [RadioStation]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([RadioStation].self, from: data)
    }
}
