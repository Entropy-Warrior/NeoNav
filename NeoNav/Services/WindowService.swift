/// WindowService.swift
/// Service for managing window-related functionality.
/// Handles window creation and size updates for the floating bookmark strip.

import AppKit
import SwiftUI

class WindowService {
    static func createFloatingWindow(viewModel: BookmarkViewModel, bookmarkCount: Int) -> FloatingWindowController {
        let rootView = FloatingStripView()
            .environmentObject(viewModel)
        let controller = FloatingWindowController(rootView: rootView, bookmarkCount: bookmarkCount)
        controller.showWindow(nil)
        return controller
    }

    static func updateWindowSize(controller: FloatingWindowController?, bookmarkCount: Int) {
        controller?.updateBookmarkCount(bookmarkCount)
    }
}
