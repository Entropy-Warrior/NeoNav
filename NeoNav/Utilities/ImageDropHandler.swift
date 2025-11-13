/// ImageDropHandler.swift
/// Handles drag-and-drop functionality for images onto bookmark icons.
/// Provides drop target views with preview and completion handlers.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ImageDropHandler {
    static func createDropTargetView(
        bookmarkID _: UUID,
        isTargeted: Binding<Bool>,
        onPreview: @escaping (NSImage) -> Void,
        onComplete: @escaping (Data) -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .onDrop(of: [.image], isTargeted: isTargeted) { providers in
                guard let provider = providers.first else { return false }

                let _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let imageData = data,
                          let nsImage = NSImage(data: imageData) else { return }

                    DispatchQueue.main.async {
                        onPreview(nsImage)
                    }

                    onComplete(imageData)
                }
                return true
            }
    }
}
