//
//  PlayPauseIcon.swift
//  Frequenzia
//
//  Gefüllter Kreis in Akzentfarbe mit weißem Play-/Pause-Symbol – bewusst
//  zwei eigenständige Ebenen statt "play.circle.fill"/"pause.circle.fill":
//  Das SF-Symbol schneidet das Dreieck nur aus der Kreisfläche aus und
//  zeigt den Hintergrund durch, was im Dark Mode statt Weiß die dunkle
//  App-Hintergrundfarbe zeigen würde.
//

import SwiftUI

struct PlayPauseIcon: View {
    let isPlaying: Bool
    var diameter: CGFloat = 32
    var color: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: diameter * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .offset(x: isPlaying ? 0 : diameter * 0.03)
        }
        .frame(width: diameter, height: diameter)
    }
}
