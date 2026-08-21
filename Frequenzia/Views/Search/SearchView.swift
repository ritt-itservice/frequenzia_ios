//
//  SearchView.swift
//  Frequenzia
//
//  Startbildschirm: Sendersuche (Name, Land oder Genre/Tag) mit
//  Live-Ergebnissen; ohne Suchbegriff "Beliebte Sender".
//

import SwiftData
import SwiftUI

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [Favorite]

    @State private var viewModel = StationListViewModel()
    let player: PlayerViewModel

    private var favoriteIDs: Set<String> {
        Set(favorites.map(\.stationuuid))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Sender")
                .searchable(text: $viewModel.searchText, prompt: "Name, Land oder Genre")
                .background(Color("AppBackground").ignoresSafeArea())
        }
        .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.stations.isEmpty, viewModel.loadState == .loading {
            ProgressView("Lade Sender…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.stations.isEmpty, case .error(let message) = viewModel.loadState {
            ContentUnavailableView(
                "Keine Sender gefunden",
                systemImage: "dot.radiowaves.left.and.right",
                description: Text(message)
            )
        } else {
            List {
                if case .error(let message) = viewModel.loadState {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color("AppBackground"))
                }

                ForEach(viewModel.stations) { station in
                    StationRow(
                        station: station,
                        isFavorite: favoriteIDs.contains(station.stationuuid),
                        isCurrent: player.currentStation?.stationuuid == station.stationuuid,
                        isPlaying: player.isPlaying,
                        onSelect: { player.preview(station) },
                        onPlay: { play(station) },
                        onToggleFavorite: { toggleFavorite(station) }
                    )
                    .listRowBackground(Color("AppBackground"))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
}
