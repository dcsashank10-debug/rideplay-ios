import Foundation
import MediaPlayer

final class LocalMusicSource: MusicSource {
    let id = "local"
    let displayName = "On Device"

    func querySongs() -> [Track] {
        let query = MPMediaQuery.songs()
        let predicate = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(predicate)
        let items = query.items ?? []
        return items.compactMap { (item: MPMediaItem) -> Track? in
            guard let url = item.assetURL,
                  let title = item.title,
                  let artist = item.artist else { return nil }
            let dur = Int64(item.playbackDuration * 1000)
            let art = item.artwork?.bounds.width != nil ? nil : nil
            return Track(
                id: "local-\(item.persistentID)",
                title: title,
                artist: artist,
                album: item.albumTitle ?? "Local",
                durationMs: dur,
                uri: url.absoluteString,
                artUri: art,
                source: .local
            )
        }
    }

    func tracks() async -> [Track] { querySongs() }
    func search(query: String, limit: Int = 30) async -> [Track] {
        let all = querySongs()
        guard !query.isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(q) ||
            $0.artist.lowercased().contains(q) ||
            $0.album.lowercased().contains(q)
        }
    }
    func trackById(_ trackId: String) async -> Track? {
        querySongs().first { $0.id == trackId }
    }
}
