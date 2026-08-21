//
//  RadioStationTests.swift
//  FrequenziaTests
//

import Foundation
import Testing
@testable import Frequenzia

@Suite("RadioStation")
struct RadioStationTests {
    private func makeStation(
        favicon: String? = nil,
        country: String? = nil,
        tags: String? = nil,
        urlResolved: String = "https://example.com/stream"
    ) -> RadioStation {
        RadioStation(
            stationuuid: "uuid-1",
            name: "Test Station",
            url_resolved: urlResolved,
            favicon: favicon,
            countrycode: "DE",
            country: country,
            tags: tags,
            codec: "MP3",
            bitrate: 128
        )
    }

    @Test("tagList splits, trims and drops empty entries")
    func tagListParsing() {
        let station = makeStation(tags: " pop, Top 40 ,,eclectic ")
        #expect(station.tagList == ["pop", "Top 40", "eclectic"])
    }

    @Test("tagList is empty for nil or empty tags")
    func tagListEmpty() {
        #expect(makeStation(tags: nil).tagList == [])
        #expect(makeStation(tags: "").tagList == [])
    }

    @Test("subtitle combines country and only the first tag")
    func subtitleFirstTagOnly() {
        let station = makeStation(country: "Germany", tags: "pop,top 40,eclectic")
        #expect(station.subtitle == "Germany · pop")
    }

    @Test("subtitle falls back gracefully when fields are missing")
    func subtitleMissingFields() {
        #expect(makeStation(country: nil, tags: "pop").subtitle == "pop")
        #expect(makeStation(country: "Germany", tags: nil).subtitle == "Germany")
        #expect(makeStation(country: nil, tags: nil).subtitle == "")
        #expect(makeStation(country: "", tags: "").subtitle == "")
    }

    @Test("detailSubtitle joins all tags, subtitle keeps only the first")
    func detailSubtitleAllTags() {
        let station = makeStation(country: "United States", tags: "pop,top 40,eclectic")
        #expect(station.detailSubtitle == "United States · pop,top 40,eclectic")
        #expect(station.subtitle == "United States · pop")
    }

    @Test("faviconURL is nil for missing or empty favicon")
    func faviconURLNilCases() {
        #expect(makeStation(favicon: nil).faviconURL == nil)
        #expect(makeStation(favicon: "").faviconURL == nil)
    }

    @Test("faviconURL parses a valid URL string")
    func faviconURLValid() {
        let station = makeStation(favicon: "https://example.com/icon.png")
        #expect(station.faviconURL?.absoluteString == "https://example.com/icon.png")
    }

    @Test("streamURL parses the resolved stream URL")
    func streamURLValid() {
        let station = makeStation(urlResolved: "https://stream.example.com/live.mp3")
        #expect(station.streamURL?.absoluteString == "https://stream.example.com/live.mp3")
    }

    @Test("id mirrors stationuuid for List/ForEach identity")
    func idMirrorsStationUUID() {
        let station = makeStation()
        #expect(station.id == station.stationuuid)
    }

    @Test("RadioStation decodes from Radio Browser API JSON")
    func decodesFromJSON() throws {
        let json = """
        {
            "stationuuid": "abc-123",
            "name": "Radio Test",
            "url_resolved": "https://stream.example.com/live",
            "favicon": "https://example.com/fav.png",
            "countrycode": "DE",
            "country": "Germany",
            "tags": "pop,rock",
            "codec": "MP3",
            "bitrate": 128
        }
        """
        let data = try #require(json.data(using: .utf8))
        let station = try JSONDecoder().decode(RadioStation.self, from: data)
        #expect(station.stationuuid == "abc-123")
        #expect(station.name == "Radio Test")
        #expect(station.tagList == ["pop", "rock"])
    }

    @Test("RadioStation decodes even when optional fields are missing")
    func decodesWithMissingOptionalFields() throws {
        let json = """
        {
            "stationuuid": "abc-123",
            "name": "Radio Test",
            "url_resolved": "https://stream.example.com/live"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let station = try JSONDecoder().decode(RadioStation.self, from: data)
        #expect(station.favicon == nil)
        #expect(station.tags == nil)
        #expect(station.subtitle == "")
    }
}
