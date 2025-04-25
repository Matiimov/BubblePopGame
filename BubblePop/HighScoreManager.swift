import Foundation

/// **HighScoreManager.swift**
/// Handles loading, updating, and persisting the top 10 high scores using UserDefaults.

/// Represents a single high-score record with unique ID, player name, and score.
struct HighScore: Codable, Identifiable {
    let id: UUID       /// Unique identifier for this score entry
    let name: String   /// Player's name or nickname
    let score: Int     /// Player's achieved score
}

/// Manages high-score data lifecycle
enum HighScoreManager {
    /// Key used to archive high-score data in UserDefaults
    private static let key = "highScores"

    /// Load all saved high scores (up to 10 entries)
    /// - Returns: An array of HighScore sorted in descending order, or empty if none
    static func loadHighScores() -> [HighScore] {
        // Retrieve raw data from UserDefaults
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let scores = try? JSONDecoder().decode([HighScore].self, from: data) // Decode into [HighScore]
        else {
            return []  /// No stored data or decode failure
        }
        return scores
    }

    /// Add or update a player's best score and maintain the top 10 list.
    /// - Parameters:
    ///   - name: The player's name to record or update
    ///   - score: The new score achieved by the player
    /// - Returns: The updated, sorted list of HighScore entries
    @discardableResult
    static func update(name: String, score: Int) -> [HighScore] {
        // Load existing scores from storage
        var scores = loadHighScores()

        if let index = scores.firstIndex(where: { $0.name == name }) {
            // Existing player: update only if new score is higher
            if score > scores[index].score {
                scores[index] = HighScore(id: scores[index].id, name: name, score: score)
            }
        } else {
            // New player: append a new entry
            let newEntry = HighScore(id: UUID(), name: name, score: score)
            scores.append(newEntry)
        }

        // Sort scores descending by score value
        scores.sort { $0.score > $1.score }

        // Trim list to top 10 entries
        if scores.count > 10 {
            scores = Array(scores.prefix(10))
        }

        // Persist updated list back to UserDefaults
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: key)
        }

        return scores  /// Return the updated high-score list
    }
}
