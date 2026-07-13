import SwiftUI

struct SettingsView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(appModel: appModel)
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 540, height: 500)
    }
}
