/// IconPreviewManager.swift
/// Provides real-time preview for bookmark icons during drag-and-drop.
/// Uses notification system to coordinate preview state across views.

import AppKit
import Foundation
import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let previewIconUpdate = Notification.Name("previewIconUpdate")
}

@MainActor
final class IconPreviewManager {
    static let shared = IconPreviewManager()
    private init() {}
    func showPreview(for bookmarkID: UUID, image: NSImage) {
        NotificationCenter.default.post(
            name: .previewIconUpdate,
            object: nil,
            userInfo: [
                "bookmarkID": bookmarkID as Any,
                "previewImage": image as Any,
            ]
        )
    }

    func clearPreview(for bookmarkID: UUID) {
        NotificationCenter.default.post(
            name: .previewIconUpdate,
            object: nil,
            userInfo: [
                "bookmarkID": bookmarkID as Any,
                "previewImage": NSImage?.none as Any,
            ]
        )
    }
}
