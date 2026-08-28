import SwiftUI

struct NowPlayingView: View {
    @StateObject private var player = AudioPlayer.shared
    let onClose: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 20) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.down").font(.title2)
                    }
                    Spacer()
                    Text("Playing from YouTube")
                        .font(.caption).foregroundStyle(.gray)
                    Spacer()
                    Spacer().frame(width: 24)
                }
                .foregroundStyle(.white)
                .padding()

                Spacer()

                artwork

                VStack(spacing: 6) {
                    Text(player.state.track?.title ?? "—")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(player.state.track?.artist ?? "")
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)

                progress

                extraControls

                controls
                    .padding(.bottom, 40)
            }
        }
    }

    private var extraControls: some View {
        HStack(spacing: 60) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundStyle(player.state.shuffleEnabled ? Color.green : .white)
            }
            Spacer()
            Button { player.cycleRepeat() } label: {
                Image(systemName: repeatIcon)
                    .font(.title3)
                    .foregroundStyle(player.state.repeatMode == .off ? .white : Color.green)
            }
        }
        .padding(.horizontal, 60)
    }

    private var repeatIcon: String {
        switch player.state.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var artwork: some View {
        AsyncImage(url: URL(string: player.state.track?.artUri ?? "")) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            default:
                Color(white: 0.2)
                    .overlay(Image(systemName: "music.note").font(.system(size: 60)).foregroundStyle(.gray))
            }
            }
            .frame(width: 320, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 20)
    }

    private var progress: some View {
        let pos = Double(player.state.positionMs) / 1000
        let dur = max(0.001, Double(player.state.durationMs) / 1000)
        let pct = min(1, pos / dur)
        return VStack {
            Slider(value: Binding(
                get: { pct },
                set: { newVal in
                    let ms = Int64(newVal * dur * 1000)
                    player.seek(toMs: ms)
                }
            ))
            .tint(.white)
            HStack {
                Text(format(pos)).font(.caption).foregroundStyle(.gray)
                Spacer()
                Text(format(dur)).font(.caption).foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 30)
    }

    private var controls: some View {
        HStack(spacing: 40) {
            Button { player.seekBack() } label: {
                Image(systemName: "gobackward.15").font(.system(size: 32))
            }
            Button { player.playPause() } label: {
                Image(systemName: player.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            Button { player.seekForward() } label: {
                Image(systemName: "goforward.30").font(.system(size: 32))
            }
        }
        .foregroundStyle(.white)
    }

    private func format(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
