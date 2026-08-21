//
//  StationRow.swift
//  Frequenzia
//
//  Zeile mit Icon, Name, Land/Genre, Favoriten-Stern und Play-Button.
//  Tippen auf die Zeile = Vorschau, Tippen auf Play = sofort abspielen.
//

import SwiftUI

struct StationRow: View {
    let station: RadioStation
    let isFavorite: Bool
    let isCurrent: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StationFaviconView(url: station.faviconURL, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name)
                    .font(.body)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .lineLimit(1)
                if !station.subtitle.isEmpty {
                    Text(station.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)

            Button(action: onPlay) {
                PlayPauseIcon(isPlaying: isCurrent && isPlaying, diameter: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
