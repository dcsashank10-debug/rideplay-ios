import SwiftUI

struct LibraryView: View {
    @State private var localTracks: [Track] = []

    var body: some View {
        NavigationStack {
            VStack {
                if localTracks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No music on this device")
                            .foregroundStyle(.gray)
                        Text("Add songs via the Music app to see them here")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(localTracks) { track in
                                TrackRow(track: track) {
                                    AudioPlayer.shared.playTrack(track, queue: localTracks)
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
            .task {
                localTracks = await MusicRepository.shared.tracks(sourceId: "local")
            }
        }
    }
}
