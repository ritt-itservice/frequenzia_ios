//
//  RadioBrowserClient.swift
//  Frequenzia
//
//  Endpunkte der Radio Browser API, siehe API_REFERENCE.md.
//

import Foundation

enum RadioBrowserError: Error {
    case invalidURL
    case invalidResponse
    case decoding(Error)
}

struct RadioBrowserClient: Sendable {
    static let shared = RadioBrowserClient()

    private let session: URLSession
    private let resolver: RadioBrowserHostResolver

    init(session: URLSession = .shared, resolver: RadioBrowserHostResolver = .shared) {
        self.session = session
        self.resolver = resolver
    }

    /// Freitextsuche über den Sendernamen (Startbildschirm-Suchfeld).
    func search(query: String, limit: Int = 50) async throws -> [RadioStation] {
        try await performRequest(
            path: "/json/stations/search",
            queryItems: [
                URLQueryItem(name: "name", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "hidebroken", value: "true"),
                URLQueryItem(name: "order", value: "clickcount"),
                URLQueryItem(name: "reverse", value: "true"),
            ]
        )
    }

    /// "Beliebte Sender" ohne aktive Suchanfrage.
    func topClickStations(limit: Int = 50) async throws -> [RadioStation] {
        try await performRequest(path: "/json/stations/topclick/\(limit)", queryItems: [])
    }

    /// Klick-Tracking der Radio-Browser-Statistik; wird beim tatsächlichen
    /// Abspielen aufgerufen (nicht bei reiner Vorschau). Fehler hier sind
    /// bewusst folgenlos, da es sich nur um Statistik handelt.
    func registerClick(stationuuid: String) async {
        guard let url = try? await makeURL(path: "/json/url/\(stationuuid)", queryItems: [], excludeLastUsed: false) else {
            return
        }
        _ = try? await session.data(from: url)
    }

    private func performRequest(path: String, queryItems: [URLQueryItem], attempt: Int = 0) async throws -> [RadioStation] {
        let url = try await makeURL(path: path, queryItems: queryItems, excludeLastUsed: attempt > 0)

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw RadioBrowserError.invalidResponse
            }
            do {
                return try JSONDecoder().decode([RadioStation].self, from: data)
            } catch {
                throw RadioBrowserError.decoding(error)
            }
        } catch {
            if attempt == 0 {
                await resolver.invalidateCache()
                return try await performRequest(path: path, queryItems: queryItems, attempt: attempt + 1)
            }
            throw error
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem], excludeLastUsed: Bool) async throws -> URL {
        let host = await resolver.resolveHost(excludeLastUsed: excludeLastUsed)
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw RadioBrowserError.invalidURL }
        return url
    }
}
