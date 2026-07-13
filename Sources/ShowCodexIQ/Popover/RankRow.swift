import ShowCodexIQCore
import SwiftUI

struct RankRow: View {
    let ranked: RankedModel

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(medalColor.opacity(0.16))
                Text("\(ranked.position)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(medalColor)
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(ranked.benchmark.label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(statusText)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(MetricFormatter.detailValue(ranked.value, metric: ranked.metric))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ranked.metric.tint)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "第 \(ranked.position) 名，\(ranked.benchmark.label)，\(MetricFormatter.detailValue(ranked.value, metric: ranked.metric))"
        )
    }

    private var medalColor: Color {
        switch ranked.position {
        case 1: .yellow
        case 2: .gray
        case 3: .orange
        default: .secondary
        }
    }

    private var statusText: String {
        if ranked.metric == .overall {
            return "加权百分位"
        }
        guard let latest = ranked.benchmark.latest else { return "暂无详细数据" }
        if let passed = latest.passed, let tasks = latest.tasks {
            return "\(passed)/\(tasks) 项通过"
        }
        return ranked.benchmark.reasoningEffort
    }
}
