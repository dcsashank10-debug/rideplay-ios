import CarPlay
import MediaPlayer

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    var tabBarTemplate: CPTabBarTemplate?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        let root = makeRootTemplate()
        self.tabBarTemplate = root
        interfaceController.setRootTemplate(root, animated: false, completion: nil)
        loadTracks()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        self.tabBarTemplate = nil
    }

    private func makeRootTemplate() -> CPTabBarTemplate {
        let youtube = CPListTemplate(title: "YouTube Music", sections: [CPListSection(items: [CPListItem(text: "Loading…", detailText: nil)])])
        youtube.tabImage = UIImage(systemName: "play.rectangle.fill")

        let audius = CPListTemplate(title: "Audius", sections: [CPListSection(items: [CPListItem(text: "Loading…", detailText: nil)])])
        audius.tabImage = UIImage(systemName: "music.note")

        return CPTabBarTemplate(templates: [youtube, audius])
    }

    private func loadTracks() {
        Task { @MainActor in
            let ytTracks = await MusicRepository.shared.trending(sourceId: "youtube", limit: 30)
            let adTracks = await MusicRepository.shared.trending(sourceId: "audius", limit: 30)

            let youtube = CPListTemplate(title: "YouTube Music", sections: [buildSection(tracks: ytTracks)])
            youtube.tabImage = UIImage(systemName: "play.rectangle.fill")

            let audius = CPListTemplate(title: "Audius", sections: [buildSection(tracks: adTracks)])
            audius.tabImage = UIImage(systemName: "music.note")

            let newTabBar = CPTabBarTemplate(templates: [youtube, audius])
            self.tabBarTemplate = newTabBar
            interfaceController?.setRootTemplate(newTabBar, animated: true, completion: nil)
        }
    }

    private func buildSection(tracks: [Track]) -> CPListSection {
        let items: [CPListItem] = tracks.map { track in
            let item = CPListItem(text: track.title, detailText: track.artist)
            item.handler = { _, completion in
                AudioPlayer.shared.playTrack(track, queue: tracks)
                completion()
            }
            return item
        }
        return CPListSection(items: items.isEmpty ? [CPListItem(text: "No tracks available", detailText: nil)] : items)
    }
}
