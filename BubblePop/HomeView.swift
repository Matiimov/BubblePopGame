import SwiftUI

struct HomeView: View {
    @State private var username = ""
    @State private var isGameActive = false
    @State private var showingSettings = false
    @State private var showingLeaderboard = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

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
                    isGameActive = true
                } label: {
                    Text("Play")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(username.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(username.isEmpty)
                .fullScreenCover(isPresented: $isGameActive) {
                    ContentView(playerName: username)
                }

                // MARK: Leaderboard Button
                Button {
                    showingLeaderboard = true
                } label: {
                    Text("All-Time High Scores")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            Color(
                                red: 212/255,
                                green: 175/255,
                                blue:  55/255
                            )
                        )
                        .cornerRadius(12)
                }
                .sheet(isPresented: $showingLeaderboard) {
                    HighScoreView()
                }

                Spacer()
            }
            .navigationTitle("")                         // hide title but keep bar
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings gear icon
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
