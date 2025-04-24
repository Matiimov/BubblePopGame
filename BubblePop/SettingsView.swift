import SwiftUI

struct SettingsView: View {
    // Persisted settings with registered defaults
    @AppStorage("gameDuration") private var gameDuration: Int = 60
    @AppStorage("maxBubbles")   private var maxBubbles:   Int = 15

    @Environment(\.presentationMode) private var presentation

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Duration (seconds)")) {
                    Stepper(value: $gameDuration, in: 10...300, step: 5) {
                        Text("\(gameDuration) s")
                    }
                }

                Section(header: Text("Maximum Bubbles")) {
                    Stepper(value: $maxBubbles, in: 1...30) {
                        Text("\(maxBubbles)")
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        // Remove stored values so registered defaults (60/15) take over
                        UserDefaults.standard.removeObject(forKey: "gameDuration")
                        UserDefaults.standard.removeObject(forKey: "maxBubbles")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
