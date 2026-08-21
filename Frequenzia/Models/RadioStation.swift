//
//  RadioStation.swift
//  Frequenzia
//
//  Antwortmodell der Radio Browser API, siehe API_REFERENCE.md.
//

import Foundation

struct RadioStation: Codable, Identifiable, Sendable, Hashable {
    var id: String { stationuuid }

    let stationuuid: String
    let name: String
    let url_resolved: String
    let favicon: String?
    let countrycode: String?
    let country: String?
    let tags: String?
    let codec: String?
    let bitrate: Int?

    var faviconURL: URL? {
        guard let favicon, !favicon.isEmpty else { return nil }
        return URL(string: favicon)
    }

    var streamURL: URL? {
        URL(string: url_resolved)
    }

    /// Kommagetrennte Tags als lesbare Liste, z. B. "Pop, Top 40".
    var tagList: [String] {
        guard let tags, !tags.isEmpty else { return [] }
        return tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// "Land · Genre" für Senderzeilen, robust gegenüber fehlenden Feldern.
    var subtitle: String {
        var parts: [String] = []
        if let country, !country.isEmpty { parts.append(country) }
        if let firstTag = tagList.first { parts.append(firstTag) }
        return parts.joined(separator: " · ")
    }
}
