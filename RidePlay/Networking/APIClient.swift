import Foundation

enum APIError: Error {
    case invalidResponse
    case http(Int)
    case decode(String)
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 20
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()

    func getJSON<T: Decodable>(_ url: String, as type: T.Type) async throws -> T {
        guard let u = URL(string: url) else { throw APIError.invalidResponse }
        var req = URLRequest(url: u)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decode(String(describing: error))
        }
    }

    func getData(_ url: String) async throws -> Data {
        guard let u = URL(string: url) else { throw APIError.invalidResponse }
        var req = URLRequest(url: u)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }
        return data
    }

    func getJSONRaw(_ url: String) async throws -> Any {
        let data = try await getData(url)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decode("not an object")
        }
        return obj
    }

    func getJSONArrayRaw(_ url: String) async throws -> [Any] {
        let data = try await getData(url)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw APIError.decode("not an array")
        }
        return arr
    }
}
