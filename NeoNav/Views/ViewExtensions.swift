//
//  ViewExtensions.swift
//  NeoNav
//
//  Created by Lin Wang on 12/23/24.
//

import SwiftUI

// MARK: - Scene Phase Extensions

/// Extensions for handling scene lifecycle events in SwiftUI views
extension View {
    /// Executes an action when the scene becomes active
    /// - Parameter action: The closure to execute when scene phase changes to .active
    /// - Returns: A view with the scene phase monitoring modifier attached
    func onSceneActive(perform action: @escaping () -> Void) -> some View {
        modifier(SceneActiveModifier(action: action))
    }
}

// MARK: - Scene Active Modifier

/// A custom view modifier that monitors scene phase changes
/// and executes an action when the scene becomes active.
///
/// Usage:
/// ```swift
/// MyView()
///     .modifier(SceneActiveModifier {
///         // Action to perform when scene becomes active
///     })
/// ```
private struct SceneActiveModifier: ViewModifier {
    // MARK: - Properties

    /// The action to perform when scene becomes active
    let action: () -> Void

    /// The current phase of the scene
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    func body(content: Content) -> some View {
        content.onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                action()
            }
        }
    }
}
