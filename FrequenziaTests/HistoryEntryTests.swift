//
//  HistoryEntryTests.swift
//  FrequenziaTests
//

import Foundation
import Testing
@testable import Frequenzia

@Suite("HistoryEntry")
struct HistoryEntryTests {
    private func makeStation(name: String = "KIIS FM") -> RadioStation {
        RadioStation(
            stationuuid: "uuid-\(name)",
            name: name,
            url_resolved: "https://example.com/stream",
            favicon: "https://example.com/icon.png",
            countrycode: "US",
            country: "The United States Of America",
            tags: "pop,top 40",
            codec: "MP3",
            bitrate: 128
        )
    }

    @Test("init copies all station fields")
    func initCopiesFields() {
        let station = makeStation()
        let entry = HistoryEntry(station: station)
        #expect(entry.stationuuid == station.stationuuid)
        #expect(entry.name == station.name)
        #expect(entry.urlResolved == station.url_resolved)
        #expect(entry.country == station.country)
        #expect(entry.tags == station.tags)
    }

    @Test("init defaults playedAt to roughly now")
    func initDefaultsPlayedAtToNow() {
        let entry = HistoryEntry(station: makeStation())
        #expect(abs(entry.playedAt.timeIntervalSinceNow) < 2)
    }

    @Test("explicit playedAt is preserved")
    func explicitPlayedAtPreserved() {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = HistoryEntry(station: makeStation(), playedAt: fixedDate)
        #expect(entry.playedAt == fixedDate)
    }

    @Test("asStation round-trips back to an equivalent RadioStation")
    func asStationRoundTrip() {
        let station = makeStation()
        let entry = HistoryEntry(station: station)
        #expect(entry.asStation == station)
    }
}
