import SwiftUI

struct ContentView: View {
    let playerName: String

    /// Diameter for each bubble
    private let bubbleDiameter: CGFloat = 70
    
    // Height reserved at top for the name/time/score HUD
    private let hudHeight: CGFloat = 60
    
    // Persisted settings (registered defaults in App init)
    @AppStorage("gameDuration") private var gameDuration: Int = 60
    @AppStorage("maxBubbles")   private var maxBubbles:   Int = 15

    // Game state
    @State private var bubbles: [Bubble] = []
    @State private var score = 0
    @State private var timeRemaining = 0
    @State private var isGameOver = false
    @State private var lastPoppedType: BubbleColorType? = nil
    @State private var consecutivePops = 0

    // Top 3 to show on game over
    @State private var topThree: [HighScore] = []

    // To dismiss back to HomeView
    @Environment(\.dismiss) private var dismiss

    // Timer publisher
    private let gameTimer = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()

    // Hold the play area size
    @State private var playAreaSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) BUBBLES
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(bubble.type.color)
                        .frame(width: bubbleDiameter, height: bubbleDiameter)
                        .position(bubble.position)
                        .onTapGesture {
                            guard !isGameOver else { return }
                            pop(bubble)
                        }
                }

                // 2) HUD
                VStack {
                    HStack(spacing: 20) {
                        Text(playerName)
                        Spacer()
                        Text("Time Left: \(timeRemaining)s")
                        Spacer()
                        Text("Score: \(score)")
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                }
                .disabled(isGameOver)

                // 3) GAME OVER + TOP 3
                if isGameOver {
                    Color.black.opacity(0.6).ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("GAME OVER, \(playerName)!")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)

                        Text("Your Score: \(score)")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("Top 3 Players")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            ForEach(topThree) { entry in
                                HStack {
                                    Text(entry.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(entry.score)")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)

                        HStack(spacing: 30) {
                            Button("Play Again") {
                                startGame(in: playAreaSize)
                            }
                            .styledGameButton()

                            Button("Main Menu") {
                                dismiss()
                            }
                            .styledGameButton()
                        }
                    }
                    .padding()
                }
            }
            // Capture size & start
            .onAppear {
                playAreaSize = geo.size
                startGame(in: geo.size)
            }
            // Tick handling
            .onReceive(gameTimer) { _ in
                if timeRemaining > 0 {
                    // still playing
                    timeRemaining -= 1
                    refreshBubbles(in: playAreaSize)

                    // if we just hit zero, finalize
                    if timeRemaining == 0 {
                        let allScores = HighScoreManager
                            .update(name: playerName, score: score)
                        topThree = Array(allScores.prefix(3))
                        isGameOver = true
                    }
                }
                // else—already game over, do nothing
            }
        }
    }

    // MARK: – Game Lifecycle

    private func startGame(in size: CGSize) {
        score = 0
        isGameOver = false
        timeRemaining = gameDuration
        bubbles = placeBubbles(
            count: Int.random(in: 1...maxBubbles),
            in: size,
            existing: []
        )
    }

    // MARK: – Bubble Logic

    private func pop(_ bubble: Bubble) {
        // 1) Track consecutive same‐colour pops
        if lastPoppedType == bubble.type {
            consecutivePops += 1
        } else {
            consecutivePops = 1
        }
        lastPoppedType = bubble.type

        // 2) Compute points (1.5× after the first in a row)
        let base = bubble.type.points
        let multiplier = consecutivePops > 1 ? 1.5 : 1.0
        let earned = Int(round(Double(base) * multiplier))

        // 3) Award and remove
        score += earned
        bubbles.removeAll { $0.id == bubble.id }
    }

    private func refreshBubbles(in size: CGSize) {
        let newTotal = Int.random(in: 1...maxBubbles)
        var kept = bubbles.shuffled()
                         .prefix(min(bubbles.count, newTotal))
                         .map { $0 }
        let toAdd = newTotal - kept.count
        kept.append(
            contentsOf: placeBubbles(count: toAdd, in: size, existing: kept)
        )
        bubbles = kept
    }

    private func placeBubbles(
      count: Int,
      in size: CGSize,
      existing: [Bubble]
    ) -> [Bubble] {
        var result: [Bubble] = []
        let diameter = bubbleDiameter
        let radius = diameter / 2
        let maxAttempts = 30

        for _ in 0..<count {
            var attempts = 0, placed = false
            while attempts < maxAttempts && !placed {
                let type = randomBubbleType()
                let x = CGFloat.random(in: radius...size.width - radius)

                // avoid Y < hudHeight
                let minY = hudHeight + radius
                let y = CGFloat.random(in: minY...size.height - radius)

                let candidate = Bubble(
                    type: type,
                    position: CGPoint(x: x, y: y)
                )

                let collision = (existing + result).contains {
                    let dx = $0.position.x - candidate.position.x
                    let dy = $0.position.y - candidate.position.y
                    return sqrt(dx*dx + dy*dy) < diameter
                }

                if !collision {
                    result.append(candidate)
                    placed = true
                }
                attempts += 1
            }
        }
        return result
    }

    private func randomBubbleType() -> BubbleColorType {
        let r = Double.random(in: 0...1)
        var cum = 0.0
        for t in BubbleColorType.allCases {
            cum += t.probability
            if r < cum { return t }
        }
        return .red
    }
}

// MARK: – Button Style

private extension View {
    func styledGameButton() -> some View {
        self.font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(playerName: "Tester")
    }
}
