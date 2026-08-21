//
//  Favorite.swift
//  Frequenzia
//

import Foundation
import SwiftData

@Model
final class Favorite {
    @Attribute(.unique) var stationuuid: String
    var name: String
    var urlResolved: String
    var favicon: String?
    var countrycode: String?
    var country: String?
    var tags: String?
    var codec: String?
    var bitrate: Int?
    var dateAdded: Date

    init(station: RadioStation, dateAdded: Date = .now) {
        self.stationuuid = station.stationuuid
        self.name = station.name
        self.urlResolved = station.url_resolved
        self.favicon = station.favicon
        self.countrycode = station.countrycode
        self.country = station.country
        self.tags = station.tags
        self.codec = station.codec
        self.bitrate = station.bitrate
        self.dateAdded = dateAdded
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

    /// Erster Buchstabe für die A–Z-Gruppierung; Nicht-Buchstaben landen im "#"-Abschnitt.
    var sectionKey: String {
        guard let first = name.trimmingCharacters(in: .whitespaces).uppercased().first,
              first.isLetter else {
            return "#"
        }
        return String(first)
    }
}
