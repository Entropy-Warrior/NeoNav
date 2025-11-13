/// IconProcessor.swift
/// Utility for processing and optimizing bookmark icons.
/// Handles image resizing, format conversion, and quality preservation.

import AppKit
import Foundation
import SwiftUI

public enum IconProcessor {
    /// Converts NSImage to PNG data
    public static func processImage(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Standardizes image to consistent size while preserving aspect ratio
    public static func standardizeImage(_ image: NSImage) -> NSImage {
        let size = NSSize(width: 128, height: 128)
        let standardized = NSImage(size: size)

        standardized.lockFocus()
        defer { standardized.unlockFocus() }

        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()

        let originalSize = image.size
        let aspectRatio = min(size.width / originalSize.width, size.height / originalSize.height)
        let newWidth = originalSize.width * aspectRatio
        let newHeight = originalSize.height * aspectRatio
        let x = (size.width - newWidth) / 2
        let y = (size.height - newHeight) / 2

        image.draw(
            in: NSRect(x: x, y: y, width: newWidth, height: newHeight),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [
                NSImageRep.HintKey.interpolation: NSNumber(value: NSImageInterpolation.high.rawValue),
            ]
        )

        return standardized
    }
}
