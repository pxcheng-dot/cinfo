//
//  RemoteDataService.swift
//  cinfo
//
//  Lightweight background updater for universities.csv.
//
//  How it works
//  ────────────
//  1. On app launch, checks whether ≥ 7 days have passed since the last fetch.
//  2. If so, sends a conditional GET (If-None-Match / ETag) to the remote URL.
//     • 304 Not Modified → nothing downloaded, just stamps the timestamp.
//     • 200 OK           → saves the new CSV to Documents, reloads college data,
//                          and posts a .rankingDataRefreshed notification.
//  3. The rest of the app observes that notification and refreshes its state.
//
//  Energy-saving choices
//  ─────────────────────
//  • Only one network call per week, conditional on ETag → almost always 304.
//  • Uses URLSession.shared (no background-session daemon; tied to app-active time).
//  • Task quality-of-service is .utility (below user-interactive).
//  • No polling, no timers, no background-app-refresh entitlement needed.
//
//  Setup (one-time)
//  ────────────────
//  Host your universities.csv somewhere static and set `remoteCSVURL` below.
//  A GitHub raw URL is free and works perfectly:
//    https://raw.githubusercontent.com/<user>/<repo>/main/cinfo/universities.csv
//

import Foundation

extension Notification.Name {
    /// Posted on the main thread after new ranking data has been saved to disk.
    static let rankingDataRefreshed = Notification.Name("rankingDataRefreshed")
}

final class RemoteDataService {

    static let shared = RemoteDataService()

    // ── Configuration ──────────────────────────────────────────────────────
    //  Replace this URL with the raw URL of your hosted universities.csv.
    //  Example (GitHub):
    //    https://raw.githubusercontent.com/yourname/cinfo-data/main/universities.csv
    private static let remoteCSVURL = URL(
        string: "https://raw.githubusercontent.com/pxcheng-dot/cinfo/main/cinfo/universities.csv"
    )!

    /// Minimum time between fetches (seconds). Default: 7 days.
    private static let fetchIntervalSeconds: TimeInterval = 7 * 24 * 60 * 60

    // ── UserDefaults keys ──────────────────────────────────────────────────
    private let lastFetchKey = "remoteDataLastFetch"
    private let etagKey      = "remoteDataETag"

    // ── Public ─────────────────────────────────────────────────────────────

    /// Call once from `cinfoApp.init` or `cinfoApp.body`.
    /// Returns immediately; all network I/O happens on a background thread.
    func fetchIfNeeded() {
        let lastFetch = UserDefaults.standard.double(forKey: lastFetchKey)
        let elapsed   = Date().timeIntervalSince1970 - lastFetch
        guard elapsed >= Self.fetchIntervalSeconds else { return }

        Task(priority: .utility) { await fetch() }
    }

    /// Force a fetch regardless of the last-fetch timestamp (e.g. pull-to-refresh).
    func forceFetch() {
        Task(priority: .utility) { await fetch() }
    }

    // ── Private ────────────────────────────────────────────────────────────

    private func fetch() async {
        var request = URLRequest(url: Self.remoteCSVURL,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 20)
        request.setValue("text/csv", forHTTPHeaderField: "Accept")

        // Conditional request: only download if the file has changed.
        if let etag = UserDefaults.standard.string(forKey: etagKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }

            // Always update the timestamp so we don't hammer the server.
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchKey)

            switch http.statusCode {
            case 304:
                // Not modified — nothing to do.
                return

            case 200:
                guard let csv = String(data: data, encoding: .utf8),
                      isValidCSV(csv) else { return }

                // Cache ETag for future conditional requests.
                if let etag = http.value(forHTTPHeaderField: "ETag") {
                    UserDefaults.standard.set(etag, forKey: etagKey)
                }

                // Write to Documents so DataLoader picks it up next load.
                try csv.write(to: DataLoader.cacheURL,
                              atomically: true, encoding: .utf8)

                // Notify the app on the main thread.
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .rankingDataRefreshed, object: nil)
                }

            default:
                break   // Non-fatal; will retry next week.
            }
        } catch {
            // Network unavailable, timeout, etc. — silent fail, retry next week.
        }
    }

    /// Sanity-check: the downloaded text must look like our CSV (has the header row).
    private func isValidCSV(_ text: String) -> Bool {
        text.hasPrefix("\"name\"") || text.hasPrefix("name,")
    }
}
