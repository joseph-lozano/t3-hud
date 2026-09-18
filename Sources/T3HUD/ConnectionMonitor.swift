import Foundation

/// Checks reachability without loading or replacing T3's document and drafts.
final class ConnectionMonitor {
    private var timer: Timer?
    private var task: URLSessionDataTask?
    private var generation = UUID()
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3
        config.urlCache = nil
        config.httpCookieStorage = nil
        return URLSession(configuration: config)
    }()

    func start(url: URL, changed: @escaping (Bool) -> Void) {
        stop()
        let current = generation
        func probe() {
            guard task == nil else { return }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.httpMethod = "HEAD"
            task = session.dataTask(with: request) { [weak self] _, response, error in
                DispatchQueue.main.async {
                    guard let self, self.generation == current else { return }
                    self.task = nil
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    // An auth challenge still establishes a reachable server.
                    changed(error == nil && (200..<500).contains(status))
                }
            }
            task?.resume()
        }
        probe()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in probe() }
    }

    func stop() {
        generation = UUID()
        timer?.invalidate(); timer = nil
        task?.cancel(); task = nil
    }

    deinit { stop(); session.invalidateAndCancel() }
}
