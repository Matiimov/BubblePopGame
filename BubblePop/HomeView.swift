import SwiftUI

/// **HomeView.swift**
/// Home screen where the player enters their username, starts the game, accesses settings, or views high scores.
struct HomeView: View {
    // MARK: - Local State
    @State private var username = ""                   /// Text field for player's name entry
    @State private var isGameActive = false             /// Controls full-screen cover for the game view
    @State private var showingSettings = false          /// Controls display of the settings sheet
    @State private var showingLeaderboard = false       /// Controls display of the high-score sheet

    // MARK: - Main View
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()  /// Push content toward vertical center

                // MARK: Title / Logo
                Text("Bubble Pop")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                // MARK: Username Entry
                TextField("Enter your username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 50)

                // MARK: Play Button
                Button {
                    isGameActive = true      /// Trigger game view presentation
                } label: {
                    Text("Play")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(username.isEmpty ? Color.gray : Color.blue)  /// Gray when disabled
                        .cornerRadius(12)
                }
                .disabled(username.isEmpty)  /// Prevent start without a name
                .fullScreenCover(isPresented: $isGameActive) {
                    ContentView(playerName: username)  /// Launch ContentView with entered name
                }

                // MARK: Leaderboard Button
                Button {
                    showingLeaderboard = true  /// Trigger high-score sheet
                } label: {
                    Text("All-Time High Scores")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            Color(
                                red: 212/255,
                                green: 175/255,
                                blue: 55/255
                            )  /// Gold-themed button color
                        )
                        .cornerRadius(12)
                }
                .sheet(isPresented: $showingLeaderboard) {
                    HighScoreView()  /// Present high-score view modally
                }
                Spacer()  /// Balance bottom spacing
            }
            
            // MARK: Navigation Bar Configuration
            .navigationTitle("")  /// Hide default title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings gear icon on top-right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true  /// Open settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()  /// Present SettingsView
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()  /// Show HomeView in preview mode
    }
}
