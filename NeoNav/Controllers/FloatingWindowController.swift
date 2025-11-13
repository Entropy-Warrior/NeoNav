/// FloatingWindowController.swift
/// Controller for managing the floating bookmark strip window.
/// Handles window configuration, position persistence, and dynamic sizing.

import AppKit
import SwiftUI

/// Custom window that stays on top without becoming key
class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func makeKey() {
        // Prevent window from becoming key
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        orderFront(sender)
    }
}

class FloatingWindowController: NSWindowController {
    private let itemWidth: CGFloat = 70
    private let itemSpacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 26
    private let maxItemsPerRow: Int = 8
    private let defaults = UserDefaults.standard

    init(rootView: some View, bookmarkCount: Int) {
        let window = FloatingWindow(
            contentRect: .zero,
            styleMask: [
                .borderless,
                .resizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.hasShadow = true
        window.acceptsMouseMovedEvents = true

        let dragHandleWidth: CGFloat = 28
        let minWidth = itemWidth + dragHandleWidth + 4
        let minHeight = itemWidth + 20
        window.minSize = NSSize(width: minWidth, height: minHeight)

        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = true

        let hostingView = NSHostingView(rootView: rootView)
        window.contentView = hostingView

        super.init(window: window)

        updateWindowSize(bookmarkCount: bookmarkCount)
        setupWindowTracking()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindowTracking() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
    }

    @objc private func windowDidMove(_: Notification) {
        guard let window else { return }
        let frame = window.frame
        defaults.set(frame.origin.x, forKey: "FloatingWindow.x")
        defaults.set(frame.origin.y, forKey: "FloatingWindow.y")
    }

    func updateBookmarkCount(_ count: Int) {
        updateWindowSize(bookmarkCount: count)
    }

    private func updateWindowSize(bookmarkCount: Int) {
        guard let window else { return }

        let itemsPerRow = min(maxItemsPerRow, max(1, bookmarkCount))
        let rows = ceil(Double(bookmarkCount) / Double(maxItemsPerRow))

        let width = (itemWidth * CGFloat(itemsPerRow)) + (itemSpacing * CGFloat(itemsPerRow - 1)) + horizontalPadding
        let height = (itemWidth * CGFloat(rows)) + (itemSpacing * CGFloat(rows - 1)) + verticalPadding

        let currentOrigin = window.frame.origin
        let newFrame = NSRect(
            x: currentOrigin.x,
            y: currentOrigin.y,
            width: max(width, window.minSize.width),
            height: max(height, window.minSize.height)
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        guard let window else { return }

        if let savedX = defaults.object(forKey: "FloatingWindow.x") as? CGFloat,
           let savedY = defaults.object(forKey: "FloatingWindow.y") as? CGFloat
        {
            let savedPoint = NSPoint(x: savedX, y: savedY)

            if NSScreen.screens.contains(where: { screen in
                screen.frame.contains(savedPoint) || screen.visibleFrame.contains(savedPoint)
            }) {
                window.setFrameOrigin(savedPoint)
            } else {
                resetToDefaultPosition(window)
            }
        } else {
            resetToDefaultPosition(window)
        }
    }

    private func resetToDefaultPosition(_ window: NSWindow) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.maxY - windowFrame.height - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
