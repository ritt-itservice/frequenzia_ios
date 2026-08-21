//
//  EqualizerView.swift
//  Frequenzia
//
//  Rein dekorative "läuft gerade"-Animation (wippende Balken) – kein
//  echtes Audiosignal, siehe CLAUDE.md Player-Beschreibung.
//
//  Läuft über TimelineView statt über ein implizites `.animation(value:)`
//  mit `.repeatForever().delay(...)`: Diese Kombination bleibt in der
//  Praxis nach der ersten Wiederholung stehen, statt endlos weiterzulaufen
//  (echter Bug, siehe Nutzer-Feedback). TimelineView berechnet die Höhe
//  jeder Bildwiederholung neu und kann daher nicht "stecken bleiben".
//

import SwiftUI

struct EqualizerView: View {
    var isAnimating: Bool
    var color: Color = .accentColor

    private let minHeight: CGFloat = 6
    private let maxHeights: [CGFloat] = [16, 26, 12, 22]
    private let speeds: [Double] = [3.2, 4.1, 2.6, 3.7]

    var body: some View {
        TimelineView(.animation(paused: !isAnimating)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<maxHeights.count, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: 4, height: isAnimating ? height(at: time, index: index) : minHeight)
                }
            }
        }
        .frame(height: maxHeights.max() ?? 28, alignment: .bottom)
        .opacity(isAnimating ? 1 : 0.4)
    }

    private func height(at time: TimeInterval, index: Int) -> CGFloat {
        let phase = Double(index) * 1.3
        let wave = (sin(time * speeds[index] + phase) + 1) / 2
        return minHeight + CGFloat(wave) * (maxHeights[index] - minHeight)
    }
}
