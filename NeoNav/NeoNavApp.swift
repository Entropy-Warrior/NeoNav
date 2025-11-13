/// NeoNavApp.swift
/// Main application entry point and window management.
/// Manages app lifecycle, window configuration, and floating bookmark strip.

import AppKit
import SwiftUI

/// Main entry point for NeoNav app.
@main
struct NeoNavApp: App {
    @StateObject private var viewModel = BookmarkViewModel()
    @State private var isFloatingWindowVisible = false
    @State private var mainWindowSetupAttempts = 0
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = Bundle.main.executableURL
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .background(
                    FloatingWindowView(isVisible: $isFloatingWindowVisible)
                        .environmentObject(viewModel)
                )
                .onAppear {
                    // Delay floating window creation to ensure main window is set up first
                    DispatchQueue.main.async {
                        self.setupMainWindow()
                    }
                }
                .onChange(of: viewModel.bookmarks) { _, newBookmarks in
                    if let controller = NSApp.windows
                        .compactMap({ $0.windowController as? FloatingWindowController })
                        .first
                    {
                        controller.updateBookmarkCount(newBookmarks.count)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        isFloatingWindowVisible = false
                    } else if newPhase == .active {
                        isFloatingWindowVisible = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About NeoNav") {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center

                    let credits = NSAttributedString(
                        string:
                        "A lightweight bookmark manager for quick access to your favorite websites.\n\nDeveloped by Lin Wang\n\n© 2024 Lin Wang",
                        attributes: [
                            .foregroundColor: NSColor.textColor,
                            .font: NSFont.systemFont(ofSize: 11),
                            .paragraphStyle: paragraphStyle,
                        ]
                    )

                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: credits,
                            NSApplication.AboutPanelOptionKey.version: "",
                        ]
                    )
                }
            }
        }
    }
    
    private func setupMainWindow() {
        // Find the main window more reliably
        let mainWindow: NSWindow?
        
        // First try NSApp.mainWindow (most reliable)
        if let window = NSApp.mainWindow {
            mainWindow = window
        } else {
            // Fallback: find window containing ContentView
            // Look for windows that are not floating windows
            mainWindow = NSApp.windows.first { window in
                // Exclude floating windows (they have FloatingWindowController)
                guard window.windowController as? FloatingWindowController == nil else {
                    return false
                }
                // Check if window has content and is visible or can become visible
                return window.contentView != nil
            }
        }
        
        guard let window = mainWindow else {
            // If window not found yet, try again after a short delay (max 5 attempts)
            mainWindowSetupAttempts += 1
            guard mainWindowSetupAttempts < 5 else {
                // After 5 attempts, show floating window anyway
                isFloatingWindowVisible = true
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setupMainWindow()
            }
            return
        }
        
        // Reset attempts counter on success
        mainWindowSetupAttempts = 0
        
        // Configure window
        window.delegate = MainWindowDelegate.shared
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.minSize = NSSize(
            width: UIConstants.MainWindow.minWidth,
            height: UIConstants.MainWindow.minHeight
        )
        
        // Center window if no saved state exists
        if UserDefaults.standard.dictionary(forKey: MainWindowDelegate.windowStateKey) == nil {
            window.center()
        }
        
        // Explicitly show the main window to ensure it's visible
        window.makeKeyAndOrderFront(nil)
        
        // Now show the floating window after main window is ready
        isFloatingWindowVisible = true
    }
}

// MARK: - FloatingWindowView

#if os(macOS)
    import AppKit

    struct FloatingWindowView: NSViewRepresentable {
        @EnvironmentObject var viewModel: BookmarkViewModel
        @Binding var isVisible: Bool

        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            updateWindowController(context: context)
            return view
        }

        func updateNSView(_: NSView, context: Context) {
            updateWindowController(context: context)
        }

        private func updateWindowController(context: Context) {
            // Only create floating window if it should be visible
            guard isVisible else {
                context.coordinator.windowController?.close()
                return
            }
            
            if context.coordinator.windowController == nil {
                let rootView = FloatingStripView()
                    .environmentObject(viewModel)
                context.coordinator.windowController = FloatingWindowController(
                    rootView: rootView,
                    bookmarkCount: viewModel.bookmarks.count
                )
            }

            if let controller = context.coordinator.windowController {
                controller.updateBookmarkCount(viewModel.bookmarks.count)
                controller.showWindow(nil)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var windowController: FloatingWindowController?
        }
    }
#endif

// MARK: - Window Delegate

/// Handles main window lifecycle and persistence (minimizes instead of closing)
class MainWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = MainWindowDelegate()
    static let windowStateKey = "MainWindowState"
    private var isQuitting = false
    private var hasRestoredInitialState = false
    private var isFirstLaunch = true

    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidFinishLaunching(_:)),
            name: NSApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidFinishLaunching(_: Notification) {
        // Mark that we've finished launching - after this, we can restore minimized state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isFirstLaunch = false
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard !isQuitting,
              let window = notification.object as? NSWindow else { return }

        saveWindowState(window)
        window.miniaturize(nil)
    }

    func windowDidBecomeMain(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              !hasRestoredInitialState else { return }

        restoreWindowState(window)
        hasRestoredInitialState = true
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowState(window)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowState(window)
    }

    func windowDidMiniaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowState(window)
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowState(window)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isQuitting { return true }
        sender.miniaturize(nil)
        return false
    }

    private func saveWindowState(_ window: NSWindow) {
        let state: [String: Any] = [
            "frame": NSStringFromRect(window.frame),
            "isMinimized": window.isMiniaturized,
        ]
        UserDefaults.standard.set(state, forKey: Self.windowStateKey)
    }

    private func restoreWindowState(_ window: NSWindow) {
        guard let state = UserDefaults.standard.dictionary(forKey: Self.windowStateKey),
              let frameString = state["frame"] as? String else { return }

        let frame = NSRectFromString(frameString)
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero

        if visibleFrame.intersects(frame) {
            window.setFrame(frame, display: true)
            // Don't restore minimized state on first launch - always show the window
            if let isMinimized = state["isMinimized"] as? Bool, isMinimized, !isFirstLaunch {
                window.miniaturize(nil)
            } else {
                // Ensure window is visible on first launch
                window.makeKeyAndOrderFront(nil)
            }
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func applicationWillTerminate(_: Notification) {
        isQuitting = true
        if let window = NSApp.mainWindow {
            saveWindowState(window)
        }
    }
}
