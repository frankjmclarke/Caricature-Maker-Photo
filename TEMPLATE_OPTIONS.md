# Template App Creation Options

## Requirements
- Single screen skeleton app
- MVVM-lite architecture (per `.cursor/mdc/swiftui-architecture.mdc`)
- Onboarding flow (tested and working)
- Paywall with StoreKit 2 (tested and working)
- Delete account button
- Completely independent from Calories Deficit Tracker
- Reusable for building new apps quickly

## Option 1: Automated Script Extraction (RECOMMENDED)

**Approach**: Create a shell script that:
1. Copies the project structure
2. Extracts and sanitizes core components
3. Replaces app-specific strings with placeholders
4. Removes domain-specific code (calorie tracking, etc.)
5. Creates a minimal single-screen ContentView

**Pros**:
- ✅ Automated, repeatable process
- ✅ Can be version-controlled and improved over time
- ✅ Ensures nothing is missed
- ✅ Can be run multiple times as source app evolves

**Cons**:
- ⚠️ Requires initial script development
- ⚠️ Needs testing to ensure it works correctly

**Implementation**:
- Script would extract:
  - `EntitlementManager.swift` (generic, reusable)
  - `SimplePaywallView.swift` (generic, reusable)
  - `OnboardingView.swift` (simplified to generic steps)
  - `AccountDeletionView.swift` (generic, reusable)
  - `TraceLogger.swift` (debug utility)
  - App entry point structure
  - Project configuration files

**Files to create**:
- `create_template.sh` - Main extraction script
- `template_config.json` - Configuration for what to extract/sanitize

---

## Option 2: Manual Starter Template Repository

**Approach**: Manually create a clean template repository with:
- Generic naming (e.g., "AppTemplate" instead of "Calories Deficit Tracker")
- Placeholder product IDs
- Minimal single-screen ContentView
- All reusable components copied and sanitized

**Pros**:
- ✅ Clean, ready-to-use immediately
- ✅ No automation complexity
- ✅ Full control over what's included

**Cons**:
- ⚠️ Manual work required
- ⚠️ Must be maintained separately
- ⚠️ Risk of missing updates from source app

**Structure**:
```
AppTemplate/
├── AppTemplate/
│   ├── AppTemplateApp.swift (generic app entry)
│   ├── ContentView.swift (single screen skeleton)
│   ├── OnboardingView.swift (generic onboarding)
│   ├── SimplePaywallView.swift (reusable paywall)
│   ├── EntitlementManager.swift (reusable)
│   ├── AccountDeletionView.swift (reusable)
│   ├── TraceLogger.swift (debug utility)
│   └── Config.plist.example
└── AppTemplate.xcodeproj/
```

---

## Option 3: Swift Package + Template

**Approach**: 
1. Extract reusable components into a Swift Package (`AppTemplateKit`)
2. Create minimal template app that imports the package

**Pros**:
- ✅ Maximum code reuse across multiple apps
- ✅ Bug fixes in package benefit all apps
- ✅ Clean separation of concerns

**Cons**:
- ⚠️ More complex setup
- ⚠️ Package versioning overhead
- ⚠️ May be overkill for your use case

**Structure**:
```
AppTemplateKit/ (Swift Package)
├── Sources/
│   ├── Paywall/
│   ├── Onboarding/
│   ├── Entitlements/
│   └── AccountDeletion/

AppTemplate/ (Template App)
└── Uses AppTemplateKit via SPM
```

---

## Option 4: Hybrid: Script + Template Repository

**Approach**: Combine Option 1 and 2
- Script extracts and sanitizes components
- Outputs to a template repository
- Template repository is version-controlled separately

**Pros**:
- ✅ Best of both worlds
- ✅ Automated extraction + clean template
- ✅ Template can be customized after extraction

**Cons**:
- ⚠️ Most complex setup
- ⚠️ Two-step process

---

## Recommendation: Option 1 (Automated Script)

**Why**: 
- You mentioned "there is probably a better solution" than copy-paste
- Script ensures consistency and can be improved iteratively
- Can be run whenever the source app is updated
- Minimal maintenance burden once created

**Script would handle**:
1. Copy project structure
2. Replace bundle identifiers with placeholders
3. Replace product IDs with placeholders (`{{MONTHLY_PRODUCT_ID}}`, `{{YEARLY_PRODUCT_ID}}`)
4. Replace app name strings
5. Simplify OnboardingView to generic steps
6. Create minimal ContentView (single screen)
7. Remove domain-specific files (DataManager, Models, AIService, etc.)
8. Sanitize Config.plist
9. Update project.pbxproj references

**Output**: Clean template in `../AppTemplate/` directory

---

## Next Steps

If you choose Option 1, I can:
1. Create the extraction script
2. Define what to extract/sanitize
3. Test it by generating the template
4. Create a README for the template explaining how to customize it

Would you like me to proceed with Option 1, or do you prefer a different approach?
