import SwiftUI
import ShowCodexIQCore

@main
struct ShowCodexIQApp: App {
    private let appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            VStack(spacing: 12) {
                HStack {
                    Label("Show Codex IQ", systemImage: "brain.head.profile")
                        .font(.headline)
                    Spacer()
                    if appModel.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                Text("详细榜单与趋势图正在构建。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("立即刷新") {
                    Task { await appModel.refresh() }
                }
                .disabled(appModel.isRefreshing)
            }
            .padding()
            .frame(width: 360)
            .task { await appModel.start() }
        } label: {
            MenuBarLabel(appModel: appModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            VStack(alignment: .leading, spacing: 10) {
                Text("Show Codex IQ")
                    .font(.title2.bold())
                Text("设置界面正在构建。")
                    .foregroundStyle(.secondary)
            }
                .padding(24)
        }
    }
}
