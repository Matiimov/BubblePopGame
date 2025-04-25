import SwiftUI

/// **ContentView.swift**
/// Main gameplay screen: binds UI entirely to GameEngine state.
struct ContentView: View {
    // MARK: - ViewModel
    @StateObject private var engine = GameEngine()

    // MARK: - Input
    let playerName: String   /// The player's chosen username displayed on the HUD

    // MARK: - Layout
    @Environment(\.dismiss) private var dismiss     /// Allows dismissing full-screen views

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(
                    red: 225.0/255.0,
                    green: 247.0/255.0,
                    blue: 200.0/255.0
                ).ignoresSafeArea()
                
                /// 1) Pop Effects
                ForEach(engine.popEffects) { effect in
                    Text(effect.text)
                        .font(.system(size: 48, weight: .bold))
                        .scaleEffect(1.2)
                        .foregroundColor(.yellow)
                        .position(effect.position)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onAppear {  /// Remove this effect after 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    engine.popEffects.removeAll { $0.id == effect.id }
                                }
                            }
                        }
                }

                /// 2) Bubbles
                ForEach(engine.bubbles) { bubble in
                    Circle()
                        .fill(bubble.type.color)    /// Color circle based on bubble type
                        .frame(width: engine.bubbleDiameter,
                               height: engine.bubbleDiameter)
                        .position(bubble.position)  /// Place bubble at its current coordinate
                        .scaleEffect(engine.poppedBubbleIDs.contains(bubble.id) ? 1.5 : 1)  /// Enlarge briefly when popped
                        .opacity(engine.poppedBubbleIDs.contains(bubble.id) ? 0 : 1)    /// Fade out when popped
                        .animation(.easeOut(duration: 0.2), value: engine.poppedBubbleIDs)
                        .onTapGesture {
                            /// Only allow popping when game is running
                            guard !engine.isGameOver, !engine.isCountingDown else { return }
                            engine.pop(bubble)
                        }
                }

                /// 3) Heads-Up Display (HUD): shows player name, timer, score, and high score
                VStack {
                    HStack(spacing: 20) {
                        Text(playerName)
                        Spacer()
                        VStack {    /// Timer: label + remaining seconds
                            Text("Time Left:")
                            Text("\(engine.timeRemaining)s")
                        }
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        Spacer()
                        Text("Score: \(engine.score)")  /// Current game score
                        Spacer()
                        Text("High Score: \(HighScoreManager.loadHighScores().first?.score ?? 0)")  /// All-time high score loaded from storage
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    Spacer()
                }
                .disabled(engine.isGameOver)    /// Disable HUD interaction when game is over

                /// 4) Countdown Overlay
                if engine.isCountingDown {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    Text("\(engine.countdownValue)")    /// Display the countdown number
                        .font(.system(size: 100, weight: .bold))
                        .foregroundColor(.white)
                }

                /// 5) Game Over Overlay
                if engine.isGameOver && !engine.isCountingDown {
                    Color.black.opacity(0.6).ignoresSafeArea() /// Darken the background behind the overlay
                    VStack(spacing: 20) {
                        Text("GAME OVER, \(playerName)!")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        Text("Your Score: \(engine.score)") /// Display the player’s final score
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Top 3 Scores")    /// Heading for the top-three scores list
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(spacing: 8) {
                            ForEach(engine.topThree) { entry in
                                HStack {    /// Player name in the high-score list
                                    Text(entry.name).foregroundColor(.white)
                                    Spacer()
                                    Text("\(entry.score)").foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)

                        HStack(spacing: 30) {
                            Button("Play Again") {  /// Option to play again
                                engine.startGame(in: engine.playAreaSize)
                            }
                            .styledGameButton()

                            Button("Main Menu") {   /// Option to go back to main menyu
                                dismiss()
                            }
                            .styledGameButton()
                        }
                    }
                    .padding()
                }
            }
            .onAppear { /// Sync engine on appear
                engine.playerName = playerName
                engine.playAreaSize = geo.size
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(playerName: "Tester")
    }
}
