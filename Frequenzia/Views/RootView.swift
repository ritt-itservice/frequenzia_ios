//
//  RootView.swift
//  Frequenzia
//
//  iPhone/compact: Bottom-Tab-Bar + Mini-Player + Vollbild-Overlay.
//  iPad/regular: Sidebar statt Tab-Bar (analog NavigationRail); ab
//  wideLayoutMinWidth zusätzlich ein dauerhaftes Player-Seitenpanel statt
//  Overlay – unterhalb dieser Schwelle (z. B. iPad Hochformat) bleibt es
//  beim Vollbild-Overlay, sonst quetscht ein festes Panel die Liste auf
//  einen unbrauchbaren Streifen zusammen (echter Android-Bug, siehe
//  CLAUDE.md).
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var favorites: [Favorite]

    @State private var player = PlayerViewModel()
    @State private var selectedTab: Tab = .search
    @State private var isPlayerPresented = false

    private let wideLayoutMinWidth: CGFloat = 900

    enum Tab: String, CaseIterable, Identifiable {
        case search, favorites, history, info
        var id: String { rawValue }

        var title: String {
            switch self {
            case .search: "Sender"
            case .favorites: "Favoriten"
            case .history: "Verlauf"
            case .info: "Info"
            }
        }

        var icon: String {
            switch self {
            case .search: "magnifyingglass"
            case .favorites: "star"
            case .history: "clock"
            case .info: "info.circle"
            }
        }
    }

    private var isFavorite: Bool {
        guard let station = player.currentStation else { return false }
        return favorites.contains { $0.stationuuid == station.stationuuid }
    }

    var body: some View {
        GeometryReader { proxy in
            let showSidePanel = horizontalSizeClass == .regular
                && proxy.size.width >= wideLayoutMinWidth
                && player.hasStation

            Group {
                if horizontalSizeClass == .regular {
                    regularLayout(showSidePanel: showSidePanel)
                } else {
                    compactLayout
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { isPlayerPresented && !showSidePanel },
                set: { isPlayerPresented = $0 }
            )) {
                playerSheet
            }
        }
        .onAppear(perform: setupPlayer)
    }

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            SearchView(player: player)
                .safeAreaInset(edge: .bottom) { miniPlayerInset }
                .tag(Tab.search)
                .tabItem { Label(Tab.search.title, systemImage: Tab.search.icon) }

            FavoritesView(player: player)
                .safeAreaInset(edge: .bottom) { miniPlayerInset }
                .tag(Tab.favorites)
                .tabItem { Label(Tab.favorites.title, systemImage: Tab.favorites.icon) }

            HistoryView(player: player)
                .safeAreaInset(edge: .bottom) { miniPlayerInset }
                .tag(Tab.history)
                .tabItem { Label(Tab.history.title, systemImage: Tab.history.icon) }

            InfoView()
                .safeAreaInset(edge: .bottom) { miniPlayerInset }
                .tag(Tab.info)
                .tabItem { Label(Tab.info.title, systemImage: Tab.info.icon) }
        }
    }

    // Wichtig: der Inset muss am Inhalt JEDES Tabs hängen, nicht an der
    // TabView selbst – sonst legt sich der Mini-Player unter die Tab-Bar
    // statt sauber darüber (echter Bug, siehe Nutzer-Feedback).
    @ViewBuilder
    private var miniPlayerInset: some View {
        if player.hasStation {
            MiniPlayerView(player: player, onTap: { isPlayerPresented = true })
        }
    }

    @ViewBuilder
    private func regularLayout(showSidePanel: Bool) -> some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            selectedContent
                .frame(maxWidth: .infinity)
                .safeAreaInset(edge: .bottom) {
                    if player.hasStation && !showSidePanel {
                        MiniPlayerView(player: player, onTap: { isPlayerPresented = true })
                            .padding(.horizontal, 8)
                    }
                }

            if showSidePanel {
                Divider()
                PlayerView(player: player, isFavorite: isFavorite, onToggleFavorite: toggleFavorite)
                    .frame(width: 380)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.title, systemImage: tab.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 220)
        .background(Color("AppBackground").ignoresSafeArea())
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .search: SearchView(player: player)
        case .favorites: FavoritesView(player: player)
        case .history: HistoryView(player: player)
        case .info: InfoView()
        }
    }

    private var playerSheet: some View {
        PlayerView(
            player: player,
            isFavorite: isFavorite,
            onToggleFavorite: toggleFavorite,
            onClose: { isPlayerPresented = false }
        )
    }

    private func setupPlayer() {
        player.setOnStationPlayed { station in
            let stationuuid = station.stationuuid
            let descriptor = FetchDescriptor<HistoryEntry>(
                predicate: #Predicate { $0.stationuuid == stationuuid }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.playedAt = .now
            } else {
                modelContext.insert(HistoryEntry(station: station))
            }
        }
    }

    private func toggleFavorite() {
        guard let station = player.currentStation else { return }
        if let existing = favorites.first(where: { $0.stationuuid == station.stationuuid }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(Favorite(station: station))
        }
    }
}
