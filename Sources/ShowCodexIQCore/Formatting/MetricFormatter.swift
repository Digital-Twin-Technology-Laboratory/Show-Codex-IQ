import Foundation

public enum MetricFormatter {
    public static func benchmarkDateLabel(_ dateKey: String) -> String {
        let value = dateKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 10 else { return dateKey }

        let dateEnd = value.index(value.startIndex, offsetBy: 10)
        let date = String(value[..<dateEnd])
        guard isCalendarDate(date) else { return dateKey }

        let remainder = value[dateEnd...]
        guard let separator = remainder.first else { return date }

        if separator == "T" || separator == "t" || separator == " " {
            let hourText = remainder.dropFirst().prefix(2)
            guard hourText.count == 2,
                  let hour = Int(hourText),
                  (0..<24).contains(hour) else {
                return date
            }
            return "\(date) · \(hour < 12 ? "AM" : "PM")"
        }

        if separator == "-" {
            let session = remainder
                .dropFirst()
                .split(whereSeparator: { $0 == "_" || $0 == "-" })
                .first?
                .uppercased()
            if let session, ["AM", "PM"].contains(session) {
                return "\(date) · \(session)"
            }
        }

        return date
    }

    public static func detailValue(_ value: Double, metric: RankingMetric) -> String {
        switch metric {
        case .iq:
            formatNumber(value, maximumFractionDigits: value.rounded() == value ? 0 : 1)
        case .cost:
            "$" + formatNumber(value, minimumFractionDigits: 2, maximumFractionDigits: 2)
        case .duration:
            detailDuration(value)
        case .overall:
            formatNumber(value, minimumFractionDigits: 1, maximumFractionDigits: 1)
        }
    }

    public static func menuBarValue(_ value: Double, metric: RankingMetric) -> String {
        switch metric {
        case .duration:
            if value < 3_600 {
                return "\(Int((value / 60).rounded()))m"
            }
            return formatNumber(value / 3_600, maximumFractionDigits: 1) + "h"
        default:
            return detailValue(value, metric: metric)
        }
    }

    public static func compactModelName(_ label: String) -> String {
        label
            .replacingOccurrences(of: "GPT-", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: " medium", with: " med")
            .replacingOccurrences(of: " xhigh", with: " xh")
            .replacingOccurrences(of: " high", with: " hi")
            .replacingOccurrences(of: " low", with: " lo")
            .replacingOccurrences(of: " max", with: " max")
    }

    private static func detailDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds.rounded())) 秒"
        }
        if seconds < 3_600 {
            return "\(Int((seconds / 60).rounded())) 分钟"
        }
        let hours = Int(seconds) / 3_600
        let minutes = (Int(seconds) % 3_600) / 60
        return minutes == 0 ? "\(hours) 小时" : "\(hours) 小时 \(minutes) 分"
    }

    private static func isCalendarDate(_ value: String) -> Bool {
        guard value.count == 10 else { return false }
        for (offset, character) in value.enumerated() {
            if offset == 4 || offset == 7 {
                guard character == "-" else { return false }
            } else {
                guard character.isNumber else { return false }
            }
        }
        return true
    }

    private static func formatNumber(
        _ value: Double,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.roundingMode = .halfUp
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
