import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel
    @State private var page: SettingsPage = .root

    var body: some View {
        Group {
            switch page {
            case .root:
                rootSettings
            case .menuBarAliases:
                MenuBarAliasesSettingsView(
                    appModel: appModel,
                    onBack: { page = .root }
                )
            }
        }
        .frame(width: 620, height: 560)
    }

    private var rootSettings: some View {
        TabView {
            GeneralDashboardSettingsView(appModel: appModel)
                .tabItem {
                    Label("通用&看板", systemImage: "slider.horizontal.3")
                }

            ModelRadarSettingsView(
                appModel: appModel,
                onOpenMenuBarAliases: { page = .menuBarAliases }
            )
            .tabItem {
                Label("智商显示", systemImage: "brain.head.profile")
            }

            TokenUsageSettingsView(appModel: appModel)
                .tabItem {
                    Label("Token 用量", systemImage: "chart.bar.xaxis")
            }

            ResetCreditsSettingsView(appModel: appModel)
                .tabItem {
                    Label("重置卡", systemImage: "arrow.clockwise.circle")
                }

            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
    }
}

private enum SettingsPage {
    case root
    case menuBarAliases
}
