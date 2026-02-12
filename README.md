# Calories Deficit Tracker

A modern iOS app for tracking calorie deficits, monitoring progress, and building sustainable weight loss habits.

## Features

### 📊 Today's Progress
- Visual circular progress indicator showing remaining calories
- Daily calorie consumption tracking
- Target deficit display
- Completion percentage badge

### 🍽️ Log Food
- Search functionality for food items
- Meal tracking with time stamps
- Macronutrient breakdown (Protein, Carbs, Fat)
- Visual calorie indicators per meal
- Today's meals overview

### 📈 Deficit Analysis
- Weekly deficit breakdown with interactive charts
- Average daily deficit tracking
- Daily deficit visualization
- Target deficit reference line
- On-track status with projected weight loss

### 📉 Your Progress
- Weight tracking over time
- Current, starting, lost, and remaining weight metrics
- 8-week weight trend graph
- Weekly weight loss rate indicator
- Visual progress cards

### ⚙️ Goal Settings
- Adjustable deficit rate (Conservative, Moderate, Aggressive)
- Weekly rest day toggle
- Activity level configuration
- Target weight setting
- Lifestyle customization

### 🔄 Consistency
- Current streak tracking
- Weekly progress visualization
- Days tracked statistics
- Deficit target hit rate
- Habit building insights

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.0+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Calories-Deficit-Tracker.git
```

2. Open the project in Xcode:
```bash
cd "Calories Deficit Tracker"
open "Calories Deficit Tracker.xcodeproj"
```

3. **Set up OpenAI API Key** (required for AI meal estimation):
   - Copy `Config.plist.example` to `Config.plist`:
     ```bash
     cp "Calories Deficit Tracker/Config.plist.example" "Calories Deficit Tracker/Config.plist"
     ```
   - Open `Config.plist` and replace `YOUR_OPENAI_API_KEY_HERE` with your actual OpenAI API key
   - **Important**: `Config.plist` is gitignored and will not be committed to the repository
   
   **Alternative**: You can also set the `OPENAI_API_KEY` environment variable in Xcode:
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add `OPENAI_API_KEY` with your key as the value

4. Select your development team in the project settings (Signing & Capabilities)

5. Build and run on your device or simulator

## Project Structure

```
Calories Deficit Tracker/
├── Calories Deficit Tracker/
│   ├── Calories_Deficit_TrackerApp.swift    # App entry point
│   ├── ContentView.swift                    # Main progress screen
│   ├── LogFoodView.swift                    # Food logging screen
│   ├── DeficitAnalysisView.swift            # Weekly analysis screen
│   ├── ProgressView.swift                   # Weight progress screen
│   ├── GoalSettingsView.swift               # Settings screen
│   ├── ConsistencyView.swift               # Consistency tracking screen
│   └── Assets.xcassets/                     # App assets
└── README.md
```

## Technologies

- **SwiftUI** - Modern declarative UI framework
- **Swift Charts** - Data visualization
- **iOS 17.0+** - Latest iOS features

## Features in Detail

### Responsive Design
- Fully responsive layout that adapts to all iPhone sizes
- Optimized for iPhone SE and larger devices
- Adaptive sizing and spacing

### Navigation
- Seamless navigation between all screens
- Native iOS navigation patterns
- Intuitive user flow

### Data Visualization
- Interactive charts for deficit and weight trends
- Circular progress indicators
- Visual progress cards

## Screenshots

The app includes six main screens:
1. **Today's Progress** - Daily calorie tracking
2. **Log Food** - Meal logging and search
3. **Deficit Analysis** - Weekly breakdown
4. **Your Progress** - Weight tracking
5. **Goal Settings** - Customizable preferences
6. **Consistency** - Habit tracking

## Development

### Building for Device
1. Connect your iPhone via USB
2. Select your device in Xcode
3. Trust the computer on your iPhone if prompted
4. Click Run (▶) or press `Cmd + R`

### Code Signing
The project uses automatic code signing. Make sure to:
- Set your development team in project settings
- Trust your developer certificate on device (Settings → General → VPN & Device Management)

## License

This project is available for personal use.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created by Francis Clarke

---

**Note**: This app is designed for iOS devices only. macOS and visionOS support have been removed for a focused mobile experience.
