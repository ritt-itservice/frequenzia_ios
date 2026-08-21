//
//  StationListCacheTests.swift
//  FrequenziaTests
//
//  Nutzt eine eigene UserDefaults-Suite pro Test, damit nichts in den
//  echten App-Defaults landet und Tests sich nicht gegenseitig stören.
//

import Foundation
import Testing
@testable import Frequenzia

@Suite("StationListCache")
struct StationListCacheTests {
    private func makeStations() -> [RadioStation] {
        [
            RadioStation(
                stationuuid: "uuid-1",
                name: "KIIS FM",
                url_resolved: "https://example.com/1",
                favicon: nil,
                countrycode: "US",
                country: "United States",
                tags: "pop",
                codec: "MP3",
                bitrate: 128
            ),
            RadioStation(
                stationuuid: "uuid-2",
                name: "BBC World Service",
                url_resolved: "https://example.com/2",
                favicon: "https://example.com/icon.png",
                countrycode: "GB",
                country: "United Kingdom",
                tags: "news",
                codec: "AAC",
                bitrate: 96
            ),
        ]
    }

    private func makeIsolatedDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("load returns nil when nothing was saved yet")
    func loadReturnsNilInitially() {
        let defaults = makeIsolatedDefaults(suiteName: "cache-test-empty")
        let cache = StationListCache(defaults: defaults)
        #expect(cache.load() == nil)
    }

    @Test("save then load round-trips the exact station list")
    func saveThenLoadRoundTrips() {
        let defaults = makeIsolatedDefaults(suiteName: "cache-test-roundtrip")
        let cache = StationListCache(defaults: defaults)
        let stations = makeStations()

        cache.save(stations)

        #expect(cache.load() == stations)
    }

    @Test("save overwrites a previously cached list")
    func saveOverwritesPreviousList() {
        let defaults = makeIsolatedDefaults(suiteName: "cache-test-overwrite")
        let cache = StationListCache(defaults: defaults)

        cache.save(makeStations())
        cache.save([])

        #expect(cache.load() == [])
    }
}
