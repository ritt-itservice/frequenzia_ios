//
//  StationListViewModel.swift
//  Frequenzia
//
//  Speist den Sendersuche-Screen: Live-Suche während des Tippens (debounced),
//  ohne Suchbegriff "Beliebte Sender" (Top-Click-Charts).
//

import Foundation
import Observation

@MainActor
@Observable
final class StationListViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    var searchText: String = "" {
        didSet {
            guard oldValue != searchText else { return }
            scheduleLoad()
        }
    }

    private(set) var stations: [RadioStation] = []
    private(set) var loadState: LoadState = .idle

    private let client: RadioBrowserClient
    private let cache: StationListCache
    private var loadTask: Task<Void, Never>?
    private var didLoadInitially = false

    init(client: RadioBrowserClient = .shared, cache: StationListCache = StationListCache()) {
        self.client = client
        self.cache = cache
    }

    func onAppear() {
        guard !didLoadInitially else { return }
        didLoadInitially = true
        scheduleLoad(debounce: false)
    }

    private func scheduleLoad(debounce: Bool = true) {
        loadTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        loadTask = Task { [weak self] in
            if debounce && !query.isEmpty {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            guard !Task.isCancelled, let self else { return }
            if query.isEmpty {
                await self.loadTopStations()
            } else {
                await self.performSearch(query: query)
            }
        }
    }

    private func loadTopStations() async {
        loadState = .loading
        do {
            let result = try await client.topClickStations()
            guard !Task.isCancelled else { return }
            stations = result
            loadState = .loaded
            cache.save(result)
        } catch {
            guard !Task.isCancelled else { return }
            if let cached = cache.load(), !cached.isEmpty {
                stations = cached
                loadState = .error("Aktuelle Liste konnte nicht geladen werden – zeige zuletzt gespeicherte Sender.")
            } else {
                stations = []
                loadState = .error("Sender konnten gerade nicht geladen werden. Bitte später erneut versuchen.")
            }
        }
    }

    private func performSearch(query: String) async {
        loadState = .loading
        do {
            let result = try await client.search(query: query)
            guard !Task.isCancelled else { return }
            stations = result
            loadState = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            stations = []
            loadState = .error("Suche fehlgeschlagen. Bitte Verbindung prüfen.")
        }
    }
}
