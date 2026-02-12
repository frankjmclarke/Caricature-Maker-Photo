# Calories Deficit Tracker - Technical Overview

## 1. Purpose and Target Users

**Primary Purpose**: A calorie-deficit-focused weight management application that:
- Allows users to log what they eat (with optional AI assistance) and tracks calories/macros
- Calculates personalized daily calorie targets based on BMR, activity level, and chosen deficit pace
- Displays "today vs target" status, weekly consistency, and weight-loss progress

**Target Users**:
- Individuals actively trying to lose weight via consistent calorie deficit
- Users comfortable with food logging who want a focused, simple UX rather than a general fitness tracker

---

## 2. Overall Architecture and Data Flow

**Architecture Style**: SwiftUI + SwiftData with light MVVM flavor and service classes

**Key Layers**:
- **UI Layer (Views)**: SwiftUI views for onboarding, daily progress, food logging, goals, progress visualization
- **ViewModel Layer**: `TodayViewModel`, `LogFoodViewModel`, `ProgressViewModel`, `OnboardingViewModel`, `EntitlementManager`, `SuperwallManager`
- **Data Layer**: SwiftData models in `Models.swift` (`UserSettings`, `DailyEntry`, `Meal`, `WeightEntry`) with `DataManager` as repository/service
- **Service Layer**:
  - `AIService`: OpenAI integration for meal estimation
  - `SuperwallManager` + `EntitlementManager`: Paywall and premium status management
  - `TraceLogger`: Debug-only logging abstraction

**Data Flow (Typical)**:
User interacts with **View** → calls **ViewModel** → uses `DataManager` → reads/writes **SwiftData models** → published properties update → SwiftUI re-renders

---

## 3. Major Modules and Responsibilities

### App Entry / Composition
- **`Calories_Deficit_TrackerApp.swift`**:
  - Configures Superwall using `Config.plist`
  - Creates shared SwiftData `modelContainer`
  - Shows `AppRootView`
- **`AppRootView`**:
  - Decides whether to show onboarding vs `ContentView` based on `hasCompletedOnboarding` and `forceOnboarding`

### Core Domain & Persistence
- **`Models.swift`**:
  - `UserSettings`: Central configuration (deficit target, daily calories, BMR inputs, rest day settings)
  - `DailyEntry`: Per-day consumption/deficit tracking + relationship to `Meal`s
  - `Meal`: Logged food item with macros + optional AI estimation metadata
  - `WeightEntry`: Time-series weight tracking
  - Date helper extensions
- **`DataManager.swift`**:
  - Repository pattern over `ModelContext`
  - Initializes default `UserSettings` and handles migrations for new fields
  - Computes TDEE using Mifflin-St Jeor equation + activity multiplier
  - CRUD operations for `DailyEntry`, `Meal`, and `WeightEntry`
  - Posts `SettingsChanged` / `MealsChanged` notifications

### Onboarding & Paywall
- **`OnboardingView.swift`**:
  - Multi-step onboarding flow (screens 0-12) including:
    - Conceptual explanation screens (AI logging, weekly patterns, etc.)
    - BMR input collection (sex, age, height, weight, activity, deficit pace)
    - Estimated daily calories display
    - Paywall step (`OnboardingPaywallView`)
  - Uses `OnboardingViewModel` + `DataManager` to compute and persist settings
  - Handles `CompleteOnboarding` notification and writes `hasCompletedOnboarding` to `UserDefaults`
  - Global testing flags `forceOnboarding` and `forceShowPaywall` (default `false`)
  - Includes debug-only `DebugPurchasesPanel` (behind `#if DEBUG`)
- **`OnboardingViewModel.swift`**:
  - Holds sex/age/height/weight/activity/deficitRate during onboarding
  - Uses `DataManager.calculateTDEE` to compute `estimatedCalories` reactively
  - Persists final choices into `UserSettings`
- **`SuperwallManager.swift`**:
  - Centralized adapter around Superwall SDK:
    - `configure()` with API key from `Config.plist`
    - Polls `Superwall.shared.subscriptionStatus`
    - Verifies via StoreKit to avoid false positives
  - `static var forceOnboarding/forceShowPaywall` for testing (default `false` in production)
- **`EntitlementManager.swift`**:
  - App's single source of truth for **premium access**
  - Observes Superwall subscription status, verifies via StoreKit entitlements
  - Publishes `hasPremiumAccess`, `isLoading`, `justPurchased`
  - Listens for `"ResetEntitlementManager"` notification for debug reset

### Main App Flows
- **`ContentView.swift`**:
  - "Today" dashboard: daily deficit ring, key cards, date navigation (diagnostic flag)
  - Uses `TodayViewModel`, drives navigation to `LogFoodView` and `ConsistencyView`
- **`ViewModels.swift`**:
  - `TodayViewModel`: Calculates remaining calories, completion %, status text; manages selected date
  - `LogFoodViewModel`: Loads/adds/updates/deletes meals for selected date
  - `ProgressViewModel`: Computes weight loss progress, weeks tracking, chart data
- **`LogFoodView.swift`**:
  - Main food logging view, uses `LogFoodViewModel`
  - Shows list of `MealCard` and presents `AddMealSheet` to add/edit meals
  - Uses notifications to sync `selectedDate` with `ContentView`
- **`GoalSettingsView.swift`, `ConsistencyView.swift`, `ProgressView.swift`**:
  - Additional views for goal settings, weekly patterns, progress visualization

### AI Integration
- **`AIService.swift`**:
  - Loads OpenAI API key from: injected parameter → `OPENAI_API_KEY` env → Keychain → `Config.plist`
  - Uses `gpt-4o-mini` chat completions with strict JSON schema and `response_format: json_object`
  - Decodes into `AIEstimationResponse` / `AIEstimationItem` with robust `AIRange` decoding

### Infrastructure / Debug
- **`TraceLogger.swift`**:
  - Simple debug logger with categories and structured state logging
  - Behind `#if DEBUG` to avoid production noise
- **`SUBMISSION_CHECKLIST.md`, `MIGRATION_SUMMARY.md`**:
  - Documentation for submission and schema evolution

---

## 4. State, Data, and Configuration Management

### Persistent Data
- SwiftData models (`UserSettings`, `DailyEntry`, `Meal`, `WeightEntry`) via `.modelContainer(for: [...])` in `App` struct
- `DataManager` abstracts all SwiftData access and centralizes domain logic (TDEE, deficits, migrations)

### Ephemeral UI State
- `@StateObject` ViewModels inside top-level views (`ContentView`, `LogFoodView`, `OnboardingView`)
- `@Published` properties in ViewModels drive SwiftUI re-renders

### Global / Cross-Screen State
- **Notifications** (`NotificationCenter`) for:
  - `SettingsChanged`, `MealsChanged` (DataManager → Views)
  - `SelectedDateChanged` / `RequestSelectedDate` (syncs `ContentView` and `LogFoodView`)
  - `CompleteOnboarding` (Paywall → `OnboardingView`)
  - `ResetEntitlementManager` (Debug reset → `EntitlementManager`)

### Configuration & Secrets
- **`Config.plist`** (gitignored) contains:
  - `SUPERWALL_API_KEY`
  - `OPENAI_API_KEY` (for AIService fallback)
- **`Config.plist.example`** documents expected keys without secrets
- OpenAI key is mirrored into Keychain for persistence

### Feature Flags / Testing Switches
- `forceOnboarding`, `forceShowPaywall` (global and in `SuperwallManager`) – default `false`
- `showDiagnosticButtons` in `ContentView` shows date navigation diagnostics
- Debug-only panels (`DebugPurchasesPanel`) and logging via `#if DEBUG`

---

## 5. External Dependencies / SDKs / APIs

### Apple Frameworks
- **SwiftUI / SwiftData**: Primary UI and persistence frameworks
- **StoreKit**: Subscription entitlements (`Transaction.currentEntitlements`, `AppStore.sync`)
- **Security**: iOS Keychain for storing OpenAI API key

### Third-Party
- **SuperwallKit**: Third-party paywall SDK
  - `Superwall.configure(apiKey:)`, `Superwall.shared.subscriptionStatus`, `PaywallView`
  - Used to show paywall on onboarding last screen and manage subscription UX
- **OpenAI API**: HTTPS REST via `URLSession` in `AIService`
  - Model: `gpt-4o-mini`, used for calorie/macro estimation from free-text meal descriptions

No other major third-party libraries beyond Superwall and OpenAI.

---

## 6. Main Execution Paths and Lifecycle

### 1. App Startup
- `Calories_Deficit_TrackerApp.init`:
  - Loads `SUPERWALL_API_KEY` from `Config.plist`
  - Configures Superwall; sets initial `subscriptionStatus = .inactive`
- `WindowGroup` with `AppRootView`

### 2. Onboarding vs Main Content Decision
- `AppRootView.onAppear`:
  - Calls `checkOnboardingStatus()`:
    - Reads `hasCompletedOnboarding` from `UserDefaults`
    - If `forceOnboarding` or `!hasCompletedOnboarding` → show `OnboardingView`
    - Else → show `ContentView`

### 3. Onboarding Flow
- `OnboardingView`:
  - Multi-step `TabView` (screens 0-12) covering:
    - Conceptual intro (AI logging, weekly patterns, etc.)
    - Collect sex, age, height, weight, activity, deficit pace
    - Show estimated daily calories
    - Paywall step (`OnboardingPaywallView`)
  - Uses `OnboardingViewModel` + `DataManager` to compute and persist settings
- `OnboardingPaywallView`:
  - Shows spinner while entitlements are loading
  - Shows welcome message / auto-completes if premium is detected
  - Hosts `PaywallView`:
    - `.purchased` → kicks off entitlement verification via `EntitlementManager`
    - `.restored` → similar via restore path
    - `.declined` → now posts `CompleteOnboarding` so onboarding is finished even for non-premium users

### 4. Onboarding Completion
- `OnboardingView` listens for `CompleteOnboarding` or `hasPremiumAccess` changes on final step:
  - Calls `completeOnboarding()` →:
    - `viewModel.saveSettings()`
    - Writes `hasCompletedOnboarding = true` to `UserDefaults`
    - Calls `onComplete()` → `AppRootView` switches to `ContentView`

### 5. Main Usage Flow
- `ContentView`:
  - On appear sets up `TodayViewModel` with real `modelContext`
  - Loads daily data via `DataManager`
  - Shows daily deficit ring and navigation into:
    - `LogFoodView` (logging meals, optionally using AI)
    - `ConsistencyView` (weekly/longer-term patterns)
    - `YourProgressView` / `ProgressView` (weight trends)
- `LogFoodView`:
  - Uses `LogFoodViewModel` and `DataManager` to manage meals for selected date
  - Interacts with `AIService` in `AddMealSheet` for AI estimation

---

## 7. Non-Obvious / Implicit Design Decisions

### SwiftData + Manual `ModelContainer` in View
- Views like `ContentView` and `LogFoodView` initialize an "internal" `ModelContainer` in the `@StateObject` factory, then overwrite `dataManager` with the real `modelContext` in `onAppear`
- This ensures `@StateObject` has a non-optional `DataManager` but is slightly unusual vs injecting environment context directly

### Notification-Based Cross-Screen Sync
- `SelectedDateChanged` and `RequestSelectedDate` are used instead of a shared observable object or environment object for date sync
- This decouples screens but is less type-safe

### EntitlementManager + SuperwallManager Layering
- Both observe Superwall, but `EntitlementManager` is the "app-facing" layer, while `SuperwallManager` is more of a lower-level adapter and test harness
- There is some overlap; the design leans toward redundancy for clarity over strict DRY

### AI Key Handling
- AIService prioritizes:
  1. Injected parameter
  2. `OPENAI_API_KEY` env
  3. Keychain
  4. `Config.plist`
- It also contains logic to detect malformed keys (too long) and reset Keychain

---

## 8. Complexity, Technical Debt, and Risk Areas

### Entitlement / Subscription Logic
- Two layers (`EntitlementManager`, `SuperwallManager`) plus `OnboardingPaywallView`'s local logic; easy to regress behavior if you tweak one without understanding all
- Polling Superwall status in a loop is simple but not event-driven; watch for battery/network impact

### NotificationCenter Usage
- Date and onboarding completion flows rely on string-typed notifications and `userInfo` dictionaries
- Easy to break by mistyping names or changing payload shapes

### AIService Error Handling
- Uses print statements for debug logging rather than centralized logging; errors bubble via throws but there may be edge cases if the API returns unexpected JSON

### Initialization Patterns
- Multiple places create `ModelContainer` just to satisfy `@StateObject` initialization, then later swap contexts in `onAppear`
- This works but is non-standard, and new developers might accidentally use the wrong context

### Debug-Only Flags
- `forceOnboarding` / `forceShowPaywall` exist both globally and inside `SuperwallManager`
- While default values are safe, this duplication is easy to misconfigure in future changes

---

## 9. Extension Points / Future Growth

### Analytics / Telemetry
- There are several logical points (`updateData`, meal add/edit/delete, onboarding completion, paywall events) where analytics hooks could be added

### More Sophisticated Diet Features
- `DailyEntry` contains fields like `caloriesBurned` and `weight`; these could be used for:
  - Exercise logging
  - Projected time-to-goal
  - More advanced weekly summaries

### Richer AI Integration
- The AI schema already supports per-item assumptions and ranges; you could:
  - Show more detailed AI breakdowns
  - Let users adjust AI suggestions and feed back corrections

### Multi-Platform
- Architecture (SwiftUI + SwiftData) is compatible with macOS / iPadOS with modest view adjustments

### EntitlementManager as Shared Service
- Could be injected via environment or ObservableObject at the root instead of local `@StateObject` in `OnboardingView`, making premium gating easier in other parts of the app

---

## 10. How a New Developer Should Approach This Codebase

### 1. Start with Flows, Not Files
- **Run the app**:
  - Go through onboarding → paywall → main dashboard
  - Log a few meals, check weekly/weight views
- **Then read**:
  - `Calories_Deficit_TrackerApp.swift` → `AppRootView` (entry point)
  - `OnboardingView` + `OnboardingViewModel` (user setup)
  - `ContentView` + `ViewModels.swift` (daily/weekly flows)

### 2. Understand the Data Model via `Models.swift` & `DataManager.swift`
- How `UserSettings` drives calories and targets
- How `DailyEntry` and `Meal` represent the core logging domain
- How `DataManager` encapsulates all reads/writes and calculations

### 3. Learn the Entitlement/Premium Story
- Read `EntitlementManager.swift` first (this is what views should depend on)
- Then skim `SuperwallManager.swift` to see how Superwall is configured and validated

### 4. Review AI Integration Only After Basics
- `AIService.swift` and the AI sections in `LogFoodView.swift` / `AddMealSheet` can be understood once you're comfortable with the logging flow

### 5. Use TraceLogger in DEBUG
- When debugging entitlements/onboarding/AI, rely on `TraceLogger` output instead of sprinkling new `print`s

### 6. When Modifying Behavior
- **For data or business rules**: Prefer changing `DataManager` or ViewModels
- **For UI**: Adjust SwiftUI views, but keep logic thin
- **For onboarding/premium**: Touch `OnboardingView`, `OnboardingPaywallView`, and `EntitlementManager` together, and verify `hasCompletedOnboarding` + paywall flows end correctly

---

This mental model—a SwiftData-backed calorie/weight tracker with an onboarding/paywall gate and optional AI meal estimation—should give any senior developer enough orientation to safely extend or audit the app.
