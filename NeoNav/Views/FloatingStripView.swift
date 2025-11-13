/// FloatingStripView.swift
/// The main floating window interface that displays bookmarks in a strip layout.
/// This file contains:
/// - Grid-based bookmark layout with scroll support
/// - Draggable window area implementation
/// - Hover effects and click handling
/// - Dynamic size calculations and content overflow indicators
/// The view adapts to different numbers of bookmarks and window sizes.

import Cocoa
import SwiftUI

// MARK: - FloatingStripView

/// A floating bar that displays bookmarks horizontally in a borderless window.
/// Features:
/// - Displays bookmarks with custom icons or default system icons
/// - Click to open bookmarks in default browser
/// - Hover effects and tooltips
/// - Draggable interface
struct FloatingStripView: View {
    @EnvironmentObject var viewModel: BookmarkViewModel
    @State private var hoveredBookmarkID: UUID?
    @State private var contentSize: CGSize = .zero
    @State private var viewportSize: CGSize = .zero

    // Constants for layout
    private let itemWidth = UIConstants.FloatingStrip.itemWidth
    private let itemSpacing = UIConstants.FloatingStrip.itemSpacing
    private let minWidth = UIConstants.FloatingStrip.minWidth
    private let minHeight = UIConstants.FloatingStrip.minHeight
    private let horizontalPadding = UIConstants.FloatingStrip.horizontalPadding
    private let topPadding = UIConstants.FloatingStrip.topPadding
    private let bottomPadding = UIConstants.FloatingStrip.bottomPadding

    private var hasMoreContent: Bool {
        guard !viewModel.bookmarks.isEmpty,
              viewportSize.width > 0,
              viewportSize.height > 0
        else {
            return false
        }

        // Calculate grid layout
        let itemsPerRow = max(1, Int((viewportSize.width - horizontalPadding) / (itemWidth + itemSpacing)))
        let totalRows = ceil(CGFloat(viewModel.bookmarks.count) / CGFloat(itemsPerRow))

        // Calculate minimum required height for current layout
        let requiredHeight = (itemWidth * totalRows) + (itemSpacing * (totalRows - 1)) + topPadding + bottomPadding

        return requiredHeight > viewportSize.height
    }

    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = width - horizontalPadding
        let itemWidthWithSpacing = itemWidth + itemSpacing

        // If width is close to minimum, force single column
        if width <= (minWidth + itemSpacing) {
            return [GridItem(.fixed(itemWidth), spacing: itemSpacing)]
        }

        // Otherwise calculate columns based on available space
        let columnCount = max(1, Int(availableWidth / itemWidthWithSpacing))
        return Array(repeating: GridItem(.fixed(itemWidth), spacing: itemSpacing), count: columnCount)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundView()

                // Content layer
                ZStack(alignment: .bottom) {
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        LazyVGrid(
                            columns: calculateColumns(for: geometry.size.width),
                            spacing: UIConstants.Window.stripItemSpacing
                        ) {
                            if viewModel.bookmarks.isEmpty {
                                EmptyBookmarksView()
                            } else {
                                bookmarksList
                            }
                        }
                        .padding(.horizontal, UIConstants.Layout.largePadding)
                        .padding(.top, UIConstants.Window.topPadding)
                        .padding(.bottom, UIConstants.Window.bottomPadding)
                        .background(
                            GeometryReader { gridGeometry in
                                Color.clear.preference(key: SizePreferenceKey.self, value: gridGeometry.size)
                            }
                        )
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            viewportSize = geometry.size
                        }
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        DispatchQueue.main.async {
                            viewportSize = newSize
                        }
                    }

                    // Overflow indicators
                    if hasMoreContent {
                        VStack {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: UIConstants.Layout.smallIconSize, weight: .regular))
                                .foregroundStyle(.white.opacity(UIConstants.Style.strongOpacity))
                                .background(
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(
                                            width: UIConstants.Layout.smallIconSize,
                                            height: UIConstants.Layout.smallIconSize
                                        )
                                )
                                .allowsHitTesting(false)
                                .transition(.opacity
                                    .animation(.easeInOut(duration: UIConstants.Animation.quickDuration)))
                                .help("Scroll to see more bookmarks")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, UIConstants.Layout.mediumSpacing)
                        .padding(.bottom, UIConstants.Layout.mediumSpacing)
                    }
                }

                // Drag handle layer - always on top
                DraggableArea(width: geometry.size.width)
            }
            .onPreferenceChange(SizePreferenceKey.self) { size in
                DispatchQueue.main.async {
                    contentSize = size
                }
            }
        }
        .frame(
            minWidth: UIConstants.Window.stripMinWidth,
            maxWidth: .infinity,
            minHeight: UIConstants.Window.stripMinHeight,
            maxHeight: .infinity
        )
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius))
    }

    private func calculateInitialWidth() -> CGFloat {
        let bookmarkCount = viewModel.bookmarks.count
        let itemsPerRow = min(UIConstants.Window.maxItemsPerRow, max(1, bookmarkCount))
        return (UIConstants.Window.stripItemWidth * CGFloat(itemsPerRow)) +
            (UIConstants.Window.stripItemSpacing * CGFloat(itemsPerRow - 1)) + UIConstants.Layout.triplePadding
    }

    private var bookmarksList: some View {
        ForEach(viewModel.bookmarks) { bookmark in
            BookmarkButton(
                bookmark: bookmark,
                isHovered: hoveredBookmarkID == bookmark.id,
                onHover: { isHovered in
                    DispatchQueue.main.async {
                        if isHovered {
                            hoveredBookmarkID = bookmark.id
                        } else if hoveredBookmarkID == bookmark.id {
                            hoveredBookmarkID = nil
                        }
                    }
                }
            )
            .id(bookmark.id)
        }
        .animation(
            .spring(
                response: UIConstants.Animation.standardResponse,
                dampingFraction: UIConstants.Animation.standardDamping,
                blendDuration: UIConstants.Animation.blendDuration
            ),
            value: viewModel.bookmarks.map(\.id)
        )
    }
}

// MARK: - Background View Component

/// Semi-transparent background with blur effect and border
private struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Base background
            Color.black.opacity(UIConstants.Style.standardOpacity)

            // Consistent edge highlight all around
            RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius)
                .strokeBorder(
                    Color.white.opacity(0.1), // Consistent opacity all around
                    lineWidth: 1.0
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius))
        .allowsHitTesting(false) // Prevent dragging from background
    }
}

// MARK: - Draggable Area Component

/// Transparent draggable area with centered drag indicator
private struct DraggableArea: View {
    let width: CGFloat
    @State private var isHovered: Bool = false

    // Calculate handle width based on window width
    private var handleWidth: CGFloat {
        // For very small windows, use minimum width
        if width < UIConstants.Window.stripMinWidth * 1.5 {
            return UIConstants.Window.dragHandleMinWidth
        }
        return UIConstants.Window.dragHandleWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side drag handle
            VStack(spacing: UIConstants.Style.dragIndicatorDotSpacing) {
                ForEach(0 ..< 3) { _ in
                    Circle()
                        .fill(Color.white
                            .opacity(isHovered ? UIConstants.Style.highOpacity : UIConstants.Style.lightOpacity))
                        .frame(
                            width: UIConstants.Style.dragIndicatorDotSize,
                            height: UIConstants.Style.dragIndicatorDotSize
                        )
                }
            }
            .frame(width: handleWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: UIConstants.Animation.quickDuration)) {
                    isHovered = hovering
                }
            }
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.001)) // Nearly invisible but helps with hit testing
                    .allowsHitTesting(true)
            )
            .background(DraggableViewRepresentable())

            // Rest of the space - allow interaction but not dragging
            Spacer()

            // Right edge resize handle
            Rectangle()
                .fill(Color.clear)
                .frame(width: UIConstants.Style.resizeHandleWidth)
                .contentShape(Rectangle())
                .background(ResizableViewRepresentable())
        }
    }
}

// NSView representable to handle window resizing
private struct ResizableViewRepresentable: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView {
        let view = ResizableView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

// Custom NSView that enables resizing
private class ResizableView: NSView {
    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        window.performDrag(with: event)
    }

    override func mouseEntered(with _: NSEvent) {
        NSCursor.resizeLeftRight.push()
    }

    override func mouseExited(with _: NSEvent) {
        NSCursor.pop()
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }
}

// MARK: - Empty State View

private struct EmptyBookmarksView: View {
    var body: some View {
        Text("No Bookmarks")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Bookmark Button Component

/// Individual bookmark button with icon and title
private struct BookmarkButton: View {
    let bookmark: Bookmark
    let isHovered: Bool
    let onHover: (Bool) -> Void
    @State private var lastClickTime = Date.distantPast

    var body: some View {
        Button {
            let now = Date()
            if now.timeIntervalSince(lastClickTime) > UIConstants.Timing.doubleClickPrevention {
                lastClickTime = now
                openBookmark(bookmark)
            }
        } label: {
            VStack(spacing: UIConstants.Layout.tightSpacing) {
                iconContainer
                titleLabel
            }
            .frame(width: UIConstants.Window.stripItemWidth)
            .padding(UIConstants.Layout.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius)
                    .fill(Color.primary.opacity(isHovered ? UIConstants.Style.lightOpacity : 0))
            )
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
        .help("\(bookmark.title)\n\(bookmark.url)")
        .scaleEffect(isHovered ? UIConstants.Animation.hoverScale : 1.0)
        .animation(
            .spring(
                response: UIConstants.Animation.quickResponse,
                dampingFraction: UIConstants.Animation.quickDamping
            ),
            value: isHovered
        )
    }

    private var iconContainer: some View {
        ZStack {
            iconBackground
            bookmarkIcon
        }
    }

    private var iconBackground: some View {
        RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius)
            .fill(Color.white.opacity(UIConstants.Style.mediumOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.Style.standardRadius)
                    .stroke(
                        Color.white.opacity(UIConstants.Style.lightOpacity),
                        lineWidth: UIConstants.Style.thinBorder
                    )
            )
            .frame(width: UIConstants.Layout.extraLargeIconSize, height: UIConstants.Layout.extraLargeIconSize)
    }

    @ViewBuilder
    private var bookmarkIcon: some View {
        if let iconData = bookmark.iconData,
           let nsImage = NSImage(data: iconData)
        {
            Image(nsImage: processIcon(nsImage))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIConstants.Layout.largeIconSize, height: UIConstants.Layout.largeIconSize)

        } else {
            Image(systemName: "globe")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIConstants.Layout.mediumIconSize, height: UIConstants.Layout.mediumIconSize)
                .foregroundColor(.blue)
        }
    }

    private var titleLabel: some View {
        Text(bookmark.title)
            .font(.system(size: UIConstants.Typography.smallText, weight: UIConstants.Typography.mediumWeight))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, UIConstants.Typography.textPaddingHorizontal)
            .padding(.vertical, UIConstants.Typography.textPaddingVertical)
            .background(
                Capsule()
                    .fill(Color.clear)
            )
    }

    private func openBookmark(_ bookmark: Bookmark) {
        if let url = URL(string: bookmark.url) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Icon Processing

extension BookmarkButton {
    /// Process the icon to ensure consistent quality and appearance
    /// - Parameter originalImage: The original NSImage to process
    /// - Returns: A processed NSImage with consistent size and quality
    private func processIcon(_ originalImage: NSImage) -> NSImage {
        let size = NSSize(
            width: UIConstants.BookmarkIcon.processedIconSize,
            height: UIConstants.BookmarkIcon.processedIconSize
        )
        let newImage = NSImage(size: size)

        newImage.lockFocus()

        // Clear background
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()

        // Calculate aspect ratio preserving frame
        let originalSize = originalImage.size
        let aspectRatio = min(size.width / originalSize.width, size.height / originalSize.height)
        let newWidth = originalSize.width * aspectRatio
        let newHeight = originalSize.height * aspectRatio
        let x = (size.width - newWidth) / 2
        let y = (size.height - newHeight) / 2

        // Draw with high quality
        originalImage.draw(
            in: NSRect(x: x, y: y, width: newWidth, height: newHeight),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [
                NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue),
            ]
        )

        newImage.unlockFocus()
        return newImage
    }
}

// Size preference key for measuring content
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// NSView representable to handle window dragging
private struct DraggableViewRepresentable: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView {
        let view = DraggableView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}

// Custom NSView that enables dragging
private class DraggableView: NSView {
    private var isDragging = false

    override func mouseDown(with _: NSEvent) {
        isDragging = true
        NSCursor.closedHand.push()
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        NSCursor.pop()
        if isMousePoint(event.locationInWindow, in: bounds) {
            NSCursor.openHand.push()
        }
    }

    override func mouseEntered(with _: NSEvent) {
        if !isDragging {
            NSCursor.openHand.push()
        }
    }

    override func mouseExited(with _: NSEvent) {
        if !isDragging {
            NSCursor.pop()
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }
}
