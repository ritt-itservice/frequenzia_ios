//
//  EqualizerView.swift
//  Frequenzia
//
//  Rein dekorative "läuft gerade"-Animation (hüpfende Punkte) – kein
//  echtes Audiosignal, siehe CLAUDE.md Player-Beschreibung.
//
//  Läuft über TimelineView statt über ein implizites `.animation(value:)`
//  mit `.repeatForever().delay(...)`: Diese Kombination bleibt in der
//  Praxis nach der ersten Wiederholung stehen, statt endlos weiterzulaufen
//  (echter Bug, siehe Nutzer-Feedback). TimelineView berechnet die Position
//  jeder Bildwiederholung neu und kann daher nicht "stecken bleiben".
//

import SwiftUI

struct EqualizerView: View {
    var isAnimating: Bool
    var color: Color = .accentColor

    private let dotCount = 5
    private let dotSize: CGFloat = 7
    private let bounceHeight: CGFloat = 5
    private let speed: Double = 4.5

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: isAnimating ? offset(at: time, index: index) : 0)
                }
            }
        }
        .frame(height: 20)
        .opacity(isAnimating ? 1 : 0.35)
    }

    private func offset(at time: TimeInterval, index: Int) -> CGFloat {
        let phase = Double(index) * 0.6
        let wave = sin(time * speed + phase)
        return -CGFloat(max(wave, 0)) * bounceHeight
    }
}
