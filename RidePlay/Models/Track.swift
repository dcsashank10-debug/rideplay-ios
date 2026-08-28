import Foundation

enum SourceType: String, Codable {
    case local = "LOCAL"
    case streaming = "STREAMING"
}

struct Track: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let durationMs: Int64
    var uri: String
    var artUri: String?
    let source: SourceType

    init(id: String, title: String, artist: String, album: String,
         durationMs: Int64, uri: String, artUri: String? = nil,
         source: SourceType = .streaming) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.durationMs = durationMs
        self.uri = uri
        self.artUri = artUri
        self.source = source
    }

    var mediaId: String { "track:\(id)" }
}

struct Album: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let artist: String
    var artUri: String?
    let trackIds: [String]
    var mediaId: String { "album:\(id)" }
}

struct Artist: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let trackIds: [String]
    let albumIds: [String]
    var mediaId: String { "artist:\(id)" }
}

struct Playlist: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var artUri: String?
    let trackIds: [String]
    var mediaId: String { "playlist:\(id)" }
}

enum MediaItem: Identifiable, Hashable {
    case track(Track)
    case album(Album)
    case artist(Artist)
    case playlist(Playlist)

    var id: String {
        switch self {
        case .track(let t): return t.id
        case .album(let a): return a.id
        case .artist(let ar): return ar.id
        case .playlist(let p): return p.id
        }
    }

    var title: String {
        switch self {
        case .track(let t): return t.title
        case .album(let a): return a.title
        case .artist(let ar): return ar.name
        case .playlist(let p): return p.name
        }
    }

    var subtitle: String? {
        switch self {
        case .track(let t): return t.artist
        case .album(let a): return a.artist
        case .artist, .playlist: return nil
        }
    }

    var artUri: String? {
        switch self {
        case .track(let t): return t.artUri
        case .album(let a): return a.artUri
        case .artist, .playlist: return nil
        }
    }
}
