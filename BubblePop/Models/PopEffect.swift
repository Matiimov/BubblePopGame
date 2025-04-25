import SwiftUI

/// Represents a temporary floating text (e.g., "+10s") when popping a gold bubble
struct PopEffect: Identifiable {
    let id = UUID()
    let position: CGPoint
    let text: String
}
