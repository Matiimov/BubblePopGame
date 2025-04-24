import SwiftUI

enum BubbleColorType: CaseIterable {
    case red, pink, green, blue, black

    var points: Int {
        switch self {
        case .red:   return 1
        case .pink:  return 2
        case .green: return 5
        case .blue:  return 8
        case .black: return 10
        }
    }

    var probability: Double {
        switch self {
        case .red:   return 0.40
        case .pink:  return 0.30
        case .green: return 0.15
        case .blue:  return 0.10
        case .black: return 0.05
        }
    }

    var color: Color {
        switch self {
        case .red:   return .red
        case .pink:  return .pink
        case .green: return .green
        case .blue:  return .blue
        case .black: return .black
        }
    }
}

struct Bubble: Identifiable {
    let id = UUID()
    let type: BubbleColorType
    var position: CGPoint
}
