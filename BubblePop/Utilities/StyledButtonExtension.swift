import SwiftUI

/// **StyledButton.swift**
/// Provides a reusable button style for all game-related buttons.
extension View {
    /// Standard appearance for game buttons (Play Again, Main Menu)
    func styledGameButton() -> some View {
        self.font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(8)
    }
}
