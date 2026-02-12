# App Store Submission Checklist

## ✅ Fixed Issues

### 1. Testing Flags Disabled
- ✅ `forceOnboarding` set to `false` (was `true`)
- ✅ `forceShowPaywall` set to `false` (was `true`)
- **Location**: `OnboardingView.swift` lines 14, 18

### 2. Hardcoded API Key Removed
- ✅ Removed hardcoded Superwall API key from `Calories_Deficit_TrackerApp.swift`
- ✅ Now loads from `Config.plist` with proper error handling
- ✅ Fails with clear error message if key is missing (no silent fallback)
- **Location**: `Calories_Deficit_TrackerApp.swift` lines 14-30

### 3. Debug Print Statements
- ✅ Wrapped paywall-related print statements in `#if DEBUG` blocks
- **Note**: Other debug prints in `AIService.swift` and `LogFoodView.swift` are error logging, which is acceptable for production

### 4. Config.plist.example Updated
- ✅ Added `SUPERWALL_API_KEY` placeholder to example file
- **Location**: `Config.plist.example`

### 5. Info.plist Keys Configured
- ✅ `NSContactsUsageDescription` - Set for both Debug and Release
- ✅ `NSLocationAlwaysAndWhenInUseUsageDescription` - Set for both Debug and Release
- ✅ `NSLocationWhenInUseUsageDescription` - Set for both Debug and Release
- ✅ `ITSAppUsesNonExemptEncryption` - Set to `NO` for both Debug and Release
- **Location**: `project.pbxproj` build settings

## ⚠️ Remaining Considerations

### Debug Print Statements
The following files contain `print()` statements that are used for error logging:
- `AIService.swift` - Error logging (acceptable for production)
- `LogFoodView.swift` - Error logging (acceptable for production)
- `ViewModels.swift` - Debug logging (consider wrapping in `#if DEBUG` if desired)

**Recommendation**: Error logging is fine for production. If you want to remove debug logs, wrap them in `#if DEBUG` blocks.

### Testing
Before submission, verify:
- [ ] Onboarding flow works correctly (with `forceOnboarding = false`)
- [ ] Paywall displays correctly (with `forceShowPaywall = false`)
- [ ] Purchases work in sandbox environment
- [ ] All features work without debug flags enabled

### App Store Connect
Ensure:
- [ ] App icon is set (✅ Done - icons integrated)
- [ ] Screenshots are uploaded
- [ ] App description is complete
- [ ] Privacy policy URL is provided (if required)
- [ ] Age rating is set
- [ ] Pricing and availability are configured

### Build Configuration
- [ ] Build number incremented for new submission
- [ ] Version number is correct
- [ ] Archive built with Release configuration
- [ ] Code signing is correct

## Security Checklist

- ✅ API keys stored in `Config.plist` (gitignored)
- ✅ No hardcoded secrets in source code
- ✅ `Config.plist.example` provided for other developers
- ✅ `.gitignore` properly configured

## Next Steps

1. **Test the app** with all testing flags disabled
2. **Increment build number** in Xcode (if resubmitting)
3. **Create archive** using Product → Archive
4. **Upload to App Store Connect** using Organizer
5. **Submit for review** in App Store Connect

## Notes

- The app uses Superwall for paywall management
- OpenAI API key is required for AI meal estimation feature
- Both API keys must be in `Config.plist` before building for production
- The app will crash on launch if `SUPERWALL_API_KEY` is missing (intentional - prevents silent failures)
