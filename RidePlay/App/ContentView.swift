import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayer.shared
    @State private var showNowPlaying = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                LibraryView()
                    .tabItem { Label("Library", systemImage: "music.note.list") }
            }
            .tint(.green)

            if player.state.track != nil {
                MiniPlayerView(onTap: { showNowPlaying = true })
                    .padding(.bottom, 49)
                    .transition(.move(edge: .bottom))
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(onClose: { showNowPlaying = false })
        }
    }
}

#Preview { ContentView() }
