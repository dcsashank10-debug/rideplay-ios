import SwiftUI

struct MiniPlayerView: View {
    @StateObject private var player = AudioPlayer.shared
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: player.state.track?.artUri ?? "")) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color(white: 0.2)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(player.state.track?.title ?? "—")
                    .font(.subheadline).bold()
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text(player.state.track?.artist ?? "")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button { player.playPause() } label: {
                Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 60)
        .background(
            LinearGradient(colors: [Color(white: 0.12), Color(white: 0.18)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
