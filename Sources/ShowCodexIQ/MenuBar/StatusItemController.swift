import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let statusView: MenuBarStatusView
    private let popover: NSPopover

    init(appModel: AppModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = MenuBarStatusView(appModel: appModel)
        popover = NSPopover()
        super.init()

        configureStatusItem()
        configurePopover(appModel: appModel)
    }

    private func configureStatusItem() {
        statusView.onClick = { [weak self] in
            self?.togglePopover()
        }
        statusItem.view = statusView
        statusItem.length = statusView.intrinsicContentSize.width
    }

    private func configurePopover(appModel: AppModel) {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 430, height: 680)
        popover.contentViewController = NSHostingController(
            rootView: DashboardView(appModel: appModel)
        )
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: statusView.bounds, of: statusView, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

@MainActor
private final class MenuBarStatusView: NSView {
    var onClick: (() -> Void)?

    init(appModel: AppModel) {
        super.init(frame: NSRect(x: 0, y: 0, width: 128, height: 22))

        let hostingView = NSHostingView(
            rootView: MenuBarLabel(appModel: appModel)
                .frame(width: 128, height: 22)
                .contentShape(Rectangle())
                .allowsHitTesting(false)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Show Codex IQ 模型排名")
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 128, height: 22)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
