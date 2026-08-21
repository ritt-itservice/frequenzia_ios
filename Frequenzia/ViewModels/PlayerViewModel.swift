//
//  PlayerViewModel.swift
//  Frequenzia
//
//  Kapselt AVPlayer-Wiedergabe, Preview- vs. Play-Zustand sowie die
//  Lockscreen-/Control-Center-Integration (MPNowPlayingInfoCenter,
//  MPRemoteCommandCenter).
//

import AVFoundation
import Foundation
import MediaPlayer
import Observation
import UIKit

@MainActor
@Observable
final class PlayerViewModel {
    private(set) var currentStation: RadioStation?
    private(set) var isPlaying: Bool = false
    private(set) var isBuffering: Bool = false
    private(set) var errorMessage: String?

    private var player: AVPlayer?
    private var timeControlObservation: NSKeyValueObservation?
    private var endTimeObserver: NSObjectProtocol?
    private var cachedArtwork: MPMediaItemArtwork?
    private var artworkTask: Task<Void, Never>?

    private let client: RadioBrowserClient
    private var onStationPlayed: ((RadioStation) -> Void)?

    var hasStation: Bool { currentStation != nil }

    init(client: RadioBrowserClient = .shared) {
        self.client = client
        configureAudioSession()
        configureRemoteCommands()
    }

    /// Wird von außen (RootView) gesetzt, um einen Verlaufseintrag zu
    /// schreiben, sobald tatsächlich (nicht nur zur Vorschau) abgespielt wird.
    func setOnStationPlayed(_ handler: @escaping (RadioStation) -> Void) {
        onStationPlayed = handler
    }

    /// Tippen auf eine Senderzeile: lädt den Sender in den Player, spielt
    /// aber noch nicht ab.
    func preview(_ station: RadioStation) {
        guard station.stationuuid != currentStation?.stationuuid else { return }
        loadStation(station, autoplay: false)
    }

    /// Play-Button (Zeile oder Player): startet die Wiedergabe.
    func play(_ station: RadioStation) {
        if station.stationuuid != currentStation?.stationuuid {
            loadStation(station, autoplay: true)
        } else {
            resume()
        }
    }

    func togglePlayPause() {
        guard currentStation != nil else { return }
        isPlaying ? pause() : resume()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    private func loadStation(_ station: RadioStation, autoplay: Bool) {
        teardownPlayer()
        currentStation = station
        errorMessage = nil
        cachedArtwork = nil
        loadArtwork(for: station)
        updateNowPlayingInfo()

        guard let url = station.streamURL else {
            errorMessage = "Ungültige Stream-Adresse."
            return
        }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        observe(player: newPlayer, item: item)

        if autoplay {
            resume()
        }
    }

    private func resume() {
        guard let station = currentStation, let player else { return }
        errorMessage = nil
        player.play()
        isPlaying = true
        isBuffering = true
        updateNowPlayingInfo()

        onStationPlayed?(station)
        Task { await client.registerClick(stationuuid: station.stationuuid) }
    }

    private func teardownPlayer() {
        player?.pause()
        timeControlObservation = nil
        if let endTimeObserver {
            NotificationCenter.default.removeObserver(endTimeObserver)
        }
        endTimeObserver = nil
        player = nil
        isPlaying = false
        isBuffering = false
        artworkTask?.cancel()
    }

    private func observe(player: AVPlayer, item: AVPlayerItem) {
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] observedPlayer, _ in
            Task { @MainActor in
                guard let self else { return }
                switch observedPlayer.timeControlStatus {
                case .playing:
                    self.isBuffering = false
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering = true
                case .paused:
                    break
                @unknown default:
                    break
                }
            }
        }

        endTimeObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.errorMessage = "Wiedergabe unterbrochen."
                self?.isPlaying = false
            }
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "Audio-Sitzung konnte nicht aktiviert werden."
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.resume() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.pause() }
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.togglePlayPause() }
            return .success
        }
        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.pause() }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let station = currentStation else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: station.name,
            MPMediaItemPropertyArtist: station.subtitle,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let cachedArtwork {
            info[MPMediaItemPropertyArtwork] = cachedArtwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(for station: RadioStation) {
        guard let url = station.faviconURL else { return }
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            guard !Task.isCancelled, let self, self.currentStation?.stationuuid == station.stationuuid else { return }
            self.cachedArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            self.updateNowPlayingInfo()
        }
    }
}
