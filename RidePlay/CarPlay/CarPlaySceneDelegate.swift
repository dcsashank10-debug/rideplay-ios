import CarPlay
import MediaPlayer

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        let root = makeRootTemplate()
        interfaceController.setRootTemplate(root, animated: false, completion: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }

    private func makeRootTemplate() -> CPTabBarTemplate {
        let youtube = CPListTemplate(title: "YouTube Music", sections: [youtubeSection()])
        youtube.tabImage = UIImage(systemName: "play.rectangle.fill")

        let audius = CPListTemplate(title: "Audius", sections: [audiusSection()])
        audius.tabImage = UIImage(systemName: "music.note")

        return CPTabBarTemplate(templates: [youtube, audius])
    }

    private func youtubeSection() -> CPListSection {
        let placeholder = CPListItem(text: "Loading…", detailText: nil)
        let section = CPListSection(items: [placeholder])
        Task { @MainActor in
            let tracks = await MusicRepository.shared.trending(sourceId: "youtube", limit: 30)
            section.updateItems(tracks.map { track in
                let item = CPListItem(text: track.title, detailText: track.artist)
                item.handler = { _, completion in
                    AudioPlayer.shared.playTrack(track, queue: tracks)
                    completion()
                }
                return item
            })
        }
        return section
    }

    private func audiusSection() -> CPListSection {
        let placeholder = CPListItem(text: "Loading…", detailText: nil)
        let section = CPListSection(items: [placeholder])
        Task { @MainActor in
            let tracks = await MusicRepository.shared.trending(sourceId: "audius", limit: 30)
            section.updateItems(tracks.map { track in
                let item = CPListItem(text: track.title, detailText: track.artist)
                item.handler = { _, completion in
                    AudioPlayer.shared.playTrack(track, queue: tracks)
                    completion()
                }
                return item
            })
        }
        return section
    }
}
