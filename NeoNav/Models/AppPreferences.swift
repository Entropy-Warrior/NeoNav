/// AppPreferences.swift
/// Model for managing application preferences and settings.
/// This file contains:
/// - User interface preferences
/// - Layout and appearance settings
/// - Default values and initialization
/// - Codable implementation for persistence
/// The model provides a centralized way to manage app configuration.

import Foundation
import SwiftUI

// MARK: - App Preferences

struct AppPreferences: Codable {
    var stripTheme: StripTheme = .system
    var stripOpacity: Double = 0.2
    var showLabels: Bool = true

    var effectiveBackgroundColor: Color {
        switch stripTheme {
        case .system:
            Color.black
        case .light:
            Color.white
        case .dark:
            Color.black
        }
    }

    var effectiveTextColor: Color {
        switch stripTheme {
        case .system:
            .white
        case .light:
            .black
        case .dark:
            .white
        }
    }
}

// MARK: - Strip Theme

enum StripTheme: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Color Codable Extension

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let a = try container.decode(Double.self, forKey: .alpha)

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        NSColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)

        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(a, forKey: .alpha)
    }
}
