/// Bookmark.swift
/// Core data model representing a bookmark in the app.
/// This file contains:
/// - Bookmark properties and initialization
/// - URL validation and formatting
/// - Codable implementation for persistence
/// - Utility methods for bookmark management
/// The model serves as the foundation for bookmark data throughout the app.

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Define a custom UTType for bookmarks
extension UTType {
    static var neonavBookmark: UTType {
        UTType(exportedAs: "com.linwang.neonav.bookmark")
    }
}

// MARK: - Bookmark Model

struct Bookmark: Identifiable, Codable, Transferable, Equatable, Hashable {
    let id: UUID
    var title: String
    var url: String
    var order: Int
    var iconData: Data?
    var isManuallyUploadedIcon: Bool
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        order: Int = 0,
        iconData: Data? = nil,
        isManuallyUploadedIcon: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.order = order
        self.iconData = iconData
        self.isManuallyUploadedIcon = isManuallyUploadedIcon
        dateAdded = Date()
    }

    // MARK: - Transferable Conformance

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .neonavBookmark)
        ProxyRepresentation { bookmark in
            bookmark.url
        } importing: { url in
            Bookmark(title: URL(string: url)?.host ?? url, url: url)
        }
    }

    // MARK: - Helper Methods

    static func urlExists(_ url: String, in bookmarks: [Bookmark]) -> Bool {
        bookmarks.contains { $0.url.lowercased() == url.lowercased() }
    }

    // MARK: - Equatable Conformance

    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
