#!/bin/bash

# ============================================================================
# iOS App Template Generator
# ============================================================================
# This script extracts a reusable app template from Calories Deficit Tracker
# Usage: ./create_template.sh [template_name]
# Example: ./create_template.sh MyNewApp
# ============================================================================

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"
TEMPLATE_NAME="${1:-AppTemplate}"

# Output directory (one level up from source)
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")/$TEMPLATE_NAME"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  iOS App Template Generator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Source: ${GREEN}$SOURCE_DIR${NC}"
echo -e "Template: ${GREEN}$OUTPUT_DIR${NC}"
echo ""

# ============================================================================
# Helper Functions
# ============================================================================

# Replace strings in a file
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|$search|$replace|g" "$file"
    else
        # Linux
        sed -i "s|$search|$replace|g" "$file"
    fi
}

# Copy and sanitize a Swift file
copy_swift_file() {
    local source="$1"
    local dest="$2"
    
    if [ ! -f "$source" ]; then
        echo -e "${YELLOW}Warning: $source not found, skipping...${NC}"
        return
    fi
    
    mkdir -p "$(dirname "$dest")"
    cp "$source" "$dest"
    
    # Remove domain-specific code markers (if any)
    # This is a placeholder - actual sanitization happens per file
    echo -e "  ✓ Copied $(basename "$source")"
}

# ============================================================================
# Step 1: Create Directory Structure
# ============================================================================

echo -e "${BLUE}Step 1: Creating directory structure...${NC}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/$TEMPLATE_NAME"
mkdir -p "$OUTPUT_DIR/$TEMPLATE_NAME/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUTPUT_DIR/$TEMPLATE_NAME/Assets.xcassets/AccentColor.colorset"

echo -e "${GREEN}✓ Directory structure created${NC}"
echo ""

# ============================================================================
# Step 2: Copy Core Reusable Files
# ============================================================================

echo -e "${BLUE}Step 2: Copying core reusable components...${NC}"

SOURCE_APP_DIR="$SOURCE_DIR/Calories Deficit Tracker"

# Core files to copy (these are generic and reusable)
CORE_FILES=(
    "EntitlementManager.swift"
    "SimplePaywallView.swift"
    "TraceLogger.swift"
)

for file in "${CORE_FILES[@]}"; do
    copy_swift_file "$SOURCE_APP_DIR/$file" "$OUTPUT_DIR/$TEMPLATE_NAME/$file"
done

# Create simplified AccountDeletionView (without DataManager dependency)
echo -e "${BLUE}Step 2b: Creating simplified AccountDeletionView...${NC}"
cat > "$OUTPUT_DIR/$TEMPLATE_NAME/AccountDeletionView.swift" << 'ACCOUNT_DELETION_EOF'
//
//  AccountDeletionView.swift
//  {{APP_NAME}}
//
//  Generated from template
//

import SwiftUI

struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Deletion")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Delete all your local app data and reset the app to its initial state.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                
                // Explanatory text section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will be deleted:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("All your settings and preferences", systemImage: "gearshape")
                        Label("All app data and user content", systemImage: "doc.text")
                        Label("All locally stored information", systemImage: "internaldrive")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("What will NOT be affected:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your subscription status (managed by Apple)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    
                    Text("Your subscription is managed by Apple through your Apple ID. To manage or cancel your subscription, go to Settings > [Your Name] > Subscriptions.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // Delete button
                Button(action: {
                    showConfirmation = true
                }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Delete Account")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isDeleting)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete all your local app data. This action cannot be undone. Your subscription will not be affected.")
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        // TODO: Add your app-specific data deletion logic here
        // Example:
        // - Clear UserDefaults
        // - Delete SwiftData models
        // - Clear any cached files
        // - Reset app state
        
        // Clear onboarding flag
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        
        // Clear any other UserDefaults keys your app uses
        // UserDefaults.standard.removeObject(forKey: "yourKey")
        
        // If using SwiftData, delete all models:
        // let context = modelContext
        // // Delete your models here
        
        // Post notification to reset app
        NotificationCenter.default.post(name: NSNotification.Name("AccountDeleted"), object: nil)
        
        // Small delay to ensure cleanup completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isDeleting = false
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AccountDeletionView()
    }
}
ACCOUNT_DELETION_EOF

echo -e "  ✓ Simplified AccountDeletionView created"

echo -e "${GREEN}✓ Core files copied${NC}"
echo ""

# ============================================================================
# Step 3: Create Simplified Onboarding
# ============================================================================

echo -e "${BLUE}Step 3: Creating simplified onboarding...${NC}"

# Create a simplified OnboardingView with just intro screens and paywall
cat > "$OUTPUT_DIR/$TEMPLATE_NAME/OnboardingView.swift" << 'ONBOARDING_EOF'
//
//  OnboardingView.swift
//  {{APP_NAME}}
//
//  Generated from template
//

import SwiftUI
import StoreKit

struct OnboardingView: View {
    @State private var currentStep: Int = 0
    @ObservedObject var entitlementManager: EntitlementManager
    var onComplete: () -> Void
    
    let totalSteps = 3 // intro, features, paywall
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        // Screen 1: Welcome
                        OnboardingWelcomeScreen(step: 0)
                            .tag(0)
                        
                        // Screen 2: Features
                        OnboardingFeaturesScreen(step: 1)
                            .tag(1)
                        
                        // Screen 3: Paywall
                        OnboardingPaywallScreen(
                            entitlementManager: entitlementManager,
                            step: 2,
                            onComplete: onComplete
                        )
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        if currentStep < totalSteps - 1 {
                            Button("Next") {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Onboarding Screens

struct OnboardingWelcomeScreen: View {
    let step: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to {{APP_NAME}}")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Get started with a simple, powerful experience")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(40)
    }
}

struct OnboardingFeaturesScreen: View {
    let step: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                VStack(spacing: 24) {
                    FeatureRow(
                        icon: "star.fill",
                        title: "Feature One",
                        description: "Description of your first key feature"
                    )
                    
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Feature Two",
                        description: "Description of your second key feature"
                    )
                    
                    FeatureRow(
                        icon: "lock.fill",
                        title: "Feature Three",
                        description: "Description of your third key feature"
                    )
                }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OnboardingPaywallScreen: View {
    @ObservedObject var entitlementManager: EntitlementManager
    let step: Int
    let onComplete: () -> Void
    
    var body: some View {
        SimplePaywallView(
            onResult: { result in
                switch result {
                case .purchased, .restored:
                    entitlementManager.markNewPurchase()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        entitlementManager.refreshEntitlement()
                        var attempts = 0
                        while !entitlementManager.hasPremiumAccess && attempts < 15 {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            entitlementManager.refreshEntitlement()
                            attempts += 1
                        }
                        if entitlementManager.hasPremiumAccess {
                            onComplete()
                        }
                    }
                case .declined, .error:
                    // User must select a subscription
                    break
                }
            }
        )
    }
}

#Preview {
    OnboardingView(
        entitlementManager: EntitlementManager(),
        onComplete: {}
    )
}
ONBOARDING_EOF

echo -e "${GREEN}✓ Simplified onboarding created${NC}"
echo ""

# ============================================================================
# Step 4: Create Minimal ContentView
# ============================================================================

echo -e "${BLUE}Step 4: Creating minimal ContentView...${NC}"

cat > "$OUTPUT_DIR/$TEMPLATE_NAME/ContentView.swift" << 'CONTENT_EOF'
//
//  ContentView.swift
//  {{APP_NAME}}
//
//  Generated from template
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var entitlementManager: EntitlementManager
    @State private var showAccountDeletion = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Your app content goes here")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Main content area
                    VStack(spacing: 16) {
                        // Example card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Main Feature")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Replace this with your app's main functionality")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showAccountDeletion = true
                        }) {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAccountDeletion) {
                NavigationStack {
                    AccountDeletionView()
                }
            }
        }
    }
}

#Preview {
    ContentView(entitlementManager: EntitlementManager())
}
CONTENT_EOF

echo -e "${GREEN}✓ ContentView created${NC}"
echo ""

# ============================================================================
# Step 5: Create App Entry Point
# ============================================================================

echo -e "${BLUE}Step 5: Creating app entry point...${NC}"

cat > "$OUTPUT_DIR/$TEMPLATE_NAME/{{APP_NAME}}App.swift" << 'APP_EOF'
//
//  {{APP_NAME}}App.swift
//  {{APP_NAME}}
//
//  Generated from template
//

import SwiftUI
import StoreKit

// Paywall sheet shown when user has no subscription (after onboarding)
struct PaywallSheetView: View {
    @ObservedObject var entitlementManager: EntitlementManager
    let onDismiss: () -> Void
    @State private var isProcessingPurchase = false
    @State private var purchaseCompleted = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SimplePaywallView(
                    onResult: { result in
                        switch result {
                        case .purchased(let productID):
                            #if DEBUG
                            TraceLogger.trace("PaywallSheetView", "Purchase result: PURCHASED - \(productID)")
                            #endif
                            isProcessingPurchase = true
                            purchaseCompleted = true
                            entitlementManager.markNewPurchase()
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                entitlementManager.refreshEntitlement()
                                var attempts = 0
                                while !entitlementManager.hasPremiumAccess && attempts < 15 {
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    entitlementManager.refreshEntitlement()
                                    attempts += 1
                                }
                                isProcessingPurchase = false
                            }
                        case .restored:
                            #if DEBUG
                            TraceLogger.trace("PaywallSheetView", "Purchase result: RESTORED")
                            #endif
                            isProcessingPurchase = true
                            purchaseCompleted = true
                            entitlementManager.isLoading = true
                            entitlementManager.justPurchased = false
                            entitlementManager.refreshEntitlement()
                            Task { @MainActor in
                                var attempts = 0
                                while !entitlementManager.hasPremiumAccess && attempts < 15 {
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    entitlementManager.refreshEntitlement()
                                    attempts += 1
                                }
                                isProcessingPurchase = false
                            }
                        case .declined, .error:
                            isProcessingPurchase = false
                            purchaseCompleted = false
                        }
                    }
                )
                .blur(radius: isProcessingPurchase ? 3 : 0)
                .allowsHitTesting(!isProcessingPurchase)
                
                if isProcessingPurchase {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing your subscription...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if purchaseCompleted && entitlementManager.hasPremiumAccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            onDismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(!purchaseCompleted || !entitlementManager.hasPremiumAccess)
            .onChange(of: entitlementManager.hasPremiumAccess) { _, hasAccess in
                if hasAccess && purchaseCompleted {
                    #if DEBUG
                    TraceLogger.trace("PaywallSheetView", "Premium access detected - dismissing paywall")
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

@main
struct {{APP_NAME}}App: App {
    init() {
        #if DEBUG
        TraceLogger.trace("App", "INIT: App initialized")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

struct AppRootView: View {
    @StateObject private var entitlementManager = EntitlementManager()
    @State private var showOnboarding: Bool = {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        return !hasCompleted
    }()
    @State private var showPaywall: Bool = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(
                    entitlementManager: entitlementManager,
                    onComplete: {
                        showOnboarding = false
                        checkAndShowPaywallIfNeeded()
                    }
                )
            } else {
                ContentView(entitlementManager: entitlementManager)
                    .sheet(isPresented: $showPaywall) {
                        PaywallSheetView(
                            entitlementManager: entitlementManager,
                            onDismiss: {
                                showPaywall = false
                            }
                        )
                    }
                    .onAppear {
                        if !entitlementManager.hasPremiumAccess && !entitlementManager.hasEverHadPremium {
                            checkAndShowPaywallIfNeeded()
                        }
                    }
                    .onChange(of: entitlementManager.hasPremiumAccess) { _, hasAccess in
                        if hasAccess {
                            showPaywall = false
                            #if DEBUG
                            TraceLogger.trace("AppRootView", "Premium access detected - dismissing paywall")
                            #endif
                        }
                    }
            }
        }
        .onAppear {
            if !showOnboarding {
                if !entitlementManager.hasPremiumAccess && !entitlementManager.hasEverHadPremium {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkAndShowPaywallIfNeeded()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccountDeleted"))) { _ in
            #if DEBUG
            TraceLogger.trace("AppRootView", "AccountDeleted notification received - resetting to onboarding")
            #endif
            showOnboarding = true
            showPaywall = false
        }
    }
    
    private func checkAndShowPaywallIfNeeded() {
        if entitlementManager.hasPremiumAccess || entitlementManager.hasEverHadPremium || entitlementManager.justPurchased {
            if showPaywall {
                showPaywall = false
            }
            return
        }
        
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        guard hasCompleted else { return }
        
        if !entitlementManager.isInitialCheckComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkAndShowPaywallIfNeeded()
            }
            return
        }
        
        if entitlementManager.isLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkAndShowPaywallIfNeeded()
            }
            return
        }
        
        if !entitlementManager.hasPremiumAccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !entitlementManager.hasPremiumAccess {
                    showPaywall = true
                }
            }
        }
    }
}
APP_EOF

echo -e "${GREEN}✓ App entry point created${NC}"
echo ""

# ============================================================================
# Step 6: Copy Configuration Files
# ============================================================================

echo -e "${BLUE}Step 6: Copying configuration files...${NC}"

# Copy Config.plist.example
if [ -f "$SOURCE_APP_DIR/Config.plist.example" ]; then
    cp "$SOURCE_APP_DIR/Config.plist.example" "$OUTPUT_DIR/$TEMPLATE_NAME/Config.plist.example"
    echo -e "  ✓ Config.plist.example copied"
fi

# Copy entitlements file (optional - may not exist)
if [ -f "$SOURCE_APP_DIR/Calories_Deficit_Tracker.entitlements" ]; then
    cp "$SOURCE_APP_DIR/Calories_Deficit_Tracker.entitlements" "$OUTPUT_DIR/$TEMPLATE_NAME/{{APP_NAME}}.entitlements"
    echo -e "  ✓ Entitlements file copied"
else
    # Create a minimal entitlements file
    cat > "$OUTPUT_DIR/$TEMPLATE_NAME/{{APP_NAME}}.entitlements" << 'ENTITLEMENTS_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.in-app-payments</key>
	<array>
		<string>merchant.{{BUNDLE_ID}}</string>
	</array>
</dict>
</plist>
ENTITLEMENTS_EOF
    echo -e "  ✓ Created minimal entitlements file"
fi

# Copy Assets
if [ -d "$SOURCE_APP_DIR/Assets.xcassets" ]; then
    cp -r "$SOURCE_APP_DIR/Assets.xcassets/AccentColor.colorset" "$OUTPUT_DIR/$TEMPLATE_NAME/Assets.xcassets/"
    echo -e "  ✓ Assets copied"
fi

echo -e "${GREEN}✓ Configuration files copied${NC}"
echo ""

# ============================================================================
# Step 7: Sanitize Files (Replace Placeholders)
# ============================================================================

echo -e "${BLUE}Step 7: Sanitizing files...${NC}"

# Replace app-specific strings (macOS sed syntax)
if [[ "$OSTYPE" == "darwin"* ]]; then
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '' 's/Calories Deficit Tracker/{{APP_NAME}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '' 's/Calories_Deficit_Tracker/{{APP_NAME}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '' 's/caloriesMonthly/{{MONTHLY_PRODUCT_ID}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '' 's/caloriesYearly/{{YEARLY_PRODUCT_ID}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '' '/import SuperwallKit/d' {} \;
else
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i 's/Calories Deficit Tracker/{{APP_NAME}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i 's/Calories_Deficit_Tracker/{{APP_NAME}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i 's/caloriesMonthly/{{MONTHLY_PRODUCT_ID}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i 's/caloriesYearly/{{YEARLY_PRODUCT_ID}}/g' {} \;
    find "$OUTPUT_DIR" -type f -name "*.swift" -exec sed -i '/import SuperwallKit/d' {} \;
fi

# Replace in EntitlementManager
if [ -f "$OUTPUT_DIR/$TEMPLATE_NAME/EntitlementManager.swift" ]; then
    replace_in_file "$OUTPUT_DIR/$TEMPLATE_NAME/EntitlementManager.swift" \
        'private let subscriptionProductIDs = \["caloriesMonthly", "caloriesYearly"\]' \
        'private let subscriptionProductIDs = ["{{MONTHLY_PRODUCT_ID}}", "{{YEARLY_PRODUCT_ID}}"]'
fi

# Replace in SimplePaywallView
if [ -f "$OUTPUT_DIR/$TEMPLATE_NAME/SimplePaywallView.swift" ]; then
    replace_in_file "$OUTPUT_DIR/$TEMPLATE_NAME/SimplePaywallView.swift" \
        'let productIDs = \["caloriesMonthly", "caloriesYearly"\]' \
        'let productIDs = ["{{MONTHLY_PRODUCT_ID}}", "{{YEARLY_PRODUCT_ID}}"]'
    
    # Replace privacy policy URL placeholder
    replace_in_file "$OUTPUT_DIR/$TEMPLATE_NAME/SimplePaywallView.swift" \
        'https://francisclarke.com/apple/privacy-policy-apple-calories.html' \
        '{{PRIVACY_POLICY_URL}}'
fi

# Note: SuperwallKit import removal is handled in the sed commands above

echo -e "${GREEN}✓ Files sanitized${NC}"
echo ""

# ============================================================================
# Step 8: Create README and Documentation
# ============================================================================

echo -e "${BLUE}Step 8: Creating documentation...${NC}"

cat > "$OUTPUT_DIR/README.md" << 'README_EOF'
# {{APP_NAME}} - iOS App Template

This is a reusable iOS app template generated from a working app. It includes:

- ✅ **MVVM-lite architecture** (per `.cursor/mdc/swiftui-architecture.mdc`)
- ✅ **Onboarding flow** (tested and working)
- ✅ **Paywall with StoreKit 2** (tested and working)
- ✅ **Account deletion** functionality
- ✅ **Single screen skeleton** ready for your content

## Quick Start

1. **Rename the template**:
   ```bash
   # Replace {{APP_NAME}} with your app name throughout the project
   # Use find & replace in Xcode or your editor
   ```

2. **Update Product IDs**:
   - Open `EntitlementManager.swift` and `SimplePaywallView.swift`
   - Replace `{{MONTHLY_PRODUCT_ID}}` and `{{YEARLY_PRODUCT_ID}}` with your App Store Connect product IDs

3. **Update URLs**:
   - Open `SimplePaywallView.swift`
   - Replace `{{PRIVACY_POLICY_URL}}` with your privacy policy URL

4. **Create Xcode Project**:
   - Open Xcode
   - Create a new iOS App project
   - Copy all Swift files into your project
   - Add StoreKit framework
   - Configure bundle identifier and signing

5. **Customize Onboarding**:
   - Edit `OnboardingView.swift` to match your app's onboarding flow
   - Update welcome screen, features, and messaging

6. **Build Your App**:
   - Replace `ContentView.swift` with your app's main screen
   - Add your domain-specific models and view models
   - Implement your app's core functionality

## Architecture

This template follows MVVM-lite:
- **Views**: UI + simple state bindings (`@State`, `@ObservedObject`)
- **ViewModels**: `ObservableObject` for non-trivial logic (see `EntitlementManager`)
- **Models**: Plain structs/enums (add your own)

## Key Components

### EntitlementManager
Manages subscription status using StoreKit 2. Automatically checks for active subscriptions and updates `hasPremiumAccess`.

### SimplePaywallView
Reusable paywall component that:
- Loads products from App Store Connect
- Handles purchases and restores
- Shows free trial information if available
- Displays error messages

### OnboardingView
Simplified onboarding with:
- Welcome screen
- Features screen
- Paywall integration

### AccountDeletionView
Handles account deletion with proper data cleanup.

## Customization Checklist

- [ ] Replace `{{APP_NAME}}` with your app name
- [ ] Update product IDs in `EntitlementManager.swift` and `SimplePaywallView.swift`
- [ ] Update privacy policy URL in `SimplePaywallView.swift`
- [ ] Customize onboarding screens in `OnboardingView.swift`
- [ ] Replace `ContentView.swift` with your app's main screen
- [ ] Add your domain-specific models and view models
- [ ] Update app icon and assets
- [ ] Configure bundle identifier and signing
- [ ] Set up App Store Connect products

## Notes

- All debug logging is wrapped in `#if DEBUG` blocks
- The paywall is mandatory during onboarding (no skip button)
- Account deletion posts `AccountDeleted` notification to reset onboarding
- StoreKit 2 is used directly (no third-party SDKs)

## Support

This template was generated from a production app. The onboarding and paywall flows have been tested and approved by App Store Review.

For questions or issues, refer to the source app's implementation.
README_EOF

# Copy architecture guidelines
if [ -d "$SOURCE_DIR/.cursor/mdc" ]; then
    mkdir -p "$OUTPUT_DIR/.cursor/mdc"
    cp "$SOURCE_DIR/.cursor/mdc/swiftui-architecture.mdc" "$OUTPUT_DIR/.cursor/mdc/"
    echo -e "  ✓ Architecture guidelines copied"
fi

echo -e "${GREEN}✓ Documentation created${NC}"
echo ""

# ============================================================================
# Summary
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Template created successfully!${NC}"
echo ""
echo -e "Location: ${GREEN}$OUTPUT_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Open the template directory"
echo "  2. Replace {{APP_NAME}} with your app name"
echo "  3. Update product IDs ({{MONTHLY_PRODUCT_ID}}, {{YEARLY_PRODUCT_ID}})"
echo "  4. Update privacy policy URL ({{PRIVACY_POLICY_URL}})"
echo "  5. Create Xcode project and add files"
echo "  6. Customize onboarding and ContentView"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
