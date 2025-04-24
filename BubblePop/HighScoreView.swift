import SwiftUI

struct HighScoreView: View {
    @State private var highScores: [HighScore] = []
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        NavigationView {
            List {
                // Header row
                Section(header:
                    HStack {
                        Text("Nickname")
                            .font(.headline)
                        Spacer()
                        Text("Score")
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                ) {
                    // High‐score entries
                    ForEach(highScores) { entry in
                        HStack {
                            Text(entry.name)
                            Spacer()
                            Text("\(entry.score)")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Top 10 Players")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Main Menu") {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                highScores = HighScoreManager.loadHighScores()
            }
        }
    }
}

struct HighScoreView_Previews: PreviewProvider {
    static var previews: some View {
        HighScoreView()
    }
}
