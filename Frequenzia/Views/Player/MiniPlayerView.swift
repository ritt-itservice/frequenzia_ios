//
//  MiniPlayerView.swift
//  Frequenzia
//
//  Sichtbar, sobald ein Sender geladen ist (läuft oder pausiert). Tippen
//  öffnet den Vollbild-Player wieder.
//

import SwiftUI

struct MiniPlayerView: View {
    let player: PlayerViewModel
    let onTap: () -> Void

    var body: some View {
        if let station = player.currentStation {
            HStack(spacing: 12) {
                StationFaviconView(url: station.faviconURL, size: 36)

                VStack(alignment: .leading, spacing: 0) {
                    Text(station.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if !station.subtitle.isEmpty {
                        Text(station.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                EqualizerView(isAnimating: player.isPlaying)
                    .frame(width: 24)

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}
