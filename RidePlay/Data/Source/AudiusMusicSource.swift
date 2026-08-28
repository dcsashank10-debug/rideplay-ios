import Foundation

final class AudiusMusicSource: MusicSource {
    let id = "audius"
    let displayName = "Audius"

    private let appName = "RidePlay"
    private var cachedHost: String?

    private func host() async throws -> String {
        if let h = cachedHost { return h }
        let arr = try await APIClient.shared.getJSONArrayRaw("https://api.audius.co")
        let pick = (arr.compactMap { $0 as? String }).first(where: { $0.hasPrefix("https://") }) ?? (arr.first as? String ?? "")
        cachedHost = pick
        return pick
    }

    private func trackUrl(_ id: String) -> String {
        "https://audius.co/v1/tracks/\(id)/stream?app_name=\(appName)"
    }

    private func artworkUrl(_ id: String) -> String {
        "https://audius.co/v1/tracks/\(id)/artwork?height=480&app_name=\(appName)"
    }

    private func parseTrack(_ o: [String: Any]) -> Track? {
        guard let id = o["id"] as? String else { return nil }
        let user = o["user"] as? [String: Any]
        let artist = (user?["name"] as? String) ?? "Unknown"
        let genre = (o["genre"] as? String) ?? "Audius"
        let title = (o["title"] as? String) ?? "Untitled"
        let dur = (o["duration"] as? Int) ?? 0
        return Track(
            id: "audius-\(id)",
            title: title,
            artist: artist,
            album: genre,
            durationMs: Int64(dur) * 1000,
            uri: trackUrl(id),
            artUri: artworkUrl(id)
        )
    }

    private func fetchTracks(path: String, limit: Int) async -> [Track] {
        do {
            let h = try await host()
            let sep = path.contains("?") ? "&" : "?"
            let url = "\(h)\(path)\(sep)limit=\(limit)&app_name=\(appName)"
            let obj = try await APIClient.shared.getJSONRaw(url)
            guard let arr = obj["data"] as? [[String: Any]] else { return [] }
            return arr.compactMap { parseTrack($0) }
        } catch { return [] }
    }

    func search(query: String, limit: Int = 30) async -> [Track] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return await fetchTracks(path: "/v1/tracks/search?query=\(encoded)", limit: limit)
    }

    func trending(limit: Int = 30) async -> [Track] {
        await fetchTracks(path: "/v1/tracks/trending?", limit: limit)
    }

    func tracks() async -> [Track] { await trending(limit: 50) }

    func trackById(_ trackId: String) async -> Track? {
        guard trackId.hasPrefix("audius-") else { return nil }
        let real = String(trackId.dropFirst(7))
        do {
            let h = try await host()
            let obj = try await APIClient.shared.getJSONRaw("\(h)/v1/tracks/\(real)?app_name=\(appName)")
            if let data = obj["data"] as? [String: Any] { return parseTrack(data) }
        } catch {}
        return nil
    }
}
