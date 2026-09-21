import Foundation

struct HTTPResponse {
    let status: Int
    let data: Data
}

/// Minimal JSON GET/POST helper shared by all providers.
enum HTTP {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    static func request(
        _ url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> HTTPResponse {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        do {
            let (data, response) = try await session.data(for: req)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return HTTPResponse(status: status, data: data)
        } catch {
            throw ProviderError.network(error.localizedDescription)
        }
    }

    /// Maps common status codes to ProviderError and returns the body on 2xx.
    static func json(_ url: URL, method: String = "GET", headers: [String: String] = [:], body: Data? = nil) async throws -> Data {
        let resp = try await request(url, method: method, headers: headers, body: body)
        switch resp.status {
        case 200...299: return resp.data
        case 401, 403: throw ProviderError.tokenExpired
        case 429: throw ProviderError.rateLimited
        default:
            let snippet = String(data: resp.data.prefix(200), encoding: .utf8) ?? ""
            throw ProviderError.badResponse("HTTP \(resp.status) \(snippet)")
        }
    }
}
