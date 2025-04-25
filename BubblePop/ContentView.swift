import SwiftUI

/// **ContentView.swift**
/// Main gameplay screen: handles bubble spawning, movement, pop animations, scoring, countdown, HUD display, and game-over flow.

struct ContentView: View {
    // MARK: -  Input
    let playerName: String   /// The player's chosen username displayed on the HUD

    // MARK: - Persisted Settings
    @AppStorage("gameDuration") private var gameDuration: Int = 60  /// Total seconds for each game
    @AppStorage("maxBubbles")   private var maxBubbles:   Int = 15  /// Maximum bubbles onscreen simultaneously

    // MARK: - Game State
    @State private var bubbles: [Bubble] = []           /// Current bubbles in play
    @State private var score = 0                        /// Player's running score
    @State private var timeRemaining = 0                /// Seconds left in this game
    @State private var isGameOver = false               /// Flag to show Game Over overlay
    @State private var topThree: [HighScore] = []       /// Top three high-score entries to display

    // MARK: - Countdown State
    @State private var isCountingDown = true            /// Flag for the 3-2-1 pre-game countdown
    @State private var countdownValue = 3               /// Current countdown number shown

    // MARK: - Pop Animation State
    @State private var poppedBubbleIDs: Set<UUID> = []  /// IDs of bubbles currently animating pop effect

    // MARK: - Layout
    @Environment(\.dismiss) private var dismiss       /// Allows dismissing full-screen views
    @State private var playAreaSize: CGSize = .zero     /// Captured size of gameplay area

    // MARK: - Timers
    private let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()       /// 1‑second tick for countdown and game logic
    private let movementTimer = Timer.publish(every: 1.0/30.0, on: .main, in: .common).autoconnect()  /// 30‑Hz tick for bubble movement

    // MARK: - Constants
    private let baseSpeed: CGFloat = 60     /// Speed at game start
    private let maxSpeed: CGFloat = 300     /// Speed at game end
    private let bubbleDiameter: CGFloat = 60 /// Bubble size in points
    private let hudHeight: CGFloat = 60      /// Reserved height for HUD at top
    
    // MARK: - Pop Effect Model
    /// Represents a temporary floating text (e.g., "+10s") when popping a gold bubble
    struct PopEffect: Identifiable {
        let id = UUID()
        let position: CGPoint  /// Screen location for the floating text
        let text: String       /// The message to display (e.g., "+10s")
    }
    
    @State private var popEffects: [PopEffect] = []  /// Active pop effects to render

    var body: some View {
        GeometryReader { geo in  // Capture available play area size
            ZStack {
                // MARK: 1) Render Pop Effects
                ForEach(popEffects) { effect in
                    Text(effect.text)
                        .font(.system(size: 48, weight: .bold))
                        .scaleEffect(1.2)                              /// Slight extra scaling for visual effect
                        .foregroundColor(.yellow)
                        .position(effect.position)                     /// Place at bubble's pop location
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onAppear {                                     /// Remove effect after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    popEffects.removeAll { $0.id == effect.id }
                                }
                            }
                        }
                }
                
                // MARK: 2) Render Bubbles
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(bubble.type.color)
                        .frame(width: bubbleDiameter, height: bubbleDiameter)
                        .position(bubble.position)
                        .scaleEffect(poppedBubbleIDs.contains(bubble.id) ? 1.5 : 1)  /// Pop animation scale
                        .opacity(poppedBubbleIDs.contains(bubble.id) ? 0 : 1)      /// Fade out when popped
                        .animation(.easeOut(duration: 0.2), value: poppedBubbleIDs)
                        .onTapGesture {
                            guard !isGameOver, !isCountingDown else { return }
                            pop(bubble)  /// Handle bubble pop: scoring, animation, effects
                        }
                }

                // MARK: 3) Heads-Up Display (HUD)
                VStack {
                    HStack(spacing: 20) {
                        Text(playerName)                                       /// Show player name
                        Spacer()
                        Text("Time Left: \(timeRemaining)s")               /// Remaining time
                        Spacer()
                        Text("Score: \(score)")                            /// Current score
                        Spacer()
                        Text("High Score: \(HighScoreManager.loadHighScores().first?.score ?? 0)")  /// All-time best
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    Spacer()
                }
                .disabled(isGameOver)  /// Prevent interaction when game over

                // MARK: 4) Pre-Game Countdown Overlay
                if isCountingDown {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    Text("\(countdownValue)")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                        .onAppear(perform: runCountdown)  /// Start 3-2-1 countdown when shown
                }

                // MARK: 5) Game Over Overlay
                if isGameOver && !isCountingDown {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("GAME OVER, \(playerName)!")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        Text("Your Score: \(score)")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Top 3 Scores")
                            .font(.headline)
                            .foregroundColor(.white)

                        // Display top-three leaderboard
                        VStack(spacing: 8) {
                            ForEach(topThree) { entry in
                                HStack {
                                    Text(entry.name).foregroundColor(.white)
                                    Spacer()
                                    Text("\(entry.score)").foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)

                        // Replay and return buttons
                        HStack(spacing: 30) {
                            Button("Play Again") { startGame(in: playAreaSize) }
                                .styledGameButton()
                            Button("Main Menu") { dismiss() }
                                .styledGameButton()
                        }
                    }
                    .padding()
                }
            }
            // Capture geometry and start countdown on appear
            .onAppear {
                playAreaSize = geo.size      /// Store play area for bubble placement
                countdownValue = 3           /// Reset countdown value
                isCountingDown = true        /// Trigger countdown overlay
            }
            // MARK: - Game Timer (1 Hz)
            .onReceive(gameTimer) { _ in
                guard !isCountingDown, timeRemaining > 0 else { return }
                timeRemaining -= 1           /// Decrement game timer each second
                refreshBubbles(in: playAreaSize)  /// Possibly add/remove bubbles
                if timeRemaining == 0 {
                    let allScores = HighScoreManager.update(name: playerName, score: score)
                    topThree = Array(allScores.prefix(3))  /// Grab top 3 for display
                    isGameOver = true
                }
            }
            // MARK: - Movement Timer (30 Hz)
            .onReceive(movementTimer) { _ in
                guard !isCountingDown, !isGameOver else { return }
                let progress = CGFloat(gameDuration - timeRemaining) / CGFloat(gameDuration)
                let speed = baseSpeed + progress * (maxSpeed - baseSpeed)  /// Ramp speed over time
                let dt = CGFloat(1.0/30.0)
                // Update positions
                for i in bubbles.indices {
                    bubbles[i].position.x += bubbles[i].direction.dx * speed * dt
                    bubbles[i].position.y += bubbles[i].direction.dy * speed * dt
                }
                // Remove bubbles that moved off-screen
                bubbles.removeAll { b in
                    let x = b.position.x, y = b.position.y
                    return x < -bubbleDiameter
                        || x > playAreaSize.width + bubbleDiameter
                        || y < hudHeight - bubbleDiameter
                        || y > playAreaSize.height + bubbleDiameter
                }
            }
        }
    }

    // MARK: - Countdown Logic
    /// Runs the 3-2-1 countdown then starts the game
    private func runCountdown() {
        guard countdownValue >= 0 else { return }
        if countdownValue > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdownValue -= 1
                runCountdown()
            }
        } else {
            isCountingDown = false
            startGame(in: playAreaSize)
        }
    }

    // MARK: - Game Lifecycle
    /// Reset and begin a new game session
    private func startGame(in size: CGSize) {
        score = 0
        isGameOver = false
        timeRemaining = gameDuration
        poppedBubbleIDs.removeAll()
        bubbles = placeBubbles(count: Int.random(in: 1...maxBubbles),
                               in: size,
                               existing: [])
    }

    /// Adjust active bubbles: trim or add randomly
    private func refreshBubbles(in size: CGSize) {
        let newTotal = Int.random(in: 1...maxBubbles)
        var kept = bubbles.shuffled()
                         .prefix(min(bubbles.count, newTotal))
                         .map { $0 }
        let toAdd = newTotal - kept.count
        for _ in 0..<toAdd {
            kept.append(makeBubble(in: size))
        }
        bubbles = kept
    }

    // MARK: - Bubble Factory
    /// Create a single bubble at random position & direction
    private func makeBubble(in size: CGSize) -> Bubble {
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
    private func placeBubbles(count: Int, in size: CGSize,existing: [Bubble]) -> [Bubble] {
        var result: [Bubble] = []
        let diameter = bubbleDiameter
        let maxAttempts = 30     /// Prevent infinite loop on tight spaces
        for _ in 0..<count {
            var attempts = 0, placed = false
            while attempts < maxAttempts && !placed {
                let candidate = makeBubble(in: size)
                let collision = (existing + result).contains { other in
                    let dx = other.position.x - candidate.position.x
                    let dy = other.position.y - candidate.position.y
                    return sqrt(dx*dx + dy*dy) < diameter
                }
                if !collision {
                    result.append(candidate)
                    placed = true       /// Successful placement
                }
                attempts += 1
            }
        }
        return result
    }

    // MARK: - Pop & Scoring
    /// Handle bubble pop: show effect, update score/time, remove bubble
    private func pop(_ bubble: Bubble) {
        if bubble.type == .gold {
            popEffects.append(
                PopEffect(position: bubble.position, text: "+10s") /// Display time bonus popup for gold bubbles
            )
        }

        poppedBubbleIDs.insert(bubble.id)           /// Trigger pop animation
        score += bubble.type.points                 /// Add points for regular bubbles
        timeRemaining += bubble.type.timeBonus      /// Add time bonus for gold bubbles

        // Remove bubble model after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            bubbles.removeAll { $0.id == bubble.id }
            poppedBubbleIDs.remove(bubble.id)
        }
    }

    // MARK: - Bubble Color Selection
    /// Randomly choose a bubble type, including a small chance for gold
    private func randomBubbleType() -> BubbleColorType {
        let goldChance = 0.03 /// 3% chance to spawn gold bubble
        let r0 = Double.random(in: 0...1)
        if r0 < goldChance { return .gold }  /// Fixed chance for gold bubble
        let r = (r0 - goldChance) / (1 - goldChance)
        var cum = 0.0
        for t in BubbleColorType.normalCases {
            cum += t.probability
            if r < cum { return t }
        }
        return .red
    }
}

// MARK: - Styled Button Helper
private extension View {
    /// Standard appearance for game buttons (Play Again, Main Menu)
    func styledGameButton() -> some View {
        self.font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(8)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(playerName: "Tester")  /// Preview using a sample player name
    }
}
