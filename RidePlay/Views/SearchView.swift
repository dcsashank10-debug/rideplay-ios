import SwiftUI
import Combine

struct SearchView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var query: String = ""
    @State private var results: [Track] = []
    @State private var loading = false
    @State private var error: String?
    @State private var resolvingId: String?
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchField
                if loading && results.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error, results.isEmpty {
                    Text("Search failed: \(error)").foregroundStyle(.red).padding()
                } else if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Search YouTube, Audius, and your library")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("\(results.count) results")
                        .font(.caption).foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(results) { track in
                                TrackRow(
                                    track: track,
                                    isResolving: resolvingId == track.id
                                ) { play(track) }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Search")
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.gray)
            TextField("Songs, artists, genres", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .onChange(of: query) { new in
                    debounceTask?.cancel()
                    debounceTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        if !Task.isCancelled { await runSearch(new) }
                    }
                }
            if !query.isEmpty {
                Button { query = ""; results = [] } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private func runSearch(_ q: String) async {
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { results = []; return }
        loading = true; error = nil
        let r = await MusicRepository.shared.search(query: trimmed, limit: 30)
        if !Task.isCancelled {
            results = r
            loading = false
        }
    }

    private func play(_ track: Track) {
        resolvingId = track.id
        Task {
            player.playTrack(track, queue: results)
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { resolvingId = nil }
        }
    }
}
