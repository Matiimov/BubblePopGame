import SwiftUI

/// **BubblePopApp.swift**
/// App entry point. Registers default game settings and launches the HomeView.

@main
struct BubblePopApp: App {
    /// Initialize default values for game duration and bubble count
    init() {
        // These values apply only if the user has not customized settings
        UserDefaults.standard.register(defaults: [
            "gameDuration": 60, /// Default to 60 seconds per game
            "maxBubbles": 15 /// Default to 15 bubbles on screen
        ])
    }

    /// The main scene of the app, showing the HomeView
    var body: some Scene {
        WindowGroup {
            HomeView() /// Starts at the home screen
        }
    }
}
