import SwiftUI

/// **SettingsView.swift**
/// Allows the player to customize game duration and maximum bubbles, with safeguards and reset functionality.
struct SettingsView: View {
    // MARK: - Persisted Settings
    @AppStorage("gameDuration") private var gameDuration: Int = 60  /// Total game seconds, persisted via UserDefaults
    @AppStorage("maxBubbles")   private var maxBubbles:   Int = 15  /// Max simultaneous bubbles, persisted via UserDefaults

    // MARK: - Environment
    @Environment(\.presentationMode) private var presentation  /// For dismissing this view when done

    // MARK: - Alert Flags
    @State private var showGameTimeAlert = false   /// True when user reaches max duration cap
    @State private var showBubbleLimitAlert = false/// True when user reaches max bubbles cap

    var body: some View {
        NavigationView {
            Form {
                // MARK: Game Duration Section
                Section(header: Text("Game Duration (seconds)")) {
                    Stepper(value: $gameDuration, in: 10...120, step: 5) {
                        Text("\(gameDuration) s")  /// Display current duration setting
                    }
                    .onChange(of: gameDuration) { oldValue, newValue in
                        if newValue == 120 {
                            showGameTimeAlert = true   /// Warn when hitting upper limit
                        }
                    }
                }

                // MARK: Max Bubbles Section
                Section(header: Text("Maximum Bubbles")) {
                    Stepper(value: $maxBubbles, in: 1...20) {
                        Text("\(maxBubbles)")  /// Display current bubble limit
                    }
                    .onChange(of: maxBubbles) { oldValue, newValue in
                        if newValue == 20 {
                            showBubbleLimitAlert = true  /// Warn when hitting upper limit
                        }
                    }
                }

                // MARK: Reset Section
                Section {
                    Button("Reset to Defaults") {
                        // Remove user custom settings to revert to registered defaults
                        UserDefaults.standard.removeObject(forKey: "gameDuration")
                        UserDefaults.standard.removeObject(forKey: "maxBubbles")
                    }
                    .foregroundColor(.red)  /// Highlight the button
                }
            }
            
            // MARK: Navigation Title & Toolbar
            .navigationTitle("Settings")  /// Title shown in navigation bar
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentation.wrappedValue.dismiss()  /// Close settings view
                    }
                }
            }
            
            // MARK: Alerts
            .alert("Maximum game time is 120 seconds", isPresented: $showGameTimeAlert) {
                Button("OK") { showGameTimeAlert = false }  /// Reset alert state
            }
            .alert("Maximum bubbles is 20", isPresented: $showBubbleLimitAlert) {
                Button("OK") { showBubbleLimitAlert = false }  /// Reset alert state
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()  /// Render SettingsView
    }
}
