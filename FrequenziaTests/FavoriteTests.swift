//
//  FavoriteTests.swift
//  FrequenziaTests
//

import Testing
@testable import Frequenzia

@Suite("Favorite")
struct FavoriteTests {
    private func makeStation(name: String) -> RadioStation {
        RadioStation(
            stationuuid: "uuid-\(name)",
            name: name,
            url_resolved: "https://example.com/stream",
            favicon: "https://example.com/icon.png",
            countrycode: "DE",
            country: "Germany",
            tags: "pop,rock",
            codec: "MP3",
            bitrate: 128
        )
    }

    @Test("sectionKey uppercases a normal leading letter")
    func sectionKeyNormalLetter() {
        let favorite = Favorite(station: makeStation(name: "radio paradise"))
        #expect(favorite.sectionKey == "R")
    }

    @Test("sectionKey ignores leading whitespace")
    func sectionKeyLeadingWhitespace() {
        let favorite = Favorite(station: makeStation(name: "  mango radio"))
        #expect(favorite.sectionKey == "M")
    }

    @Test("sectionKey falls back to # for a leading digit")
    func sectionKeyLeadingDigit() {
        let favorite = Favorite(station: makeStation(name: "1live"))
        #expect(favorite.sectionKey == "#")
    }

    @Test("sectionKey falls back to # for a leading symbol")
    func sectionKeyLeadingSymbol() {
        let favorite = Favorite(station: makeStation(name: "!Radio"))
        #expect(favorite.sectionKey == "#")
    }

    @Test("sectionKey falls back to # for an empty name")
    func sectionKeyEmptyName() {
        let favorite = Favorite(station: makeStation(name: ""))
        #expect(favorite.sectionKey == "#")
    }

    @Test("sectionKey treats an accented leading letter as a letter, not #")
    func sectionKeyAccentedLetter() {
        let favorite = Favorite(station: makeStation(name: "Éclectic FM"))
        #expect(favorite.sectionKey == "É")
    }

    @Test("init copies all station fields")
    func initCopiesFields() {
        let station = makeStation(name: "KIIS FM")
        let favorite = Favorite(station: station)
        #expect(favorite.stationuuid == station.stationuuid)
        #expect(favorite.name == station.name)
        #expect(favorite.urlResolved == station.url_resolved)
        #expect(favorite.favicon == station.favicon)
        #expect(favorite.country == station.country)
        #expect(favorite.tags == station.tags)
        #expect(favorite.codec == station.codec)
        #expect(favorite.bitrate == station.bitrate)
    }

    @Test("asStation round-trips back to an equivalent RadioStation")
    func asStationRoundTrip() {
        let station = makeStation(name: "KIIS FM")
        let favorite = Favorite(station: station)
        #expect(favorite.asStation == station)
    }
}
