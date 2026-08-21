//
//  InfoView.swift
//  Frequenzia
//
//  App-Icon, Name, Version, Links zu Quellcode/Lizenz/Autor/Radio Browser.
//  Kein "App bewerten"-Link, solange es noch keinen App-Store-Eintrag gibt
//  (siehe CLAUDE.md: Store-Texte müssen wahrheitsgemäß sein).
//

import SwiftUI

struct InfoView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Text("Frequenzia")
                            .font(.title2.bold())
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Link(destination: URL(string: "https://github.com/ritt-itservice/frequenzia_ios")!) {
                        Label("Quellcode", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!) {
                        Label("Lizenz (GPLv3)", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "mailto:kontakt@ritt-itservice.de")!) {
                        Label("Autor: Eduard Ritt", systemImage: "envelope")
                    }
                    Link(destination: URL(string: "https://www.radio-browser.info")!) {
                        Label("Sender-Daten: Radio Browser", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Info")
        }
    }
}
