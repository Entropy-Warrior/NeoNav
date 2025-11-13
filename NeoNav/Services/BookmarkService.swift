/// BookmarkService.swift
/// Core service for managing bookmark data and operations.
/// Handles CRUD operations with validation and enforces maximum bookmark limit.

import Foundation

// MARK: - Bookmark Service Protocol

protocol BookmarkServiceProtocol {
    func saveBookmark(_ bookmark: Bookmark) async throws
    func deleteBookmark(_ bookmark: Bookmark) async throws
    func fetchBookmarks() async throws -> [Bookmark]
    func updateBookmark(_ bookmark: Bookmark) async throws
    func saveBookmarks(_ bookmarks: [Bookmark]) async throws
}

// MARK: - Bookmark Service Implementation

final class BookmarkService: BookmarkServiceProtocol {
    private let persistenceManager: LocalPersistenceManager

    init(persistenceManager: LocalPersistenceManager = LocalPersistenceManager()) {
        self.persistenceManager = persistenceManager
    }

    func saveBookmark(_ bookmark: Bookmark) async throws {
        var bookmarks = try await fetchBookmarks()

        guard bookmarks.count < UIConstants.Storage.maxBookmarks else {
            throw BookmarkError.maxBookmarksReached
        }

        bookmarks.append(bookmark)
        try await persistenceManager.saveBookmarks(bookmarks)
    }

    func deleteBookmark(_ bookmark: Bookmark) async throws {
        var bookmarks = try await fetchBookmarks()

        guard bookmarks.contains(where: { $0.id == bookmark.id }) else {
            throw BookmarkError.bookmarkNotFound
        }

        bookmarks.removeAll { $0.id == bookmark.id }
        try await persistenceManager.saveBookmarks(bookmarks)
    }

    func fetchBookmarks() async throws -> [Bookmark] {
        try await persistenceManager.fetchBookmarks()
    }

    func updateBookmark(_ bookmark: Bookmark) async throws {
        var bookmarks = try await fetchBookmarks()

        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            throw BookmarkError.bookmarkNotFound
        }

        bookmarks[index] = bookmark
        try await persistenceManager.saveBookmarks(bookmarks)
    }

    func saveBookmarks(_ bookmarks: [Bookmark]) async throws {
        try await persistenceManager.saveBookmarks(bookmarks)
    }
}

// MARK: - Bookmark Errors

enum BookmarkError: LocalizedError {
    case maxBookmarksReached
    case bookmarkNotFound

    var errorDescription: String? {
        switch self {
        case .maxBookmarksReached:
            "Maximum number of bookmarks (\(UIConstants.Storage.maxBookmarks)) reached"
        case .bookmarkNotFound:
            "The specified bookmark could not be found"
        }
    }
}
