//
//  PlayerView.swift
//  Frequenzia
//
//  Vollbild-Player (Handy) bzw. Seitenpanel/Overlay (iPad, siehe RootView).
//  Getrenntes Hoch-/Querformat-Layout; Cover-Größe an Breite UND Höhe
//  gekoppelt, damit ein zu großes Cover auf kurzen Bildschirmen nicht die
//  Steuerung verdrängt (siehe CLAUDE.md Bugfix-Historie).
//

import SwiftUI

struct PlayerView: View {
    let player: PlayerViewModel
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var onClose: (() -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height

            VStack(spacing: 0) {
                if let onClose {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "chevron.down")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }

                if let station = player.currentStation {
                    if isLandscape {
                        landscapeLayout(station: station, size: proxy.size)
                    } else {
                        portraitLayout(station: station, size: proxy.size)
                    }
                } else {
                    ContentUnavailableView(
                        "Kein Sender ausgewählt",
                        systemImage: "dot.radiowaves.left.and.right",
                        description: Text("Wähle einen Sender aus der Liste.")
                    )
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }

    private func coverSize(for size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.55
    }

    @ViewBuilder
    private func portraitLayout(station: RadioStation, size: CGSize) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)
            coverArt(size: coverSize(for: size), station: station)
            stationInfo(station: station)
            EqualizerView(isAnimating: player.isPlaying)
            controls(station: station)
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func landscapeLayout(station: RadioStation, size: CGSize) -> some View {
        HStack(spacing: 24) {
            coverArt(size: coverSize(for: size), station: station)
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                stationInfo(station: station)
                EqualizerView(isAnimating: player.isPlaying)
                controls(station: station)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }

    private func coverArt(size: CGFloat, station: RadioStation) -> some View {
        StationFaviconView(url: station.faviconURL, size: size)
            .shadow(radius: 12)
    }

    private func stationInfo(station: RadioStation) -> some View {
        VStack(spacing: 6) {
            Text(station.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !station.subtitle.isEmpty {
                Text(station.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if let errorMessage = player.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func controls(station: RadioStation) -> some View {
        HStack(spacing: 36) {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(isFavorite ? .yellow : .primary)
            }
            .buttonStyle(.plain)

            Button(action: { togglePlayback(station: station) }) {
                if player.isBuffering {
                    ProgressView()
                        .controlSize(.large)
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func togglePlayback(station: RadioStation) {
        if player.currentStation?.stationuuid == station.stationuuid {
            player.togglePlayPause()
        } else {
            player.play(station)
        }
    }
}
