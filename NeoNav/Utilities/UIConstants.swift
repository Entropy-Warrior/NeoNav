import Foundation
import SwiftUI

/// Global UI constants used throughout the app for consistent styling and layout
enum UIConstants {
    /// Core layout metrics used throughout the app
    enum Layout {
        /// Standard padding values
        static let smallPadding: CGFloat = 4
        static let mediumPadding: CGFloat = 8
        static let largePadding: CGFloat = 12
        static let extraLargePadding: CGFloat = 16
        static let doublePadding: CGFloat = 20
        static let triplePadding: CGFloat = 24

        /// Standard spacing values
        static let tightSpacing: CGFloat = 2
        static let smallSpacing: CGFloat = 4
        static let mediumSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 12
        static let extraLargeSpacing: CGFloat = 16
        static let doubleSpacing: CGFloat = 24

        /// Standard sizes
        static let smallIconSize: CGFloat = 24
        static let mediumIconSize: CGFloat = 32
        static let largeIconSize: CGFloat = 36
        static let extraLargeIconSize: CGFloat = 52
        static let hugeIconSize: CGFloat = 128
        static let maxIconSize: CGFloat = 160

        /// Form element sizes
        static let buttonHeight: CGFloat = 44
        static let fieldPadding: CGFloat = 10
        static let fieldSpacing: CGFloat = 16
        static let labelSpacing: CGFloat = 6
    }

    /// Visual style constants
    enum Style {
        /// Corner radii
        static let smallRadius: CGFloat = 8
        static let standardRadius: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let formFieldRadius: CGFloat = 8

        /// Border widths
        static let thinBorder: CGFloat = 0.5
        static let thickBorder: CGFloat = 2
        static let borderWidth: CGFloat = 0.5
        static let focusedBorderWidth: CGFloat = 2

        /// Opacities
        static let subtleOpacity: Double = 0.05
        static let lightOpacity: Double = 0.1
        static let mediumOpacity: Double = 0.15
        static let standardOpacity: Double = 0.2
        static let highOpacity: Double = 0.25
        static let strongOpacity: Double = 0.4
        static let fullOpacity: Double = 0.5
        static let backgroundOpacity: Double = 0.2
        static let borderOpacity: Double = 0.1
        static let focusedOpacity: Double = 0.5
        static let disabledOpacity: Double = 0.5

        /// Drag indicator properties
        static let dragIndicatorDotSize: CGFloat = 4
        static let dragIndicatorDotSpacing: CGFloat = 6
        static let resizeHandleWidth: CGFloat = 4
    }

    /// Typography constants
    enum Typography {
        /// Font sizes
        static let smallText: CGFloat = 11
        static let bodyText: CGFloat = 14
        static let titleText: CGFloat = 20
        static let bookmarkTitleSize: CGFloat = 11
        static let formLabelSize: CGFloat = 14
        static let headerSize: CGFloat = 20

        /// Font weights
        static let regularWeight: Font.Weight = .regular
        static let mediumWeight: Font.Weight = .medium
        static let boldWeight: Font.Weight = .bold
        static let bookmarkTitleWeight: Font.Weight = .medium
        static let headerWeight: Font.Weight = .bold

        /// Text padding
        static let textPaddingHorizontal: CGFloat = 6
        static let textPaddingVertical: CGFloat = 2
        static let bookmarkTitleHorizontalPadding: CGFloat = 6
        static let bookmarkTitleVerticalPadding: CGFloat = 2
    }

    /// Window dimensions and layout
    enum Window {
        /// Main window
        static let mainMinWidth: CGFloat = 800
        static let mainMinHeight: CGFloat = 500
        static let mainContentMinWidth: CGFloat = 300
        static let mainContentMinHeight: CGFloat = 400
        static let defaultSplitPosition: Double = 200
        static let sheetWidth: CGFloat = 400

        /// Floating strip
        static let stripMinWidth: CGFloat = 120
        static let stripMinHeight: CGFloat = 100
        static let stripItemWidth: CGFloat = 70
        static let stripItemSpacing: CGFloat = 10
        static let maxItemsPerRow: Int = 8
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 16
        static let gridHorizontalPadding: CGFloat = 24

        /// Drag handle
        static let dragHandleWidth: CGFloat = 44 // Matches macOS standard touch target size
        static let dragHandleMinWidth: CGFloat = 32 // Minimum width when window is very small
    }

    /// Icon dimensions and properties
    enum Icon {
        /// Bookmark icon sizes
        static let containerSize: CGFloat = 52
        static let customIconSize: CGFloat = 36
        static let defaultIconSize: CGFloat = 28
        static let processedIconSize: CGFloat = 128
        static let detailViewSize: CGFloat = 128
        static let detailContainerSize: CGFloat = 160
        static let rowIconSize: CGFloat = 32
        static let emptyStateIconSize: CGFloat = 36
    }

    /// Animation properties
    enum Animation {
        /// Durations
        static let quickDuration: Double = 0.2
        static let standardDuration: Double = 0.3
        static let slowDuration: Double = 0.4
        static let extraSlowDuration: Double = 0.6

        /// Spring configurations
        static let standardResponse: Double = 0.4
        static let standardDamping: Double = 0.8
        static let quickResponse: Double = 0.3
        static let quickDamping: Double = 0.7
        static let blendDuration: Double = 0.2
        static let detailViewResponse: Double = 0.6
        static let detailViewDamping: Double = 0.8

        /// Scale factors
        static let hoverScale: CGFloat = 1.05
        static let entranceOffset: CGFloat = 20
    }

    /// Interaction timing
    enum Timing {
        static let doubleClickPrevention: TimeInterval = 1.0
        static let saveAnimationDelay: TimeInterval = 0.5
    }

    /// Storage limits
    enum Storage {
        static let maxBookmarks: Int = 1000
    }
}

// Extension for convenient access to commonly used combinations
extension UIConstants {
    static var standardPadding: CGFloat { Layout.largePadding }
    static var standardSpacing: CGFloat { Layout.mediumSpacing }
    static var standardCornerRadius: CGFloat { Style.standardRadius }
    static var standardBorderWidth: CGFloat { Style.thinBorder }
    static var standardOpacity: Double { Style.standardOpacity }
    static var standardIconSize: CGFloat { Layout.mediumIconSize }
    static var standardFontSize: CGFloat { Typography.bodyText }
}

// Compatibility extensions for existing code
extension UIConstants {
    enum MainWindow {
        static var minWidth: CGFloat { Window.mainMinWidth }
        static var minHeight: CGFloat { Window.mainMinHeight }
        static var minContentWidth: CGFloat { Window.mainContentMinWidth }
        static var minContentHeight: CGFloat { Window.mainContentMinHeight }
        static var defaultSplitPosition: Double { Window.defaultSplitPosition }
        static var addBookmarkSheetWidth: CGFloat { Window.sheetWidth }
    }

    enum FloatingStrip {
        static var itemWidth: CGFloat { Window.stripItemWidth }
        static var itemSpacing: CGFloat { Window.stripItemSpacing }
        static var minWidth: CGFloat { Window.stripMinWidth }
        static var minHeight: CGFloat { Window.stripMinHeight }
        static var horizontalPadding: CGFloat { Window.horizontalPadding }
        static var topPadding: CGFloat { Window.topPadding }
        static var bottomPadding: CGFloat { Window.bottomPadding }
        static var gridHorizontalPadding: CGFloat { Window.gridHorizontalPadding }
        static var maxItemsPerRow: Int { Window.maxItemsPerRow }
    }

    enum BookmarkIcon {
        static var containerSize: CGFloat { Icon.containerSize }
        static var customIconSize: CGFloat { Icon.customIconSize }
        static var defaultIconSize: CGFloat { Icon.defaultIconSize }
        static var processedIconSize: CGFloat { Icon.processedIconSize }
        static var detailViewSize: CGFloat { Icon.detailViewSize }
        static var detailContainerSize: CGFloat { Icon.detailContainerSize }
    }

    enum BookmarkRow {
        static var iconSize: CGFloat { Icon.rowIconSize }
        static var verticalPadding: CGFloat { Layout.smallPadding }
    }

    enum EmptyState {
        static var iconSize: CGFloat { Icon.emptyStateIconSize }
    }

    enum DetailView {
        static var elementSpacing: CGFloat { Layout.doubleSpacing }
        static var titleBottomPadding: CGFloat { Layout.smallPadding }
        static var entranceOffset: CGFloat { Animation.entranceOffset }
        static var springResponse: Double { Animation.detailViewResponse }
        static var springDamping: Double { Animation.detailViewDamping }
    }
}
