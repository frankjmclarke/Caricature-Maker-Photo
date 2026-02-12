# Repurpose App Checklist (manual)

Use this checklist when you copy the project folder to a new location and want to rebrand by hand instead of running `repurpose_app.sh`.

**Prerequisites:** Copy the entire project folder (e.g. "Calories Deficit Tracker") to the new location. Do not open the original in Xcode while editing the copy.

**Decide:** New display name, new bundle ID, new StoreKit product IDs (monthly/yearly), and optionally new app category.

---

## 1. project.pbxproj

Path: `Calories Deficit Tracker.xcodeproj/project.pbxproj`

- Replace every **Calories Deficit Tracker** with your new app display name (target name, product name, group path, entitlements path, usage descriptions).
- Replace **Calories_Deficit_Tracker** with your sanitized name (no spaces, e.g. `My_New_App`) in:
  - `CODE_SIGN_ENTITLEMENTS = "Calories Deficit Tracker/Calories_Deficit_Tracker.entitlements"` → `"New Name/My_New_App.entitlements"`.
- Replace **com.fclarke.caloriesDeficitTracker** with your new bundle ID (Debug and Release build settings).
- Optionally change **INFOPLIST_KEY_LSApplicationCategoryType** (e.g. from `public.app-category.food-and-drink` to another category).

---

## 2. Scheme file

Path: `Calories Deficit Tracker.xcodeproj/xcshareddata/xcschemes/Calories Deficit Tracker.xcscheme`

- Replace **Calories Deficit Tracker** with your new app name in:
  - `BuildableName`, `BlueprintName`, `ReferencedContainer` (so it points to `New Name.xcodeproj`).

---

## 3. Swift sources (app folder)

Inside the **Calories Deficit Tracker** app folder:

- **All .swift files:** In the file header, replace `//  Calories Deficit Tracker` with your new app name.
- **Main app file (Calories_Deficit_TrackerApp.swift):**
  - Replace `struct Calories_Deficit_TrackerApp` with `struct My_New_AppApp` (sanitized name + `App`).
  - Replace `@main` struct name to match.
- **SimplePaywallView.swift** and **EntitlementManager.swift:** Replace **caloriesMonthly** and **caloriesYearly** with your new product IDs (if you use different ones).
- Any usage description or user-facing string that says "Calories Deficit Tracker" → your new app name.

---

## 4. Rename folders and files

Do this after the content replacements so that paths in the project refer to the new names.

1. Rename the inner app folder: **Calories Deficit Tracker** → your new display name (e.g. **My New App**).
2. Rename the project: **Calories Deficit Tracker.xcodeproj** → **New Name.xcodeproj**.
3. Rename the scheme file: **Calories Deficit Tracker.xcscheme** → **New Name.xcscheme** (inside `New Name.xcodeproj/xcshareddata/xcschemes/`).
4. Inside the renamed app folder:
   - **Calories_Deficit_Tracker.entitlements** → **My_New_App.entitlements** (sanitized name).
   - **Calories_Deficit_TrackerApp.swift** → **My_New_AppApp.swift** (sanitized name + `App`).

---

## 5. Icon and final steps

- Replace the contents of **Assets.xcassets/AppIcon.appiconset/** with your new app icon.
- Open **New Name.xcodeproj** in Xcode and build.
- In App Store Connect, create the app with the new bundle ID and subscription products (monthly/yearly) if needed.

---

## Optional: Remove SuperwallKit

If you are not using Superwall (the app uses StoreKit 2 for the paywall):

- In Xcode: File → Packages → Remove package "Superwall-iOS" (or delete the package reference in `project.pbxproj` and remove the SuperwallKit framework from the target’s Frameworks).
- Remove any `import SuperwallKit` from Swift files if present.
