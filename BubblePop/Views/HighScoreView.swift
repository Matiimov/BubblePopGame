import SwiftUI

/// **HighScoreView.swift**
/// Displays the top 10 high scores in a list and provides navigation back to the main menu.
struct HighScoreView: View {
    // MARK: - State
    @State private var highScores: [HighScore] = []  /// Loaded high-score entries

    // MARK: - Environment
    @Environment(\.presentationMode) private var presentation  /// To dismiss this view

    var body: some View {
        /// Use a navigation container to display a title and toolbar items
        NavigationView {
            List {
                Section(header:
                    HStack {
                        Text("Nickname")
                            .font(.headline)  /// Column title for player names
                        Spacer()
                        Text("Score")
                            .font(.headline)  /// Column title for scores
                    }
                    .padding(.vertical, 4)
                ) {
                    /// Iterate through loaded high-score entries
                    ForEach(highScores) { entry in
                        HStack {
                            Text(entry.name)              /// Display player's name
                            Spacer()
                            Text("\(entry.score)")     /// Display player's score
                        }
                    }
                }
            }
            .listStyle(.plain)                      /// Simplify list appearance
            .navigationTitle("Top 10 Players")     /// Title at top of navigation bar
            .toolbar {
                /// Main Menu button to dismiss view
                ToolbarItem(placement: .confirmationAction) {
                    Button("Main Menu") {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                /// Load high scores when view appears
                highScores = HighScoreManager.loadHighScores()
            }
        }
    }
}

// MARK: - Preview
struct HighScoreView_Previews: PreviewProvider {
    static var previews: some View {
        HighScoreView()  /// Show preview with default empty list
    }
}
