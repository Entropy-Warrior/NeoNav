# Architecture

I kept it simple. MVVM (Model-View-ViewModel) with a service layer. No over-engineering. No unnecessary abstractions. Just clean separation of concerns that actually makes sense.

![Architecture Diagram](../images/architecture.svg)

There's the diagram. Look at it. Then read the rest. Or don't. Your call.

## Project Structure

```
NeoNav/
├── Models/              # Bookmark, AppPreferences
├── Views/               # SwiftUI views
├── ViewModels/          # State management (@MainActor)
├── Services/            # Business logic (protocol-oriented)
├── Controllers/         # FloatingWindowController
└── Utilities/           # Helpers
```

## Architecture Overview

**MVVM (Model-View-ViewModel) + Service Layer:**
- **Models**: Pure data structures (`Codable`, `Identifiable`)
- **Views**: SwiftUI declarative UI
- **ViewModels**: State management with `@MainActor` for thread safety
- **Services**: Protocol-oriented business logic (testable, swappable)

## Key Components

### Floating Window
Custom `NSWindow` subclass that:
- Stays on top without stealing focus (`canBecomeKey: false`)
- Appears on all Mission Control spaces
- Persists position via UserDefaults

### Favicon Fetching
Three-tier strategy:
1. Parse HTML for `<link rel="icon">`
2. Try standard locations (`/favicon.ico`, `/favicon.png`)
3. Fallback to Google's public favicon service

All favicons cached locally (URLCache, 50MB limit).

### Data Persistence
- **Bookmarks**: JSON at `~/Library/Application Support/NeoNav/bookmarks.json`
- **Preferences**: JSON at `~/Library/Application Support/NeoNav/preferences.json`
- **Window State**: UserDefaults (position, size)

Atomic writes ensure data integrity.

## Concurrency

- `@MainActor` on all ViewModels (UI thread safety)
- `async/await` for service operations
- Task groups for concurrent favicon fetching (max 5 concurrent)
- Background processing for icon fetching (non-blocking)

## Design Decisions

**Floating Window vs Menu Bar**: Instant visual access, works across spaces, doesn't steal focus.

**JSON vs Core Data**: Simple, human-readable, fast enough for <1000 bookmarks, zero dependencies.

**SwiftUI + AppKit**: SwiftUI for UI, AppKit for custom window behavior (floating, no-focus).

**Protocol-Oriented Services**: Testable, swappable, clear contracts.

## Code Highlights

### Custom Floating Window
```swift
class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func makeKey() { /* empty - blocks focus */ }
}
```

### Multi-Strategy Favicon Fetching
```swift
// Try HTML parsing first, then standard locations, then Google service
let icon = try await fetchFromHTML() 
    ?? try await fetchFromStandardLocation() 
    ?? try await fetchFromGoogleService()
```

### Real-Time Drag-and-Drop Preview
Uses `NotificationCenter` to coordinate preview state between `ImageDropHandler` and `BookmarkIconView` without tight coupling.

## Technology Stack

- **SwiftUI** + **AppKit** (hybrid approach)
- **Combine** (`@Published` for reactive state)
- **async/await** (structured concurrency)
- **URLCache** (favicon caching)
- **UserDefaults** (window state)
- **JSON** (data persistence)

No third-party dependencies. Pure Apple frameworks.

