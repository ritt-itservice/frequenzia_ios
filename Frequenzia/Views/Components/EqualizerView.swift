//
//  EqualizerView.swift
//  Frequenzia
//
//  Rein dekorative "läuft gerade"-Animation (hüpfende Punkte) – kein
//  echtes Audiosignal, siehe CLAUDE.md Player-Beschreibung.
//

import SwiftUI

struct EqualizerView: View {
    var isAnimating: Bool
    var color: Color = .accentColor

    @State private var bounce = false

    private let dotCount = 5
    private let dotSize: CGFloat = 7

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: bounce ? -5 : 0)
                    .animation(
                        isAnimating
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1)
                            : .easeOut(duration: 0.2),
                        value: bounce
                    )
            }
        }
        .frame(height: 20)
        .opacity(isAnimating ? 1 : 0.35)
        .onAppear { bounce = isAnimating }
        .onChange(of: isAnimating) { _, newValue in bounce = newValue }
    }
}
