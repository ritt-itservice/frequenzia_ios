//
//  StationFaviconView.swift
//  Frequenzia
//
//  Rundes Sender-Icon mit Platzhalter, falls favicon fehlt oder kaputt ist.
//

import SwiftUI

struct StationFaviconView: View {
    let url: URL?
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(.quaternary)

            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Image(systemName: "dot.radiowaves.left.and.right")
            .font(.system(size: size * 0.4))
            .foregroundStyle(.secondary)
    }
}
