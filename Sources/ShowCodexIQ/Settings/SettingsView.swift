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
        .frame(width: 540, height: 500)
    }

    private var rootSettings: some View {
        TabView {
            GeneralSettingsView(
                appModel: appModel,
                onOpenMenuBarAliases: { page = .menuBarAliases }
            )
            .tabItem {
                Label("通用", systemImage: "gearshape")
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
