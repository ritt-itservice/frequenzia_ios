//
//  FavoritesView.swift
//  Frequenzia
//
//  Lokal gespeicherte Favoriten mit Filter-Suche, alphabetischer Gruppierung
//  (Nicht-Buchstaben → "#") und Sticky-Section-Headern + A–Z-Leiste.
//

import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Favorite.name) private var allFavorites: [Favorite]
    @State private var searchText = ""
    let player: PlayerViewModel

    private var filtered: [Favorite] {
        guard !searchText.isEmpty else { return allFavorites }
        return allFavorites.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var sections: [(key: String, favorites: [Favorite])] {
        let grouped = Dictionary(grouping: filtered, by: \.sectionKey)
        return grouped.keys
            .sorted(by: sectionOrder)
            .map { key in
                let sorted = (grouped[key] ?? []).sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return (key: key, favorites: sorted)
            }
    }

    private var availableLetters: Set<String> {
        Set(sections.map(\.key))
    }

    private func sectionOrder(_ a: String, _ b: String) -> Bool {
        if a == "#" { return true }
        if b == "#" { return false }
        return a < b
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {
                        ForEach(sections, id: \.key) { section in
                            Section {
                                ForEach(section.favorites) { favorite in
                                    StationRow(
                                        station: favorite.asStation,
                                        isFavorite: true,
                                        isCurrent: player.currentStation?.stationuuid == favorite.stationuuid,
                                        isPlaying: player.isPlaying,
                                        onSelect: { player.preview(favorite.asStation) },
                                        onPlay: { play(favorite.asStation) },
                                        onToggleFavorite: { modelContext.delete(favorite) }
                                    )
                                    .listRowBackground(Color("AppBackground"))
                                }
                            } header: {
                                Text(section.key).id(section.key)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    if !allFavorites.isEmpty {
                        AlphabetIndexBar(availableLetters: availableLetters) { letter in
                            withAnimation {
                                proxy.scrollTo(letter, anchor: .top)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Favoriten durchsuchen")
            .background(Color("AppBackground").ignoresSafeArea())
            .overlay {
                if allFavorites.isEmpty {
                    ContentUnavailableView(
                        "Keine Favoriten",
                        systemImage: "star",
                        description: Text("Markiere Sender mit dem Stern, um sie hier zu sehen.")
                    )
                }
            }
        }
    }

    private func play(_ station: RadioStation) {
        if player.currentStation?.stationuuid == station.stationuuid {
            player.togglePlayPause()
        } else {
            player.play(station)
        }
    }
}
