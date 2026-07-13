import ShowCodexIQCore
import SwiftUI

struct RankingSection: View {
    let metric: RankingMetric
    let rankings: [RankedModel]

    var body: some View {
        GroupBox {
            VStack(spacing: 7) {
                ForEach(Array(rankings.prefix(3))) { ranked in
                    RankRow(ranked: ranked)
                    if ranked.id != rankings.prefix(3).last?.id {
                        Divider()
                    }
                }
                if rankings.isEmpty {
                    Text("暂无可用数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                }
            }
            .frame(minHeight: 88, alignment: .top)
        } label: {
            Label(metric.rankingTitle, systemImage: metric.systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(metric.tint)
        }
        .groupBoxStyle(RankingGroupBoxStyle(tint: metric.tint))
    }
}

private struct RankingGroupBoxStyle: GroupBoxStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            configuration.label
            configuration.content
        }
        .padding(11)
        .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        }
    }
}
