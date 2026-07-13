import ShowCodexIQCore
import SwiftUI

struct MenuBarLabel: View {
    @Bindable var appModel: AppModel

    var body: some View {
        if appModel.menuBarRanking.count == 2 {
            HStack(spacing: 4) {
                Image(systemName: appModel.settings.menuBarMetric.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(appModel.menuBarRanking) { ranked in
                        HStack(spacing: 3) {
                            Text("#\(ranked.position) \(MetricFormatter.compactModelName(ranked.benchmark.label))")
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Spacer(minLength: 2)
                            Text(MetricFormatter.menuBarValue(ranked.value, metric: ranked.metric))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(nsColor: .labelColor))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        } else if appModel.isInitialLoading || appModel.isRefreshing {
            Label("正在刷新", systemImage: "brain.head.profile")
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("正在刷新 Codex 模型数据")
        } else {
            Label("数据不可用", systemImage: "exclamationmark.triangle")
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
