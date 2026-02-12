## 1. Most important invariants

- **Onboarding completion invariant**
  - Once a user has completed onboarding (premium or not), `UserDefaults["hasCompletedOnboarding"] == true` and, with `forceOnboarding == false`, onboarding must not show again.
  - Depends on:
    - `OnboardingView.completeOnboarding()` reliably setting the flag.
    - `OnboardingPaywallView` always triggering completion via `CompleteOnboarding` (purchase, restore, or decline).
    - `AppRootView.checkOnboardingStatus()` using only `forceOnboarding || !hasCompleted`.

- **Entitlement/premium invariant**
  - Premium access is true only when StoreKit says there’s an active subscription.
  - In practice:
    - `EntitlementManager.hasPremiumAccess` should be true only when `Transaction.currentEntitlements` contains one of the premium product IDs.
    - Superwall’s `subscriptionStatus` is reconciled with StoreKit (false positives corrected by `verifyStoreKitSubscription` / refresh flows).
    - Any UI or feature gating must depend on `EntitlementManager.hasPremiumAccess`, not raw Superwall callbacks.

- **Calorie/deficit consistency invariant**
  - For any day, the tracked deficit and progress must be consistent with `UserSettings` and logged `Meal`s.
  - Concretely:
    - `DailyEntry.deficitAchieved == settings.totalCalories - entry.caloriesConsumed`.
    - `TodayViewModel`’s `remainingCalories`, `completionPercentage`, and status text derive from the same `totalCalories`, `targetDeficit`, and meal data that `DataManager` uses.
    - `DataManager.updateDailyEntry` is the single point that keeps `DailyEntry` consistent.

---

## 2. Most dangerous places to introduce bugs

- **Onboarding ↔ paywall ↔ completion boundary** (`OnboardingView`, `OnboardingPaywallView`, `AppRootView`)
  - Any change that:
    - Alters when `CompleteOnboarding` is posted,
    - Skips `completeOnboarding()` in some path (e.g., decline, restore),
    - Reintroduces `SuperwallManager.forceOnboarding` into `checkOnboardingStatus()`
  - Can lead to onboarding loops, skipped onboarding, or inconsistent first‑run behavior.

- **Entitlement / Superwall / StoreKit integration** (`EntitlementManager`, `SuperwallManager`, paywall result handlers)
  - Multiple sources of truth:
    - Superwall’s `subscriptionStatus`
    - StoreKit entitlements
    - `EntitlementManager.hasPremiumAccess`
  - Mis-ordering async calls, changing polling intervals, or bypassing StoreKit verification can:
    - Grant “ghost” premium,
    - Hide paywalls incorrectly,
    - Or leave `isLoading` / `hasPremiumAccess` stuck.

- **DataManager as central repository** (`DataManager.swift`)
  - Underpins:
    - Default/migrated `UserSettings`
    - TDEE calculation
    - Derived daily deficits and consistency metrics
    - All CRUD for meals and weight
  - A subtle change (e.g. recalculating `totalCalories` improperly, altering deficit logic, or mis-handling date ranges) will ripple into every screen: onboarding estimates, today view, consistency charts, and progress.

---

## 3. Architectural improvement to reduce long-term complexity

**Introduce a single, shared `AppSession` / `AppEnvironment` object to replace NotificationCenter for core app state and wiring.**

- **Current situation**
  - Cross-screen coordination uses multiple `NotificationCenter` channels:
    - `SelectedDateChanged`, `RequestSelectedDate`
    - `SettingsChanged`, `MealsChanged`
    - `CompleteOnboarding`, `ResetEntitlementManager`
  - `EntitlementManager` and date state are created in specific views instead of being clearly global app state.

- **Proposed improvement (incremental, no huge rewrite)**
  - Create a single `@MainActor final class AppSession: ObservableObject` that owns:
    - `DataManager`
    - `EntitlementManager`
    - Shared `selectedDate`
    - A small set of high‑level intents (`completeOnboarding()`, `reloadSettings()`, etc.).
  - Provide it via `.environmentObject(appSession)` from `Calories_Deficit_TrackerApp`.
  - Gradually:
    - Replace `NotificationCenter` traffic for date sync and settings/meals changes with `@Published` properties and method calls on `AppSession`.
    - Use `appSession.entitlementManager` instead of local `@StateObject` creation and reset notifications.

- **Benefits**
  - Centralizes “what’s going on right now” in one place for new developers (less hunting through notifications).
  - Makes data and entitlement flows easier to reason about and unit test.
  - Reduces the risk of subtle bugs caused by notification ordering or missing observers, without changing the core business logic or UI structure.

