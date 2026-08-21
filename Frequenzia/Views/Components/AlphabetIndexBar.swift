//
//  AlphabetIndexBar.swift
//  Frequenzia
//
//  A–Z-Schnellzugriffsleiste für die Favoriten. Wichtige Lehre aus einem
//  echten Android-Bug (siehe CLAUDE.md): Bei zu wenig Höhe darf die Zeilen-
//  höhe NICHT gleichmäßig über die volle Höhe verteilt werden (27 Buchstaben
//  ÷ wenig Platz = Text faktisch unsichtbar). Jeder Buchstabe behält eine
//  feste Mindesthöhe; reicht der Platz nicht, scrollt die Leiste selbst statt
//  sich zu stauchen.
//

import SwiftUI

struct AlphabetIndexBar: View {
    let availableLetters: Set<String>
    let onSelect: (String) -> Void

    private let letters: [String] = ["#"] + (65...90).map { String(UnicodeScalar($0)!) }
    private let minRowHeight: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let contentHeight = CGFloat(letters.count) * minRowHeight
            let needsScroll = contentHeight > proxy.size.height

            if needsScroll {
                ScrollView(.vertical, showsIndicators: false) {
                    letterStack
                }
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    letterStack
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: 20)
    }

    private var letterStack: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                let isAvailable = availableLetters.contains(letter)
                Text(letter)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isAvailable ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(minHeight: minRowHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isAvailable else { return }
                        onSelect(letter)
                    }
            }
        }
    }
}
