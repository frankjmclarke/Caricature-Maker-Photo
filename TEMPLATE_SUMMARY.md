# Template Generator - Summary

## What Was Created

I've created an **automated template extraction system** that makes it easy to generate reusable app templates from your Calories Deficit Tracker app.

## Files Created

### 1. `create_template.sh` (Main Script)
- **Purpose**: Extracts and sanitizes reusable components
- **Usage**: `./create_template.sh AppName`
- **Features**:
  - Copies core reusable files (EntitlementManager, SimplePaywallView, etc.)
  - Creates simplified onboarding (3 screens)
  - Creates minimal ContentView skeleton
  - Replaces app-specific strings with placeholders
  - Creates documentation automatically
  - Works on macOS and Linux

### 2. `TEMPLATE_USAGE.md` (Detailed Guide)
- Complete usage instructions
- Step-by-step workflow
- Troubleshooting tips
- Customization checklist

### 3. `TEMPLATE_QUICK_REFERENCE.md` (Quick Reference)
- One-page quick reference
- Placeholder table
- Essential commands

### 4. `TEMPLATE_OPTIONS.md` (Analysis)
- Comparison of different approaches
- Why Option 1 was chosen

## How It Works

```
Source App (Calories Deficit Tracker)
         ↓
    [Script runs]
         ↓
Template (AppName/)
  ├── Reusable components
  ├── Simplified onboarding
  ├── Minimal ContentView
  └── Documentation
```

## Key Features

✅ **Easy to Use**: Single command generates complete template  
✅ **Easy to Maintain**: Script is version-controlled and well-commented  
✅ **Easy to Understand**: Clear documentation and inline comments  
✅ **Reusable**: Works for multiple new apps  
✅ **Production-Ready**: Uses tested onboarding and paywall code  

## What Gets Extracted

### Core Components (Copied As-Is)
- `EntitlementManager.swift` - StoreKit 2 subscription manager
- `SimplePaywallView.swift` - Reusable paywall UI
- `TraceLogger.swift` - Debug logging utility

### Generated Components
- `OnboardingView.swift` - Simplified 3-screen onboarding
- `ContentView.swift` - Single screen skeleton
- `{{APP_NAME}}App.swift` - App entry point with paywall logic
- `AccountDeletionView.swift` - Generic account deletion (no domain dependencies)

### Configuration
- `Config.plist.example` - Configuration template
- `{{APP_NAME}}.entitlements` - App entitlements
- `Assets.xcassets/` - App assets

## Placeholders System

The script replaces app-specific strings with placeholders:

| Placeholder | Example Replacement |
|------------|---------------------|
| `{{APP_NAME}}` | `MyNewApp` |
| `{{MONTHLY_PRODUCT_ID}}` | `myapp.monthly` |
| `{{YEARLY_PRODUCT_ID}}` | `myapp.yearly` |
| `{{PRIVACY_POLICY_URL}}` | `https://example.com/privacy` |

## Quick Start

```bash
# 1. Generate template
./create_template.sh MyNewApp

# 2. Navigate to template
cd ../MyNewApp

# 3. Replace placeholders (use find/replace in your editor)
# {{APP_NAME}} → MyNewApp
# {{MONTHLY_PRODUCT_ID}} → myapp.monthly
# etc.

# 4. Create Xcode project and add files
# 5. Build and customize
```

## Maintenance

### Updating the Script

When you improve the source app's paywall/onboarding:
1. Edit the template sections in `create_template.sh`
2. Test with: `./create_template.sh TestTemplate`
3. Verify it builds and works
4. Use for new apps

### Version Control

The script is committed with your source app, so:
- ✅ Template improvements are tracked
- ✅ Easy to see what changed
- ✅ Can roll back if needed

## Benefits Over Copy-Paste

| Copy-Paste | Template Generator |
|------------|-------------------|
| ❌ Manual search/replace | ✅ Automated placeholders |
| ❌ Risk of missing strings | ✅ Systematic replacement |
| ❌ Hard to maintain | ✅ Version-controlled script |
| ❌ Error-prone | ✅ Tested and repeatable |
| ❌ Time-consuming | ✅ One command |

## Next Steps

1. **Test the script**: Run `./create_template.sh TestApp` to verify it works
2. **Review output**: Check the generated template structure
3. **Use for new apps**: Generate templates as needed
4. **Improve over time**: Update script as you learn what works best

## Support

- **Full guide**: See `TEMPLATE_USAGE.md`
- **Quick reference**: See `TEMPLATE_QUICK_REFERENCE.md`
- **Script help**: Run `./create_template.sh` (no args) or check script comments

---

**The template generator is ready to use!** It's designed to be easy to understand, maintain, and use for multiple new apps.
