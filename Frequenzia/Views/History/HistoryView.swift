//
//  HistoryView.swift
//  Frequenzia
//
//  Zeigt nur tatsächlich abgespielte Sender. "Verlauf leeren" fragt vorher
//  über einen Bestätigungsdialog nach.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryEntry.playedAt, order: .reverse) private var history: [HistoryEntry]
    @Query private var favorites: [Favorite]
    @State private var showClearConfirmation = false
    let player: PlayerViewModel

    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.stationuuid))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(history) { entry in
                    StationRow(
                        station: entry.asStation,
                        isFavorite: favoriteIDs.contains(entry.stationuuid),
                        isCurrent: player.currentStation?.stationuuid == entry.stationuuid,
                        isPlaying: player.isPlaying,
                        onSelect: { player.preview(entry.asStation) },
                        onPlay: { play(entry.asStation) },
                        onToggleFavorite: { toggleFavorite(entry.asStation) }
                    )
                }
            }
            .listStyle(.plain)
            .navigationTitle("Zuletzt gehört")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(history.isEmpty)
                }
            }
            .overlay {
                if history.isEmpty {
                    ContentUnavailableView(
                        "Noch nichts gehört",
                        systemImage: "clock",
                        description: Text("Abgespielte Sender erscheinen hier.")
                    )
                }
            }
            .confirmationDialog(
                "Verlauf leeren?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Leeren", role: .destructive, action: clearHistory)
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der gesamte Wiedergabeverlauf wird endgültig gelöscht. Das kann nicht rückgängig gemacht werden.")
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

    private func toggleFavorite(_ station: RadioStation) {
        if let existing = favorites.first(where: { $0.stationuuid == station.stationuuid }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(Favorite(station: station))
        }
    }

    private func clearHistory() {
        for entry in history {
            modelContext.delete(entry)
        }
    }
}
