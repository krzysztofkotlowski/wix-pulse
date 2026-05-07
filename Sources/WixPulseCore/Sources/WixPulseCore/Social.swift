import Foundation
import os.log

/// One tracked social profile (Instagram for now; structured to add Twitter/X,
/// TikTok, YouTube later without UI changes).
public struct SocialAccount: Codable, Hashable, Identifiable, Sendable {
    public enum Platform: String, Codable, CaseIterable, Sendable {
        case instagram

        public var displayName: String {
            switch self {
            case .instagram: return "Instagram"
            }
        }
        public var icon: String {
            switch self {
            case .instagram: return "camera.fill"
            }
        }
        public var profileURL: (String) -> URL? {
            switch self {
            case .instagram: return { handle in URL(string: "https://www.instagram.com/\(handle)/") }
            }
        }
    }

    public let platform: Platform
    public let handle: String                         // without leading "@"
    public var followerCount: Int                     // current count
    public var lastUpdated: Date
    public var history: [DailySnapshot]               // chronological, oldest first
    public var fetchSource: FetchSource

    public enum FetchSource: String, Codable, Sendable {
        case auto, manual
    }

    public struct DailySnapshot: Codable, Hashable, Identifiable, Sendable {
        public var id: Date { date }
        public let date: Date
        public let count: Int
        public init(date: Date, count: Int) { self.date = date; self.count = count }
    }

    public var id: String { platform.rawValue + ":" + handle.lowercased() }

    public init(platform: Platform, handle: String, followerCount: Int = 0,
                lastUpdated: Date = Date(), history: [DailySnapshot] = [],
                fetchSource: FetchSource = .manual) {
        self.platform = platform
        self.handle = handle.trimmingCharacters(in: CharacterSet(charactersIn: "@ "))
        self.followerCount = followerCount
        self.lastUpdated = lastUpdated
        self.history = history
        self.fetchSource = fetchSource
    }

    /// Day-over-day delta — how many followers gained (or lost) since the
    /// previous snapshot. Returns nil if history has fewer than 2 entries.
    public var dayOverDayChange: Int? {
        guard history.count >= 2 else { return nil }
        return history.last!.count - history[history.count - 2].count
    }

    /// 7-day delta if we have ≥7 history entries.
    public var weekOverWeekChange: Int? {
        guard history.count >= 8 else { return nil }
        return history.last!.count - history[history.count - 8].count
    }

    /// Append today's count, replacing any prior snapshot for the same calendar
    /// day. Trims history to the last 90 days.
    public mutating func recordSnapshot(count: Int, on date: Date = Date()) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        var trimmed = history.filter { !cal.isDate($0.date, inSameDayAs: day) }
        trimmed.append(DailySnapshot(date: day, count: count))
        let cutoff = cal.date(byAdding: .day, value: -90, to: day) ?? day
        trimmed = trimmed.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
        history = trimmed
        followerCount = count
        lastUpdated = date
    }
}

/// Best-effort fetcher for follower counts. Each platform has its own quirks.
/// For Instagram in 2026, the public endpoints are heavily rate-limited and
/// often require login — so this is genuinely best-effort. Failures return
/// nil; the user can fall back to manual entry in Settings.
public enum SocialFetcher {
    public static func fetchFollowerCount(for account: SocialAccount, session: URLSession = .shared) async -> Int? {
        switch account.platform {
        case .instagram:
            return await fetchInstagram(handle: account.handle, session: session)
        }
    }

    // MARK: - Instagram

    private static func fetchInstagram(handle: String, session: URLSession) async -> Int? {
        // Try Instagram's web profile info endpoint. Requires a browser-like
        // User-Agent and the public app ID header. Often returns 401 without
        // a session cookie, but works for many public accounts when scraped
        // sparingly.
        let safeHandle = handle.trimmingCharacters(in: CharacterSet(charactersIn: "@/ "))
        guard !safeHandle.isEmpty,
              let url = URL(string: "https://i.instagram.com/api/v1/users/web_profile_info/?username=\(safeHandle)")
        else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("936619743392459", forHTTPHeaderField: "X-IG-App-ID")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                os_log("Instagram fetch HTTP %{public}d for handle %{public}@", (response as? HTTPURLResponse)?.statusCode ?? -1, safeHandle)
                return nil
            }
            let envelope = try JSONDecoder().decode(InstagramEnvelope.self, from: data)
            return envelope.data?.user?.edge_followed_by?.count
        } catch {
            os_log("Instagram fetch failed for %{public}@: %{public}@", safeHandle, error.localizedDescription)
            return nil
        }
    }

    private struct InstagramEnvelope: Decodable {
        let data: DataField?
        struct DataField: Decodable {
            let user: User?
            struct User: Decodable {
                let edge_followed_by: EdgeCount?
                struct EdgeCount: Decodable { let count: Int }
            }
        }
    }
}
