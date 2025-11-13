/// PreferencesService.swift
/// Service for managing user preferences and settings.
/// Provides type-safe storage and retrieval of app preferences.

import Foundation

// MARK: - Preferences Service Protocol

protocol PreferencesServiceProtocol {
    /// Loads preferences from disk
    func loadPreferences() async throws -> AppPreferences

    /// Saves preferences to disk
    func savePreferences(_ preferences: AppPreferences) async throws
}

// MARK: - Preferences Service Implementation

final class PreferencesService: PreferencesServiceProtocol {
    // MARK: - Properties

    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Constants

    private enum Constants {
        static let fileName = "preferences.json"
        static let directoryName = "NeoNav"
    }

    // MARK: - Initialization

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

    // MARK: - Public Methods

    func loadPreferences() async throws -> AppPreferences {
        guard let url = try? getPreferencesURL() else {
            return AppPreferences()
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(AppPreferences.self, from: data)
        } catch {
            return AppPreferences()
        }
    }

    func savePreferences(_ preferences: AppPreferences) async throws {
        let url = try getPreferencesURL()
        let data = try encoder.encode(preferences)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Private Methods

    private func getPreferencesURL() throws -> URL {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PreferencesError.invalidURL
        }

        let directoryURL = appSupportURL.appendingPathComponent(Constants.directoryName, isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent(Constants.fileName)
    }
}

// MARK: - Preferences Error

enum PreferencesError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Could not determine preferences file location"
        }
    }
}
