import SwiftUI

struct HomeView: View {
    @State private var username = ""
    @State private var isGameActive = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()

                Text("Bubble Pop")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                TextField("Enter your username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 50)

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

                Spacer()
            }
            .navigationTitle("")                  // <-- empty title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
