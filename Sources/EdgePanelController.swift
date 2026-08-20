import AppKit
import QuartzCore
import SwiftUI

/// NSPanel that can accept keyboard focus (needed for the todo TextField).
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class EdgePanelController: NSObject {
    /// Invisible edge hit-zone when collapsed (no visible strip).
    static let collapsedWidth: CGFloat = 3
    static let expandedWidth: CGFloat = 312
    static let panelHeight: CGFloat = 400
    /// Apple-like springy slide — same curve both ways.
    static let slideDuration: CFTimeInterval = 0.44
    static let collapseGrace: TimeInterval = 0.1

    private let store: TodoStore
    private var panel: KeyablePanel!
    private var hostingView: NSHostingView<TodoPanelView>!
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var screenObserver: NSObjectProtocol?
    private var isPointerInside = false

    init(store: TodoStore) {
        self.store = store
        super.init()
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
        position(expanded: isExpanded, animated: false)
        panel.orderFrontRegardless()
    }

    func openAndFocus() {
        expand(activate: true)
    }

    private func buildPanel() {
        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.collapsedWidth, height: 400),
            styleMask: [.borderless, .fullSizeContentView],
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
        panel.animationBehavior = .none
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.appearance = NSAppearance(named: .darkAqua)

        hostingView = NSHostingView(rootView: makeRoot())
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
    }

    private func makeRoot() -> TodoPanelView {
        TodoPanelView(store: store, isExpanded: isExpanded)
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.position(expanded: self.isExpanded, animated: false)
        }
    }

    private func startMouseMonitor() {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.handleMouseLocation(NSEvent.mouseLocation)
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]) { [weak self] event in
            self?.handleMouseLocation(NSEvent.mouseLocation)
            return event
        }
    }

    private func handleMouseLocation(_ point: NSPoint) {
        let frame = panel.frame
        let hitPad: CGFloat = isExpanded ? 10 : 8
        let hitRect = frame.insetBy(dx: -hitPad, dy: -hitPad)
        let inside = hitRect.contains(point)

        let screen = screenContaining(point) ?? panel.screen ?? NSScreen.main
        let nearRightEdge: Bool = {
            guard let screen else { return false }
            let onThisScreen = screen.frame.contains(point)
            let closeToEdge = point.x >= screen.frame.maxX - 8
            let withinPanelHeight = point.y >= frame.minY - 16 && point.y <= frame.maxY + 16
            return onThisScreen && closeToEdge && withinPanelHeight
        }()

        let wasInside = isPointerInside
        isPointerInside = inside || nearRightEdge

        if isPointerInside {
            cancelCollapse()
            if !isExpanded {
                expand(activate: false)
            }
        } else if isExpanded && wasInside {
            scheduleCollapse()
        } else if isExpanded && !isPointerInside {
            scheduleCollapse()
        }
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    private func expand(activate: Bool) {
        cancelCollapse()
        let wasExpanded = isExpanded
        isExpanded = true
        refreshRoot()
        position(expanded: true, animated: !wasExpanded)

        if activate {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func collapse(animated: Bool) {
        cancelCollapse()
        guard isExpanded || animated == false else { return }
        isExpanded = false
        isPointerInside = false
        refreshRoot()
        if panel.isKeyWindow {
            panel.resignKey()
        }
        position(expanded: false, animated: animated)
    }

    private func scheduleCollapse() {
        guard collapseWorkItem == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.collapseWorkItem = nil
            guard !self.isPointerInside, self.isExpanded else { return }
            self.collapse(animated: true)
        }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.collapseGrace, execute: work)
    }

    private func cancelCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    private func refreshRoot() {
        hostingView.rootView = makeRoot()
    }

    private func position(expanded: Bool, animated: Bool = false) {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        let visible = screen.visibleFrame
        let width = expanded ? Self.expandedWidth : Self.collapsedWidth
        let height = min(Self.panelHeight, visible.height - 48)
        let x = visible.maxX - width
        let y = visible.minY + (visible.height - height) / 2
        let target = NSRect(x: x, y: y, width: width, height: height)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Self.slideDuration
                // Smooth decelerate — feels like macOS Continuity / Control Center.
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                panel.animator().setFrame(target, display: true)
            }
        } else {
            panel.setFrame(target, display: true)
        }
    }
}
