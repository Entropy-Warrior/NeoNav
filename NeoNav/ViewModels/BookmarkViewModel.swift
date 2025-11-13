/// BookmarkViewModel.swift
/// Main view model managing bookmark data and operations.
/// Handles CRUD operations, favicon fetching, and bookmark reordering.

import Foundation
import SwiftUI

// MARK: - Bookmark ViewModel

@MainActor
final class BookmarkViewModel: ObservableObject {
    @Published private(set) var bookmarks: [Bookmark] = []
    private let bookmarkService: BookmarkServiceProtocol
    private let faviconService: FaviconServiceProtocol
    private(set) var isInitialized = false
    private var initializationTask: Task<Void, Never>?

    init(
        bookmarkService: BookmarkServiceProtocol = BookmarkService(),
        faviconService: FaviconServiceProtocol = FaviconService()
    ) {
        self.bookmarkService = bookmarkService
        self.faviconService = faviconService

        initializationTask = Task { @MainActor in
            await loadInitialBookmarks()
            setupFaviconUpdateObserver()
            isInitialized = true
        }
    }

    deinit {
        // Cancel initialization task if it exists
        if let task = initializationTask {
            task.cancel()
        }

        // Remove specific notification observers
        NotificationCenter.default.removeObserver(self, name: .faviconDidUpdate, object: nil)
    }

    @MainActor
    func updateBookmarkIcon(bookmark: Bookmark, iconData: Data, isManualUpload: Bool = true) async {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            return
        }

        var updatedBookmark = bookmark
        updatedBookmark.iconData = iconData
        updatedBookmark.isManuallyUploadedIcon = isManualUpload

        // Create a new array to force SwiftUI to recognize the change
        var updatedBookmarks = bookmarks
        updatedBookmarks[index] = updatedBookmark
        bookmarks = updatedBookmarks

        do {
            try await persistBookmarks()
            objectWillChange.send()
        } catch {
            // Revert changes on failure
            bookmarks = bookmarks
            objectWillChange.send()
        }
    }

    private func loadInitialBookmarks() async {
        do {
            bookmarks = try await bookmarkService.fetchBookmarks()
        } catch {
            bookmarks = []
        }
    }

    @discardableResult
    func addBookmark(bookmark: Bookmark) async -> Bool {
        await waitForInitialization()

        guard !Bookmark.urlExists(bookmark.url, in: bookmarks) else {
            return false
        }

        var mutableBookmark = bookmark

        if let url = URL(string: bookmark.url) {
            mutableBookmark.iconData = try? await faviconService.fetchFavicon(for: url)
        }

        do {
            bookmarks.append(mutableBookmark)
            try await persistBookmarks()
            return true
        } catch {
            bookmarks.removeLast()
            return false
        }
    }

    private func waitForInitialization() async {
        while !isInitialized {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if Task.isCancelled { return }
        }
    }

    @discardableResult
    func deleteBookmark(bookmark: Bookmark) async -> Bool {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            return false
        }

        do {
            bookmarks.remove(at: index)
            try await persistBookmarks()
            objectWillChange.send()
            return true
        } catch {
            // Revert the deletion if persistence fails
            bookmarks.insert(bookmark, at: index)
            objectWillChange.send()
            return false
        }
    }

    func refreshAllFavicons() async {
        let bookmarksToRefresh = bookmarks.filter { !$0.isManuallyUploadedIcon }

        // Create a task group to track all favicon updates
        await withTaskGroup(of: Void.self) { group in
            for bookmark in bookmarksToRefresh {
                group.addTask {
                    if let url = URL(string: bookmark.url) {
                        if let iconData = try? await self.faviconService.fetchFavicon(for: url) {
                            await self.updateBookmarkIcon(bookmark: bookmark, iconData: iconData, isManualUpload: false)
                        }
                    }
                }
            }

            // Wait for all updates to complete
            await group.waitForAll()
        }

        // Force final UI update
        objectWillChange.send()
    }

    func moveBookmarks(from source: IndexSet, to destination: Int) async {
        var updatedBookmarks = bookmarks
        updatedBookmarks.move(fromOffsets: source, toOffset: destination)

        for (index, var bookmark) in updatedBookmarks.enumerated() {
            bookmark.order = index
            updatedBookmarks[index] = bookmark
        }

        do {
            bookmarks = updatedBookmarks
            try await persistBookmarks()
            objectWillChange.send()
        } catch {
            // Revert changes on failure
            bookmarks = bookmarks
            objectWillChange.send()
        }
    }

    private func setupFaviconUpdateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFaviconUpdate),
            name: .faviconDidUpdate,
            object: nil
        )
    }

    @objc private func handleFaviconUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let bookmarkID = userInfo["bookmarkID"] as? UUID,
              let iconData = userInfo["iconData"] as? Data,
              let bookmark = bookmarks.first(where: { $0.id == bookmarkID })
        else {
            return
        }

        Task { @MainActor in
            await updateBookmarkIcon(bookmark: bookmark, iconData: iconData, isManualUpload: false)
        }
    }
}

// MARK: - Private Helpers

extension BookmarkViewModel {
    func persistBookmarks() async throws {
        try await bookmarkService.saveBookmarks(bookmarks)
    }

    func handleError(_: Error, operation _: String) {
        // Error handling can be extended here if needed
    }
}
