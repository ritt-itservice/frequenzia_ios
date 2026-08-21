//
//  HistoryEntry.swift
//  Frequenzia
//
//  Ein Eintrag pro tatsächlich abgespieltem Sender. Bei erneutem Abspielen
//  wird playedAt aktualisiert statt einen neuen Eintrag anzulegen, damit
//  "Zuletzt gehört" nicht mit Duplikaten vollläuft.
//

import Foundation
import SwiftData

@Model
final class HistoryEntry {
    @Attribute(.unique) var stationuuid: String
    var name: String
    var urlResolved: String
    var favicon: String?
    var countrycode: String?
    var country: String?
    var tags: String?
    var codec: String?
    var bitrate: Int?
    var playedAt: Date

    init(station: RadioStation, playedAt: Date = .now) {
        self.stationuuid = station.stationuuid
        self.name = station.name
        self.urlResolved = station.url_resolved
        self.favicon = station.favicon
        self.countrycode = station.countrycode
        self.country = station.country
        self.tags = station.tags
        self.codec = station.codec
        self.bitrate = station.bitrate
        self.playedAt = playedAt
    }

    var asStation: RadioStation {
        RadioStation(
            stationuuid: stationuuid,
            name: name,
            url_resolved: urlResolved,
            favicon: favicon,
            countrycode: countrycode,
            country: country,
            tags: tags,
            codec: codec,
            bitrate: bitrate
        )
    }
}
