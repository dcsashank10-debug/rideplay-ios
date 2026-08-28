import Foundation

protocol MusicSource {
    var id: String { get }
    var displayName: String { get }
    func tracks() async -> [Track]
    func search(query: String, limit: Int) async -> [Track]
    func trending(limit: Int) async -> [Track]
    func trackById(_ trackId: String) async -> Track?
    func loadStream(trackId: String) async -> Track?
}

extension MusicSource {
    func search(query: String, limit: Int = 30) async -> [Track] { [] }
    func trending(limit: Int = 30) async -> [Track] { [] }
    func trackById(_ trackId: String) async -> Track? { nil }
    func loadStream(trackId: String) async -> Track? { nil }
}
