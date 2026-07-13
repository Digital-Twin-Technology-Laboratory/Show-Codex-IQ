import AppKit
import ShowCodexIQCore
import SwiftUI

struct DashboardView: View {
    @Bindable var appModel: AppModel

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if appModel.snapshot == nil, !appModel.isInitialLoading {
                RadarEmptyStateView(appModel: appModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        StatusHeaderView(appModel: appModel)

                        if let error = appModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                        }

                        LazyVGrid(columns: columns, spacing: 10) {
                            RankingSection(metric: .iq, rankings: appModel.rankings(for: .iq))
                            RankingSection(metric: .cost, rankings: appModel.rankings(for: .cost))
                            RankingSection(metric: .duration, rankings: appModel.rankings(for: .duration))
                            RankingSection(metric: .overall, rankings: appModel.rankings(for: .overall))
                        }

                        TrendChartView(appModel: appModel)
                    }
                    .padding(14)
                }
            }

            Divider()
            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 430, height: 680)
        .background(.ultraThinMaterial)
        .task { await appModel.start() }
        .onAppear {
            Task { await appModel.refreshIfNeeded() }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Link(destination: AppMetadata.radarURL) {
                Label("数据来自 Codex 雷达 codexradar.com", systemImage: "link")
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .help("设置")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .help("退出 Show Codex IQ")
        }
        .buttonStyle(.borderless)
    }
}
