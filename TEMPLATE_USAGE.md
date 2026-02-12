# Template Generator Usage Guide

## Quick Start

```bash
# From the Calories Deficit Tracker directory
./create_template.sh MyNewApp
```

This creates a new template in `../MyNewApp/` with all the reusable components.

## How It Works

The script:
1. ✅ Copies reusable components (EntitlementManager, SimplePaywallView, etc.)
2. ✅ Creates simplified onboarding (3 screens: welcome, features, paywall)
3. ✅ Creates minimal ContentView (single screen skeleton)
4. ✅ Creates app entry point with paywall logic
5. ✅ Replaces app-specific strings with placeholders
6. ✅ Copies configuration files and assets
7. ✅ Creates documentation

## Placeholders to Replace

After generating the template, search and replace:

| Placeholder | What to Replace With |
|------------|----------------------|
| `{{APP_NAME}}` | Your app name (e.g., "MyNewApp") |
| `{{MONTHLY_PRODUCT_ID}}` | Your monthly subscription product ID from App Store Connect |
| `{{YEARLY_PRODUCT_ID}}` | Your yearly subscription product ID from App Store Connect |
| `{{PRIVACY_POLICY_URL}}` | Your privacy policy URL |

## Files You'll Need to Customize

### 1. App Name
- Search for `{{APP_NAME}}` in all files
- Replace with your actual app name
- Rename `{{APP_NAME}}App.swift` to match

### 2. Product IDs
Files to update:
- `EntitlementManager.swift` (line with `subscriptionProductIDs`)
- `SimplePaywallView.swift` (line with `productIDs`)

### 3. Onboarding
- `OnboardingView.swift` - Customize welcome message, features, and screens

### 4. Main Screen
- `ContentView.swift` - Replace with your app's main functionality

### 5. Account Deletion
- `AccountDeletionView.swift` - Update the deletion logic if you have custom data models

## Creating a New App from Template

### Step 1: Generate Template
```bash
./create_template.sh MyNewApp
```

### Step 2: Open in Xcode
1. Create new iOS App project in Xcode
2. Name it `MyNewApp`
3. Choose SwiftUI interface
4. Don't create any initial files

### Step 3: Copy Files
1. Copy all `.swift` files from template to your Xcode project
2. Add `Assets.xcassets` folder
3. Add `Config.plist.example` (rename to `Config.plist` and fill in)

### Step 4: Configure
1. Update bundle identifier
2. Add StoreKit capability
3. Replace all placeholders (see above)
4. Set up App Store Connect products

### Step 5: Build
1. Build and run
2. Test onboarding flow
3. Test paywall (use sandbox account)
4. Customize ContentView

## Maintenance

### Updating the Template Generator

If you improve the source app's paywall/onboarding:
1. Update the script's template sections
2. Re-run on a test template name
3. Verify it works
4. Use for new apps

### Version Control

The template generator script is version-controlled with your source app. This means:
- ✅ Template improvements are tracked
- ✅ You can see what changed
- ✅ Easy to roll back if needed

## Troubleshooting

### "Permission denied"
```bash
chmod +x create_template.sh
```

### Template has wrong paths
- Make sure you run the script from the Calories Deficit Tracker directory
- The script uses relative paths

### Placeholders not replaced
- The script uses `sed` which may behave differently on Linux
- Check the script's `replace_in_file` function
- Manually replace if needed

### Missing files
- Some files are optional (Config.plist, entitlements)
- The script will warn but continue
- You can add them manually later

## Tips

1. **Test the template first**: Generate a test template and verify it builds before using for a real app

2. **Keep the script updated**: As you improve the source app, update the template sections in the script

3. **Document customizations**: If you add features to a template-based app, consider if they should be in the template generator

4. **Use version control**: Commit the template generator script so you can track improvements

## Example Workflow

```bash
# 1. Generate template
./create_template.sh FitnessTracker

# 2. Open template directory
cd ../FitnessTracker

# 3. Find and replace (use your editor's find/replace)
# {{APP_NAME}} → FitnessTracker
# {{MONTHLY_PRODUCT_ID}} → fitness.monthly
# {{YEARLY_PRODUCT_ID}} → fitness.yearly
# {{PRIVACY_POLICY_URL}} → https://example.com/privacy

# 4. Create Xcode project
# (Create new iOS App project, copy files in)

# 5. Build and customize
```

That's it! The template has all the tested onboarding and paywall code ready to use.
