import Foundation

public struct ResetCreditSummary: Codable, Hashable, Identifiable, Sendable {
    public let sequence: Int
    public let status: String
    public let grantedAt: Date?
    public let expiresAt: Date?

    public var id: String { "reset-credit-\(sequence)" }

    public var isAvailable: Bool { status.caseInsensitiveCompare("available") == .orderedSame }

    public init(
        sequence: Int,
        status: String,
        grantedAt: Date?,
        expiresAt: Date?
    ) {
        self.sequence = sequence
        self.status = status
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
    }
}

public struct ResetCreditsSnapshot: Codable, Hashable, Sendable {
    public let availableCount: Int
    public let credits: [ResetCreditSummary]
    public let fetchedAt: Date

    public init(availableCount: Int, credits: [ResetCreditSummary], fetchedAt: Date) {
        self.availableCount = max(0, availableCount)
        self.credits = credits.sorted {
            if $0.isAvailable != $1.isAvailable { return $0.isAvailable }
            switch ($0.expiresAt, $1.expiresAt) {
            case let (lhs?, rhs?) where lhs != rhs: return lhs < rhs
            case (_?, nil): return true
            case (nil, _?): return false
            default: return $0.id < $1.id
            }
        }
        self.fetchedAt = fetchedAt
    }

    public var availableCredits: [ResetCreditSummary] {
        credits.filter(\.isAvailable)
    }

    public var nearestExpiration: Date? {
        availableCredits.compactMap(\.expiresAt).min()
    }
}

public protocol AccountRateLimitsReading: Sendable {
    func readResetCredits() async throws -> ResetCreditsSnapshot
}
