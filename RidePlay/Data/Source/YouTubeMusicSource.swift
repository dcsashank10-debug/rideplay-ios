import Foundation

final class YouTubeMusicSource: MusicSource {
    let id = "youtube"
    let displayName = "YouTube Music"

    private let instances = [
        "https://iv.melmac.space",
        "https://iv.duti.dev",
        "https://invidious.privacydev.net",
        "https://invidious.fdn.fr",
        "https://invidious.lunar.icu",
        "https://yewtu.be",
        "https://inv.nadeko.net"
    ]

    private var workingInstance: String

    init() {
        self.workingInstance = instances[0]
    }

    private func videoId(from trackId: String) -> String? {
        trackId.hasPrefix("yt-") ? String(trackId.dropFirst(3)) : nil
    }

    private func trackId(for videoId: String) -> String { "yt-\(videoId)" }

    private func withInstance<T>(_ block: (String) async -> T?) async -> T? {
        if let r = await block(workingInstance) { return r }
        for host in instances where host != workingInstance {
            if let r = await block(host) {
                workingInstance = host
                return r
            }
        }
        return nil
    }

    private func pickBestThumb(_ thumbs: [[String: Any]]?) -> String? {
        guard let thumbs else { return nil }
        var best: String?
        var bestArea = 0
        for t in thumbs {
            let w = (t["width"] as? Int) ?? 0
            let h = (t["height"] as? Int) ?? 0
            let area = w * h
            if area > bestArea, let url = t["url"] as? String {
                bestArea = area
                best = url
            }
        }
        return best
    }

    private func pickBestAudio(_ formats: [[String: Any]]?) -> [String: Any]? {
        guard let formats else { return nil }
        var best: [String: Any]?
        var bestBitrate = 0
        for f in formats {
            let type = (f["type"] as? String) ?? ""
            if !type.hasPrefix("audio/") { continue }
            let br = (f["bitrate"] as? Int) ?? 0
            if br > bestBitrate {
                bestBitrate = br
                best = f
            }
        }
        return best
    }

    private func parseSearchItem(_ o: [String: Any]) -> Track? {
        guard let videoId = o["videoId"] as? String, !videoId.isEmpty,
              let title = o["title"] as? String, !title.isEmpty else { return nil }
        let author = (o["author"] as? String) ?? "Unknown"
        let len = (o["lengthSeconds"] as? Int) ?? 0
        let thumb = pickBestThumb(o["videoThumbnails"] as? [[String: Any]])
        return Track(
            id: trackId(for: videoId),
            title: title,
            artist: author,
            album: "YouTube",
            durationMs: Int64(len) * 1000,
            uri: "",
            artUri: thumb
        )
    }

    private func doSearch(_ query: String, limit: Int) async -> [Track] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let result: [Track]? = await withInstance { host in
            let url = "\(host)/api/v1/search?q=\(encoded)&type=video&fields=title,videoId,author,lengthSeconds,videoThumbnails"
            do {
                let arr = try await APIClient.shared.getJSONArrayRaw(url)
                var out: [Track] = []
                for item in arr {
                    if let dict = item as? [String: Any], let t = parseSearchItem(dict) {
                        out.append(t)
                        if out.count >= limit { break }
                    }
                }
                return out.isEmpty ? nil : out
            } catch { return nil }
        }
        return result ?? []
    }

    private func doStreams(_ videoId: String) async -> Track? {
        await withInstance { host in
            let url = "\(host)/api/v1/videos/\(videoId)?fields=title,author,lengthSeconds,adaptiveFormats,videoThumbnails"
            do {
                let obj = try await APIClient.shared.getJSONRaw(url)
                guard let audio = self.pickBestAudio(obj["adaptiveFormats"] as? [[String: Any]]),
                      let streamUrl = audio["url"] as? String, !streamUrl.isEmpty else { return nil }
                let title = (obj["title"] as? String) ?? "Unknown"
                let author = (obj["author"] as? String) ?? "Unknown"
                let len = (obj["lengthSeconds"] as? Int) ?? 0
                let thumb = self.pickBestThumb(obj["videoThumbnails"] as? [[String: Any]])
                return Track(
                    id: self.trackId(for: videoId),
                    title: title,
                    artist: author,
                    album: "YouTube",
                    durationMs: Int64(len) * 1000,
                    uri: streamUrl,
                    artUri: thumb
                )
            } catch { return nil }
        }
    }

    func search(query: String, limit: Int = 30) async -> [Track] {
        await doSearch(query, limit: limit)
    }

    func trending(limit: Int = 30) async -> [Track] {
        let queries = [
            "top hits 2026", "trending music", "viral songs",
            "billboard hot 100", "ed sheeran", "taylor swift",
            "drake", "the weeknd", "bad bunny", "pop hits"
        ]
        var all: [Track] = []
        for q in queries {
            let r = await doSearch(q, limit: 5)
            all.append(contentsOf: r)
        }
        var seen = Set<String>()
        var unique: [Track] = []
        for t in all where seen.insert(t.id).inserted {
            unique.append(t)
            if unique.count >= limit { break }
        }
        return unique
    }

    func tracks() async -> [Track] { await trending(limit: 50) }

    func trackById(_ trackId: String) async -> Track? {
        guard let vid = videoId(from: trackId) else { return nil }
        return await doStreams(vid)
    }

    func loadStream(trackId: String) async -> Track? {
        guard let vid = videoId(from: trackId) else { return nil }
        return await doStreams(vid)
    }
}
