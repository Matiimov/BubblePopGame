// GameEngine.swift

import SwiftUI
import Combine

/// **GameEngine.swift**
/// ObservableObject encapsulating game logic: timers, bubble spawning, scoring, and state.
final class GameEngine: ObservableObject {
    // MARK: - Persisted Settings
    @AppStorage("gameDuration") var gameDuration: Int = 60
    @AppStorage("maxBubbles")   var maxBubbles:   Int = 15

    // MARK: - Published State
    @Published var playerName: String = ""            /// Set by ContentView
    @Published var bubbles: [Bubble] = []
    @Published var score = 0
    @Published var timeRemaining = 0
    @Published var isGameOver = false
    @Published var topThree: [HighScore] = []
    @Published var isCountingDown = true
    @Published var countdownValue = 3
    @Published var popEffects: [PopEffect] = []
    @Published var poppedBubbleIDs: Set<UUID> = []    /// IDs of bubbles in pop-animation
    @Published var playAreaSize: CGSize = .zero    /// Current size of the play area for bubble placement

    // MARK: - Configuration
    private let baseSpeed: CGFloat = 100    /// Speed at the start of the game
    private let maxSpeed: CGFloat = 400    /// Speed at the end of the game
    let bubbleDiameter: CGFloat = 70    /// Diameter of each bubble (points)
    private let hudHeight: CGFloat = 60    /// Reserved height  for the heads-up display

    // MARK: - Timers
    private var gameTimer: AnyCancellable?
    private var movementTimer: AnyCancellable?

    // MARK: - Pop & Scoring
    /// Tracking for consecutive colour pops
    private var lastPoppedColor: BubbleColorType?
    private var consecutivePopCount: Int = 0
    
    // MARK: - Initialization
    init() {
        runCountdown()  /// Begin 3-2-1 countdown (bubbles start after countdown)

        /// 1 Hz game timer: countdown and game-state updates
        gameTimer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      !self.isCountingDown,
                      self.timeRemaining > 0
                else { return }

                self.timeRemaining -= 1  /// Decrement timer
                self.refreshBubbles(in: self.playAreaSize)  /// Refreshing bubbles

                /// Called when the countdown hits zero
                if self.timeRemaining == 0 {
                    /// Persist the current score and retrieve the updated list
                    let all = HighScoreManager.update(name: self.playerName,
                                                      score: self.score)
                    self.topThree = Array(all.prefix(3))   /// Select the top three scores for the Game Over screen
                    self.isGameOver = true  /// End the game
                }
            }

        /// 30 Hz movement timer: update bubble positions
        movementTimer = Timer
            .publish(every: 1.0/30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      !self.isCountingDown,
                      !self.isGameOver
                else { return }

                let progress = CGFloat(self.gameDuration - self.timeRemaining)
                             / CGFloat(self.gameDuration)
                let speed = self.baseSpeed
                          + progress * (self.maxSpeed - self.baseSpeed)
                let dt = CGFloat(1.0/30.0)

                /// Move each bubble
                for index in self.bubbles.indices {
                    self.bubbles[index].position.x +=
                        self.bubbles[index].direction.dx * speed * dt
                    self.bubbles[index].position.y +=
                        self.bubbles[index].direction.dy * speed * dt
                }

                /// Remove off-screen bubbles
                self.bubbles.removeAll { b in
                    let x = b.position.x, y = b.position.y
                    return x < -self.bubbleDiameter
                        || x > self.playAreaSize.width + self.bubbleDiameter
                        || y < self.hudHeight - self.bubbleDiameter
                        || y > self.playAreaSize.height + self.hudHeight
                }
            }
    }

    // MARK: - Countdown Logic
    /// Runs the 3-2-1 countdown then starts the game
    func runCountdown() {
        guard countdownValue >= 0 else { return }
        if countdownValue > 0 {
            /// Schedule the next tick in one second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.countdownValue -= 1
                self.runCountdown()
            }
        } else {
            isCountingDown = false
            startGame(in: playAreaSize)
        }
    }

    // MARK: - Game Lifecycle
    /// Reset and begin a new game session
    func startGame(in size: CGSize) {
        score = 0
        isGameOver = false
        timeRemaining = gameDuration     /// Set timer to persisted duration
        poppedBubbleIDs.removeAll()      /// Clear any ongoing pop animations
        /// Place a random number of non-overlapping bubbles
        bubbles = placeBubbles(
            count: Int.random(in: 1...maxBubbles),
            in: size,
            existing: []
        )
    }

    /// Adjust active bubbles: trim or add randomly
    func refreshBubbles(in size: CGSize) {
        ///  Determine new bubble count
        let newTotal = Int.random(in: 1...maxBubbles)
        /// Randomly keep up to newTotal of the existing bubbles
        var kept = bubbles.shuffled()
                         .prefix(min(bubbles.count, newTotal))
                         .map { $0 }
        /// Calculate how many to add and append them
        let toAdd = newTotal - kept.count
        for _ in 0..<toAdd {
            kept.append(makeBubble(in: size))
        }
        /// Commit the updated bubble list
        bubbles = kept
    }

    // MARK: - Bubble Factory
    /// Create a single bubble at random position & direction
    func makeBubble(in size: CGSize) -> Bubble {
        let radius = bubbleDiameter / 2
        let x = CGFloat.random(in: radius...size.width - radius)
        let y = CGFloat.random(in: (hudHeight + radius)...size.height - radius)
        let angle = Double.random(in: 0..<2*Double.pi)
        let dir = CGVector(dx: cos(angle), dy: sin(angle))
        return Bubble(type: randomBubbleType(),
                      position: CGPoint(x: x, y: y),
                      direction: dir)
    }

    /// Place multiple non-overlapping bubbles
    func placeBubbles(count: Int,
                      in size: CGSize,
                      existing: [Bubble]) -> [Bubble] {
        var result: [Bubble] = []
        let diameter = bubbleDiameter   /// Used to detect overlap distance
        let maxAttempts = 30     /// Prevent infinite loop on tight spaces
        for _ in 0..<count {
            var attempts = 0, placed = false
            /// Try placing a new bubble until it fits
            while attempts < maxAttempts && !placed {
                let candidate = makeBubble(in: size) /// Random position & direction
                let collision = (existing + result).contains { other in /// Check for collision with all existing + already placed bubbles
                    let dx = other.position.x - candidate.position.x
                    let dy = other.position.y - candidate.position.y
                    return sqrt(dx*dx + dy*dy) < diameter
                }
                if !collision {
                    result.append(candidate) /// No overlap: accept placement
                    placed = true       /// Successful placement
                }
                attempts += 1
            }
        }
        return result
    }

    // MARK: - Pop & Scoring
    /// Handle bubble pop: show effect, update score/time, remove bubble
    func pop(_ bubble: Bubble) {
        if bubble.type == .gold {
            popEffects.append(
                PopEffect(position: bubble.position,
                          text: "+10s")
            )        /// Display time bonus popup for gold bubbles
        }
        
        /// Update consecutive-pop tracking
        if bubble.type == lastPoppedColor {
            consecutivePopCount += 1
        } else {
            lastPoppedColor = bubble.type
            consecutivePopCount = 0
        }
        
        /// Calculate points with 1.5× bonus on 2nd+ consecutive pop
        let pointsToAdd = consecutivePopCount > 0
            ? Int(Double(bubble.type.points) * 1.5)
            : bubble.type.points
        
        poppedBubbleIDs.insert(bubble.id)        /// Trigger pop animation
        score += pointsToAdd                     /// Add points for regular bubbles (with streak bonus)
        timeRemaining += bubble.type.timeBonus   /// Add time bonus for gold bubbles

        /// Remove bubble model after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.bubbles.removeAll { $0.id == bubble.id }
            self.poppedBubbleIDs.remove(bubble.id)
        }
    }

    // MARK: - Bubble Color Selection
    /// Randomly choose a bubble type, including a small chance for gold
    func randomBubbleType() -> BubbleColorType {
        let goldChance = 0.03  /// 3% chance for power-ups
        let r0 = Double.random(in: 0...1)
        if r0 < goldChance { return .gold }
        let r = (r0 - goldChance) / (1 - goldChance)    /// Rescale the remaining probability mass to [0,1)
        var cum = 0.0
        for t in BubbleColorType.normalCases {
            cum += t.probability
            if r < cum { return t }
        }
        return .red  /// Fallback
    }
}
