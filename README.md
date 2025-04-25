# BubblePop

BubblePop is a fun and fast‑paced iOS game built in SwiftUI. Players tap colorful, moving bubbles to earn points before the countdown timer runs out. Gold bubbles award extra time, while other bubbles grant points based on their color.

---

## 🎮 Features

- **Home Screen**: Enter username, Play button, All‑Time High Scores sheet, Settings gear
- **Settings**: Adjust game duration (10–120 s) and max bubbles (1–20); reset to defaults
- **Countdown**: Pre‑game 3‑2‑1 overlay
- **Dynamic Gameplay**:
  - Randomly spawn (1 … max) Bubbles
  - Smooth 30 Hz movement with speed ramp (20 pt/s → 100 pt/s)
  - Tap to pop: red = 1 pt, pink = 2 pt, green = 5 pt, blue = 8 pt, black = 10 pt
  - Gold bubbles grant +10 s with floating “+10 s” effect
- **HUD**: Displays player name, time left, current score, and all‑time high score
- **Game Over**: Final score, top 3 high scores, Play Again and Main Menu buttons
- **Persistence**: Top 10 high scores saved via UserDefaults + Codable

---

## 📦 Requirements

- Xcode 15 or later
- Swift 5.8+
- iOS 18+

---

## 🚀 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/<your‑username>/BubblePop.git
   ```
2. Open the project in Xcode:
   ```bash
   open BubblePop/BubblePop.xcodeproj
   ```
3. Select a simulator or device and hit **Run (⌘R)**.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

