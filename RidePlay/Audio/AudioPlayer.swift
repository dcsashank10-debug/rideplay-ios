import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

struct NowPlayingState: Equatable {
    var track: Track?
    var isPlaying: Bool = false
    var isBuffering: Bool = false
    var positionMs: Int64 = 0
    var durationMs: Int64 = 0
    var queue: [Track] = []
    var queueIndex: Int = 0
    var shuffleEnabled: Bool = false
    var repeatMode: RepeatMode = .off
}

enum RepeatMode: Equatable { case off, all, one }

final class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    @Published private(set) var state = NowPlayingState()
    let events = PassthroughSubject<String, Never>()

    private var player: AVPlayer = AVPlayer()
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var preloadTask: Task<Void, Never>?

    private init() {
        configureAudioSession()
        configureRemoteCommands()
        observePlayer()
    }

    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.onMain { self?.play() }; return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.onMain { self?.pause() }; return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.onMain { self?.playPause() }; return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.onMain { self?.next() }; return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.onMain { self?.prev() }; return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] evt in
            guard let e = evt as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let ms = Int64(e.positionTime * 1000)
            self?.onMain { self?.seek(toMs: ms) }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in self?.onMain { self?.seekForward() }; return .success }
        center.skipBackwardCommand.addTarget { [weak self] _ in self?.onMain { self?.seekBack() }; return .success }
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let ms = Int64(CMTimeGetSeconds(time) * 1000)
            let dur = Int64(CMTimeGetSeconds(self.player.currentItem?.duration ?? .zero) * 1000)
            if self.state.isPlaying {
                self.state.positionMs = ms
                if dur > 0 { self.state.durationMs = dur }
            }
        }
    }

    private func setupItem(url: URL) {
        let item = AVPlayerItem(url: url)
        playerItem = item
        statusObserver?.invalidate()
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            self?.onMain {
                guard let self else { return }
                self.state.isBuffering = (item.status == .unknown)
                if item.status == .readyToPlay {
                    let dur = Int64(CMTimeGetSeconds(item.duration) * 1000)
                    if dur > 0 { self.state.durationMs = dur }
                }
            }
        }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.onMain { self?.handleTrackEnd() }
        }
        player.replaceCurrentItem(with: item)
    }

    private func handleTrackEnd() {
        if state.repeatMode == .one {
            player.seek(to: .zero)
            player.play()
            return
        }
        if state.repeatMode == .all && state.queueIndex == state.queue.count - 1 {
            state.queueIndex = 0
            state.track = state.queue[0]
            state.positionMs = 0
            loadAndPlay(track: state.queue[0])
            return
        }
        if state.queueIndex < state.queue.count - 1 {
            next()
        } else {
            player.seek(to: .zero)
            state.isPlaying = false
            updateNowPlaying()
        }
    }

    func playTrack(_ track: Track, queue: [Track] = []) {
        let q = queue.isEmpty ? [track] : queue
        let idx = q.firstIndex(where: { $0.id == track.id }) ?? 0
        state.queue = q
        state.queueIndex = idx
        state.track = track
        state.positionMs = 0
        loadAndPlay(track: track)
    }

    func playQueue(_ tracks: [Track], startIndex: Int = 0) {
        guard !tracks.isEmpty else { return }
        var q = tracks
        if state.shuffleEnabled && q.count > 1 {
            let first = q[startIndex]
            var rest = q
            rest.remove(at: startIndex)
            rest.shuffle()
            q = [first] + rest
        }
        state.queue = q
        state.queueIndex = 0
        state.track = q[0]
        state.positionMs = 0
        loadAndPlay(track: q[0])
    }

    func toggleShuffle() {
        state.shuffleEnabled.toggle()
        events.send(state.shuffleEnabled ? "Shuffle on" : "Shuffle off")
    }

    func cycleRepeat() {
        state.repeatMode = {
            switch state.repeatMode {
            case .off: return .all
            case .all: return .one
            case .one: return .off
            }
        }()
        events.send({
            switch state.repeatMode {
            case .off: return "Repeat off"
            case .all: return "Repeat all"
            case .one: return "Repeat one"
            }
        }())
    }

    private func loadAndPlay(track: Track) {
        if track.uri.isEmpty, track.id.hasPrefix("yt-") {
            state.isBuffering = true
            updateNowPlaying()
            Task {
                if let resolved = await MusicRepository.shared.loadStream(trackId: track.id) {
                    self.onMain {
                        if let idx = self.state.queue.firstIndex(where: { $0.id == resolved.id }) {
                            self.state.queue[idx] = resolved
                        }
                        if self.state.track?.id == resolved.id {
                            self.state.track = resolved
                        }
                        if let url = URL(string: resolved.uri) {
                            self.startPlayback(url: url)
                        }
                    }
                } else {
                    self.onMain {
                        self.state.isBuffering = false
                        self.events.send("Could not load stream")
                    }
                }
            }
        } else if let url = URL(string: track.uri) {
            startPlayback(url: url)
        }
    }

    private func startPlayback(url: URL) {
        setupItem(url: url)
        player.play()
        state.isPlaying = true
        state.isBuffering = false
        updateNowPlaying()
        preloadNextIfNeeded()
    }

    func play() {
        player.play()
        state.isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player.pause()
        state.isPlaying = false
        updateNowPlaying()
    }

    func playPause() {
        if state.isPlaying { pause() } else { play() }
    }

    func next() {
        guard state.queueIndex < state.queue.count - 1 else { return }
        state.queueIndex += 1
        state.track = state.queue[state.queueIndex]
        state.positionMs = 0
        loadAndPlay(track: state.track!)
    }

    func prev() {
        if state.positionMs > 3000 {
            seek(toMs: 0)
            return
        }
        guard state.queueIndex > 0 else {
            seek(toMs: 0); return
        }
        state.queueIndex -= 1
        state.track = state.queue[state.queueIndex]
        state.positionMs = 0
        loadAndPlay(track: state.track!)
    }

    func seek(toMs ms: Int64) {
        let t = CMTime(seconds: Double(ms) / 1000, preferredTimescale: 600)
        player.seek(to: t)
        state.positionMs = ms
    }

    func seekBack() {
        seek(toMs: max(0, state.positionMs - 15_000))
    }

    func seekForward() {
        let target = min(state.durationMs, state.positionMs + 30_000)
        seek(toMs: target)
    }

    private func preloadNextIfNeeded() {
        preloadTask?.cancel()
        let nextIdx = state.queueIndex + 1
        guard nextIdx < state.queue.count else { return }
        let next = state.queue[nextIdx]
        guard let url = URL(string: next.uri) else { return }
        preloadTask = Task.detached(priority: .background) {
            _ = try? await AVURLAsset(url: url).loadValuesAsynchronously(forKeys: ["playable"])
        }
    }

    private func updateNowPlaying() {
        guard let track = state.track else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: Double(track.durationMs) / 1000,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: Double(state.positionMs) / 1000,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0
        ]
        if let artUrl = track.artUri {
            loadArtwork(url: artUrl) { img in
                guard let img else { return }
                var current = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                current[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = current
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(url: String, completion: @escaping (UIImage?) -> Void) {
        guard let u = URL(string: url) else { completion(nil); return }
        Task.detached {
            let img: UIImage? = await withCheckedContinuation { cont in
                URLSession.shared.dataTask(with: u) { data, _, _ in
                    if let data, let image = UIImage(data: data) {
                        cont.resume(returning: image)
                    } else {
                        cont.resume(returning: nil)
                    }
                }.resume()
            }
            self.onMain { completion(img) }
        }
    }
}
