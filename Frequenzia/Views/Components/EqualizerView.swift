//
//  EqualizerView.swift
//  Frequenzia
//
//  Rein dekorative Wellenform-Animation ("läuft gerade") – kein echtes
//  Audiosignal, siehe CLAUDE.md Player-Beschreibung.
//

import SwiftUI

struct EqualizerView: View {
    var isAnimating: Bool
    var color: Color = .accentColor

    @State private var grow = false

    private let heights: [CGFloat] = [16, 26, 12, 22]
    private let durations: [Double] = [0.45, 0.6, 0.4, 0.55]

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<heights.count, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 4, height: grow ? heights[index] : 6)
                    .animation(
                        isAnimating
                            ? .easeInOut(duration: durations[index]).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.2),
                        value: grow
                    )
            }
        }
        .frame(height: heights.max() ?? 28, alignment: .bottom)
        .opacity(isAnimating ? 1 : 0.4)
        .onAppear { grow = isAnimating }
        .onChange(of: isAnimating) { _, newValue in grow = newValue }
    }
}
