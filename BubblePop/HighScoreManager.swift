import Foundation

/// A single high‐score entry
struct HighScore: Codable, Identifiable {
    let id: UUID
    let name: String
    let score: Int
}

enum HighScoreManager {
    private static let key = "highScores"

    /// Load all saved high scores (up to 10)
    static func loadHighScores() -> [HighScore] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let scores = try? JSONDecoder().decode([HighScore].self, from: data)
        else {
            return []
        }
        return scores
    }

    /// Add or update the given player's best score, keep top 10
    /// - Returns: the new sorted high score list
    @discardableResult
    static func update(name: String, score: Int) -> [HighScore] {
        var scores = loadHighScores()

        if let idx = scores.firstIndex(where: { $0.name == name }) {
            // existing player—only update if this score is higher
            if score > scores[idx].score {
                scores[idx] = HighScore(id: scores[idx].id, name: name, score: score)
            }
        } else {
            // new player
            scores.append(HighScore(id: UUID(), name: name, score: score))
        }

        // sort descending, trim to 10
        scores.sort { $0.score > $1.score }
        if scores.count > 10 {
            scores = Array(scores.prefix(10))
        }

        // persist
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: key)
        }

        return scores
    }
}
