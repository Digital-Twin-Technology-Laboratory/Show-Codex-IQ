import ShowCodexIQCore
import SwiftUI

struct MenuBarLabel: View {
    @Bindable var appModel: AppModel

    var body: some View {
        if appModel.menuBarRanking.count == 2 {
            VStack(alignment: .leading, spacing: -1) {
                ForEach(appModel.menuBarRanking) { ranked in
                    HStack(spacing: 3) {
                        Text("\(ranked.position)")
                            .foregroundStyle(.secondary)
                        Text(MetricFormatter.compactModelName(ranked.benchmark.label))
                            .lineLimit(1)
                        Text(MetricFormatter.menuBarValue(ranked.value, metric: ranked.metric))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        } else if appModel.isInitialLoading || appModel.isRefreshing {
            Label("Codex IQ", systemImage: "brain.head.profile")
                .accessibilityLabel("正在刷新 Codex 模型数据")
        } else {
            Label("Codex IQ !", systemImage: "exclamationmark.triangle")
                .accessibilityLabel("Codex 模型数据不可用")
        }
    }

    private var accessibilitySummary: String {
        appModel.menuBarRanking.map { ranked in
            "第 \(ranked.position) 名 \(ranked.benchmark.label) \(MetricFormatter.detailValue(ranked.value, metric: ranked.metric))"
        }
        .joined(separator: "，")
    }
}
