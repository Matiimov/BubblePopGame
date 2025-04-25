import SwiftUI

/// **Bubble.swift**
/// Defines the BubbleColorType and Bubble structures used in the game.
/// BubbleColorType encapsulates scoring, display color, spawn probabilities per color, and time bonuses.

/// Represents all possible bubble colors and their associated behaviors
enum BubbleColorType: CaseIterable {
    case red, pink, green, blue, black, gold

    /// **Base points** awarded when popping this bubble
    var points: Int {
        switch self {
        case .red:   return 1
        case .pink:  return 2
        case .green: return 5
        case .blue:  return 8
        case .black: return 10
        case .gold:  return 0 /// Gold bubbles give no points (time bonus instead)
        }
    }

    /// **Bonus time** awarded only when popping a gold bubble
    var timeBonus: Int {
        switch self {
        case .gold: return 10 /// Only gold bubbles grant extra time
        default:    return 0 /// Other colors grant no time bonus
        }
    }

    /// **Display color** Render the bubble with the right color on screen
    var color: Color {
        switch self {
        case .red:   return .red
        case .pink:  return .pink
        case .green: return .green
        case .blue:  return .blue
        case .black: return .black
        case .gold:
              return Color(
                  red: 212/255,
                  green: 175/255,
                  blue: 55/255
              ) /// Custom gold RGB for special bubbles
          }
    }

    /// **Standard bubble types** (excludes gold)
    static let normalCases: [BubbleColorType] = [.red, .pink, .green, .blue, .black]

    /// **Spawn probability** for each normal bubble
    var probability: Double {
        switch self {
        case .red:   return 0.40
        case .pink:  return 0.30
        case .green: return 0.15
        case .blue:  return 0.10
        case .black: return 0.05
        case .gold:  return 0 /// Gold is handled separately with a fixed chance
        }
    }
}

/// Represents a single bubble instance in the game
struct Bubble: Identifiable {
    let id = UUID() /// Unique identifier for this bubble
    let type: BubbleColorType
    var position: CGPoint /// Current position in the play area
    var direction: CGVector /// Direction unit vector indicating bubble movement
}
