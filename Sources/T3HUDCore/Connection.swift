import Foundation

/// The URL to load now, and the credential-free address to reopen next launch.
public struct Connection {
    public let requestURL: URL
    public let savedURL: URL

    public init?(_ input: String) {
        guard var parts = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = parts.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              let request = parts.url else { return nil }
        requestURL = request
        parts.query = nil
        parts.fragment = nil
        // T3's pairing page must not become the next launch's destination.
        if parts.path == "/pair" || parts.path == "/pair/" { parts.path = "/" }
        guard let saved = parts.url else { return nil }
        savedURL = saved
    }
}
