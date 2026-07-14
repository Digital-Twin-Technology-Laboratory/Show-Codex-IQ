import AppKit
import ShowCodexIQCore
import SwiftUI

struct DashboardView: View {
    @Bindable var appModel: AppModel
    @Bindable var layoutState: DashboardLayoutState
    @StateObject private var interaction = DashboardInteractionState()
    @State private var measuredContentHeight: CGFloat = 0
    @State private var measuredFooterHeight: CGFloat = 0
    @Namespace private var rankingNamespace
    let onPreferredHeightChange: (CGFloat) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    init(
        appModel: AppModel,
        layoutState: DashboardLayoutState = DashboardLayoutState(),
        initiallyExpandedMetric: RankingMetric? = nil,
        onPreferredHeightChange: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.appModel = appModel
        self.layoutState = layoutState
        self.onPreferredHeightChange = onPreferredHeightChange
        _interaction = StateObject(
            wrappedValue: DashboardInteractionState(expandedMetric: initiallyExpandedMetric)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                dashboardContent
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: DashboardContentHeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
            }
            .scrollIndicators(isContentClipped ? .automatic : .hidden)

            Divider()
            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: DashboardFooterHeightPreferenceKey.self,
                            value: geometry.size.height
                        )
                    }
                }
        }
        .frame(width: DashboardLayout.width, height: resolvedHeight)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [.blue.opacity(0.045), .purple.opacity(0.035), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .task { await appModel.start() }
        .onAppear {
            Task { await appModel.refreshIfNeeded() }
        }
        .onPreferenceChange(DashboardContentHeightPreferenceKey.self) { height in
            measuredContentHeight = height
        }
        .onPreferenceChange(DashboardFooterHeightPreferenceKey.self) { height in
            measuredFooterHeight = height
        }
        .onChange(of: resolvedHeight, initial: true) { _, height in
            onPreferredHeightChange(height)
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        if appModel.snapshot == nil, !appModel.isInitialLoading {
            RadarEmptyStateView(appModel: appModel)
                .frame(maxWidth: .infinity, minHeight: DashboardLayout.emptyContentHeight)
                .padding(14)
        } else {
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

                rankingCards

                if appModel.settings.showsTrendChart {
                    TrendChartView(appModel: appModel)
                }
            }
            .padding(14)
        }
    }

    private var idealHeight: CGFloat {
        measuredContentHeight + measuredFooterHeight + 1
    }

    private var resolvedHeight: CGFloat {
        min(
            layoutState.maximumHeight,
            max(DashboardLayout.minimumHeight, idealHeight)
        )
    }

    private var isContentClipped: Bool {
        idealHeight > layoutState.maximumHeight + 0.5
    }

    @ViewBuilder
    private var rankingCards: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                rankingLayout
            }
        } else {
            rankingLayout
        }
    }

    @ViewBuilder
    private var rankingLayout: some View {
        if let expandedMetric = interaction.expandedMetric {
            VStack(spacing: 10) {
                rankingSection(for: expandedMetric, presentation: .expanded)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(RankingMetric.allCases.filter { $0 != expandedMetric }) { metric in
                        rankingSection(for: metric, presentation: .compact)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(RankingMetric.allCases) { metric in
                    rankingSection(for: metric, presentation: .standard)
                }
            }
        }
    }

    private func rankingSection(
        for metric: RankingMetric,
        presentation: RankingSectionPresentation
    ) -> some View {
        RankingSection(
            metric: metric,
            rankings: appModel.rankings(for: metric),
            presentation: presentation,
            namespace: rankingNamespace,
            onExpand: {
                withAnimation(.snappy(duration: 0.34, extraBounce: 0.04)) {
                    interaction.expandedMetric = metric
                }
            },
            onCollapse: {
                withAnimation(.snappy(duration: 0.30, extraBounce: 0.02)) {
                    interaction.expandedMetric = nil
                }
            }
        )
        .matchedGeometryEffect(id: metric.rawValue, in: rankingNamespace)
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
            .adaptiveGlassIconStyle()
            .controlSize(.small)
            .help("设置")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .adaptiveGlassIconStyle()
            .controlSize(.small)
            .help("退出 Show Codex IQ")
        }
    }
}

private struct DashboardContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct DashboardFooterHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@MainActor
private final class DashboardInteractionState: ObservableObject {
    @Published var expandedMetric: RankingMetric?

    init(expandedMetric: RankingMetric? = nil) {
        self.expandedMetric = expandedMetric
    }
}
