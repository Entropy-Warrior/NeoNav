/// PreferencesViewModel.swift
/// View model for managing user preferences and settings.
/// Provides reactive interface for app settings with automatic persistence.

import Foundation
import SwiftUI

// MARK: - Preferences ViewModel

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published private(set) var preferences: AppPreferences
    private let preferencesService: PreferencesServiceProtocol

    init(preferencesService: PreferencesServiceProtocol = PreferencesService()) {
        self.preferencesService = preferencesService
        preferences = AppPreferences()

        Task {
            await loadPreferences()
        }
    }

    private func loadPreferences() async {
        do {
            preferences = try await preferencesService.loadPreferences()
        } catch {
            // Use default preferences on error
        }
    }

    func updatePreferences(_ newPreferences: AppPreferences) async {
        preferences = newPreferences
        try? await preferencesService.savePreferences(newPreferences)
    }
}
