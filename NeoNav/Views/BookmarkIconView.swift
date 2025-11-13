/// BookmarkIconView.swift
/// A reusable view component that displays a bookmark's icon with preview capabilities.
/// This file contains:
/// - Icon display logic for both custom and default icons
/// - Preview layer for drag-and-drop operations
/// - Size and background customization options
/// The view supports both actual icons and temporary previews during drag operations.

import AppKit
import Foundation
import SwiftUI

// MARK: - Icon View

struct BookmarkIconView: View {
    let bookmark: Bookmark
    let size: CGFloat
    var showBackground: Bool = false
    @State private var previewImage: NSImage?

    var body: some View {
        ZStack {
            // Base layer (actual data)
            if let iconData = bookmark.iconData,
               let nsImage = NSImage(data: iconData)
            {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: size * 0.75))
                    .foregroundColor(.blue)
                    .frame(width: size, height: size)
            }

            // Preview layer (completely independent)
            if let preview = previewImage {
                Image(nsImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .background(Color(NSColor.windowBackgroundColor))
                    .transition(.opacity)
            }
        }
        .background(showBackground ? Color.secondary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: showBackground ? 8 : 0))
        .onDisappear {
            previewImage = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .previewIconUpdate)
            .receive(on: DispatchQueue.main))
        { notification in
            guard let userInfo = notification.userInfo,
                  let bookmarkID = userInfo["bookmarkID"] as? UUID,
                  let nsImage = userInfo["previewImage"] as? NSImage,
                  bookmarkID == bookmark.id
            else { return }

            withAnimation {
                previewImage = nsImage
            }
        }
    }
}
