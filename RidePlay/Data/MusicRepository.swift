import Foundation

actor MusicRepository {
    static let shared = MusicRepository()

    let sources: [MusicSource]
    private var trackCache: [String: [Track]] = [:]
    private var trackByIdCache: [String: Track] = [:]

    init() {
        self.sources = [
            YouTubeMusicSource(),
            AudiusMusicSource(),
            LocalMusicSource()
        ]
    }

    func tracks(sourceId: String) async -> [Track] {
        if let c = trackCache[sourceId] { return c }
        guard let s = sources.first(where: { $0.id == sourceId }) else { return [] }
        let t = await s.tracks()
        trackCache[sourceId] = t
        return t
    }

    func search(query: String, limit: Int = 30) async -> [Track] {
        var merged: [Track] = []
        for s in sources {
            let r = await s.search(query: query, limit: limit)
            merged.append(contentsOf: r)
        }
        var seen = Set<String>()
        var out: [Track] = []
        for t in merged where seen.insert(t.id).inserted {
            out.append(t)
            if out.count >= limit { break }
        }
        return out
    }

    func trending(sourceId: String = "youtube", limit: Int = 30) async -> [Track] {
        guard let s = sources.first(where: { $0.id == sourceId }) else { return [] }
        return await s.trending(limit: limit)
    }

    func trackById(_ trackId: String) async -> Track? {
        if let c = trackByIdCache[trackId] { return c }
        for s in sources {
            if let t = await s.trackById(trackId) {
                trackByIdCache[trackId] = t
                return t
            }
        }
        return nil
    }

    func loadStream(trackId: String) async -> Track? {
        for s in sources {
            if let t = await s.loadStream(trackId: trackId), !t.uri.isEmpty {
                trackByIdCache[trackId] = t
                return t
            }
        }
        return trackByIdCache[trackId]
    }
}
