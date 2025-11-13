/// BookmarkSelectionManager.swift
/// Manager for handling bookmark selection state and operations.
/// Tracks selected bookmark and coordinates with view model for deletions.

import Foundation

// MARK: - Selection Manager

@MainActor
final class BookmarkSelectionManager: ObservableObject {
    @Published private(set) var selectedBookmark: Bookmark?
    private var viewModel: BookmarkViewModel

    init(viewModel: BookmarkViewModel) {
        self.viewModel = viewModel
    }

    func select(_ bookmark: Bookmark?) {
        Task { @MainActor in
            selectedBookmark = bookmark
        }
    }

    func deleteSelected() async {
        guard let bookmark = selectedBookmark else { return }
        await viewModel.deleteBookmark(bookmark: bookmark)
        selectedBookmark = nil
    }

    func handleBookmarksChange(_ bookmarks: [Bookmark]) {
        Task { @MainActor in
            if let selected = selectedBookmark,
               !bookmarks.contains(where: { $0.id == selected.id })
            {
                selectedBookmark = nil
            }
        }
    }

    func updateViewModel(_ newViewModel: BookmarkViewModel) {
        viewModel = newViewModel
    }

    func getUpdatedBookmark() -> Bookmark? {
        guard let selected = selectedBookmark else { return nil }
        return viewModel.bookmarks.first { $0.id == selected.id }
    }
}
