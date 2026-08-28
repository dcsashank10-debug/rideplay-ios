import SwiftUI

struct HomeView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var youtubeTrending: [Track] = []
    @State private var audiusTrending: [Track] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if !audiusTrending.isEmpty {
                        sectionTitle("Trending on Audius")
                        trackList(audiusTrending)
                    }
                    if !youtubeTrending.isEmpty {
                        sectionTitle("Top hits on YouTube")
                        trackList(youtubeTrending)
                    }
                    if loading && audiusTrending.isEmpty && youtubeTrending.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black.ignoresSafeArea())
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Good evening")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
            Text("Made for the road")
                .font(.title3)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.title2).bold()
            .foregroundStyle(.white)
            .padding(.horizontal)
    }

    private func trackList(_ tracks: [Track]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(tracks) { track in
                TrackRow(track: track) {
                    player.playTrack(track, queue: tracks)
                }
            }
        }
        .padding(.bottom, 80)
    }

    private func load() async {
        loading = true
        async let yt = MusicRepository.shared.trending(sourceId: "youtube", limit: 20)
        async let au = MusicRepository.shared.trending(sourceId: "audius", limit: 20)
        let (y, a) = await (yt, au)
        youtubeTrending = y
        audiusTrending = a
        loading = false
    }
}
