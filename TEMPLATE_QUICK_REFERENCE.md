# Template Generator - Quick Reference

## One-Liner Usage

```bash
./create_template.sh AppName
```

## What Gets Created

```
../AppName/
├── AppName/
│   ├── {{APP_NAME}}App.swift          # App entry + paywall logic
│   ├── ContentView.swift              # Single screen skeleton
│   ├── OnboardingView.swift           # Simplified onboarding
│   ├── EntitlementManager.swift       # StoreKit 2 subscription manager
│   ├── SimplePaywallView.swift        # Reusable paywall UI
│   ├── AccountDeletionView.swift      # Account deletion
│   ├── TraceLogger.swift              # Debug logging utility
│   ├── Config.plist.example           # Configuration template
│   └── Assets.xcassets/               # App assets
└── README.md                          # Full documentation
```

## Placeholders (Find & Replace)

| Find | Replace With |
|------|--------------|
| `{{APP_NAME}}` | Your app name |
| `{{MONTHLY_PRODUCT_ID}}` | Monthly product ID |
| `{{YEARLY_PRODUCT_ID}}` | Yearly product ID |
| `{{PRIVACY_POLICY_URL}}` | Privacy policy URL |

## Files to Edit

1. **All files**: Replace `{{APP_NAME}}`
2. **EntitlementManager.swift**: Update product IDs
3. **SimplePaywallView.swift**: Update product IDs + privacy URL
4. **OnboardingView.swift**: Customize screens
5. **ContentView.swift**: Build your app

## What's Included

✅ MVVM-lite architecture  
✅ Onboarding (3 screens)  
✅ StoreKit 2 paywall  
✅ Account deletion  
✅ Single screen skeleton  
✅ Debug logging  
✅ Production-ready code  

## Next Steps After Generation

1. Replace placeholders
2. Create Xcode project
3. Copy files into project
4. Configure bundle ID & signing
5. Set up App Store Connect products
6. Build and test

---

**Full docs**: See `TEMPLATE_USAGE.md` for detailed instructions.
