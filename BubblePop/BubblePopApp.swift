import SwiftUI

@main
struct BubblePopApp: App {
    init() {
        // These values are only used if no user‐set value exists.
        UserDefaults.standard.register(defaults: [
            "gameDuration": 60,
            "maxBubbles": 15
        ])
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
