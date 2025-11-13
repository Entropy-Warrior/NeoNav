/// LocalPersistenceManager.swift
/// Manager for handling local data persistence operations.
/// Handles JSON-based file storage with atomic writes for data safety.

import Foundation

// MARK: - Local Persistence Manager

final class LocalPersistenceManager {
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
        encoder.outputFormatting = .prettyPrinted
    }

    func fetchBookmarks() async throws -> [Bookmark] {
        guard let url = try? getBookmarksURL() else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([Bookmark].self, from: data)
        } catch {
            return []
        }
    }

    func saveBookmarks(_ bookmarks: [Bookmark]) async throws {
        let url = try getBookmarksURL()
        let data = try encoder.encode(bookmarks)
        try data.write(to: url, options: .atomic)
    }

    private func getBookmarksURL() throws -> URL {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PersistenceError.invalidURL
        }

        let directoryURL = appSupportURL.appendingPathComponent("NeoNav", isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent("bookmarks.json")
    }
}

// MARK: - Persistence Error

enum PersistenceError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not determine bookmarks file location"
        }
    }
}
