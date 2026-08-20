import AppKit
import QuartzCore
import SwiftUI

final class EdgePanelController {
    static let collapsedWidth: CGFloat = 14
    static let expandedWidth: CGFloat = 320
    static let verticalInset: CGFloat = 80

    private let store: TodoStore
    private var panel: NSPanel!
    private var hostingView: NSHostingView<TodoPanelView>!
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    init(store: TodoStore) {
        self.store = store
        buildPanel()
        observeScreenChanges()
        startMouseMonitor()
        collapse(animated: false)
    }

    deinit {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func show() {
        position(expanded: isExpanded)
        panel.orderFrontRegardless()
    }

    private func buildPanel() {
        let style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.collapsedWidth, height: 400),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.animationBehavior = .utilityWindow

        let root = TodoPanelView(store: store, isExpanded: Binding(
            get: { [weak self] in self?.isExpanded ?? false },
            set: { [weak self] value in
                guard let self else { return }
                if value {
                    self.expand()
                } else {
                    self.collapse(animated: true)
                }
            }
        ))
        hostingView = NSHostingView(rootView: root)
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.position(expanded: self?.isExpanded ?? false)
        }
    }

    private func startMouseMonitor() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.handleMouseLocation(NSEvent.mouseLocation)
        }
        // Also track while over our own panel (global monitor skips events delivered to this app).
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.handleMouseLocation(NSEvent.mouseLocation)
            return event
        }
    }

    private func handleMouseLocation(_ point: NSPoint) {
        guard let screen = NSScreen.main else { return }
        let frame = panel.frame
        let hitPad: CGFloat = isExpanded ? 0 : 6
        let hitRect = frame.insetBy(dx: -hitPad, dy: -hitPad)
        // Only react near the right edge strip / panel so we don't expand on random cursor travel.
        let nearRightEdge = point.x >= screen.frame.maxX - (isExpanded ? Self.expandedWidth + 24 : 28)

        if hitRect.contains(point) || (nearRightEdge && abs(point.y - frame.midY) < frame.height / 2 + 20) {
            cancelCollapse()
            if !isExpanded {
                expand()
            }
        } else if isExpanded {
            scheduleCollapse()
        }
    }

    private func expand() {
        cancelCollapse()
        guard !isExpanded else {
            position(expanded: true)
            return
        }
        isExpanded = true
        refreshRoot()
        position(expanded: true, animated: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func collapse(animated: Bool) {
        cancelCollapse()
        isExpanded = false
        refreshRoot()
        position(expanded: false, animated: animated)
    }

    private func scheduleCollapse() {
        guard collapseWorkItem == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.collapse(animated: true)
            self?.collapseWorkItem = nil
        }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func cancelCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    private func refreshRoot() {
        hostingView.rootView = TodoPanelView(store: store, isExpanded: Binding(
            get: { [weak self] in self?.isExpanded ?? false },
            set: { [weak self] value in
                guard let self else { return }
                if value {
                    self.expand()
                } else {
                    self.collapse(animated: true)
                }
            }
        ))
    }

    private func position(expanded: Bool, animated: Bool = false) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let width = expanded ? Self.expandedWidth : Self.collapsedWidth
        let height = max(280, visible.height - Self.verticalInset * 2)
        let x = visible.maxX - width
        let y = visible.minY + (visible.height - height) / 2
        let target = NSRect(x: x, y: y, width: width, height: height)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(target, display: true)
            }
        } else {
            panel.setFrame(target, display: true)
        }
    }
}
