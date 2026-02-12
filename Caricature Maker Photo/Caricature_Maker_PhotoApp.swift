//
//  Caricature_Maker_PhotoApp.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import SwiftUI
import SwiftData
import SuperwallKit
import StoreKit
import Foundation

#if DEBUG
import Foundation
#endif

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
                                // Wait for StoreKit to process
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                entitlementManager.refreshEntitlement()
                                // Keep checking until entitlement is detected or timeout
                                var attempts = 0
                                while !entitlementManager.hasPremiumAccess && attempts < 15 {
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    entitlementManager.refreshEntitlement()
                                    attempts += 1
                                }
                                isProcessingPurchase = false
                                // If still no access after timeout, allow manual dismissal
                                if !entitlementManager.hasPremiumAccess {
                                    #if DEBUG
                                    TraceLogger.trace("PaywallSheetView", "Purchase timeout: Entitlement not detected after \(attempts) attempts")
                                    #endif
                                }
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
                        case .declined:
                            #if DEBUG
                            TraceLogger.trace("PaywallSheetView", "Purchase result: DECLINED - should not happen (no skip button)")
                            #endif
                            // This should not happen - no skip button exists
                            break
                        case .error(let errorMessage):
                            #if DEBUG
                            TraceLogger.trace("PaywallSheetView", "Purchase result: ERROR - \(errorMessage)")
                            #endif
                            isProcessingPurchase = false
                            purchaseCompleted = false
                            // Error occurred - user can retry
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
                // Show close button after purchase completes (fallback)
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
                // Explicitly dismiss when premium access is detected
                if hasAccess && purchaseCompleted {
                    #if DEBUG
                    TraceLogger.trace("PaywallSheetView", "Premium access detected - dismissing paywall")
                    #endif
                    // Small delay to ensure UI updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

@main
struct Caricature_Maker_PhotoApp: App {
    init(){
        // StoreKit 2 handles subscriptions directly - no configuration needed
        #if DEBUG
        TraceLogger.trace("App", "INIT: App initialized")
        #endif
    }
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [UserSettings.self, DailyEntry.self, Meal.self, WeightEntry.self])
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
                    // After onboarding completes, check if we need to show paywall
                    checkAndShowPaywallIfNeeded()
                })
            } else {
                TabView {
                    CaricatureHomeView()
                        .tabItem {
                            Label("Caricature", systemImage: "face.smiling")
                        }
                    ContentView()
                        .tabItem {
                            Label("Today", systemImage: "flame.fill")
                        }
                }
                .environmentObject(entitlementManager)
                .sheet(isPresented: $showPaywall) {
                        PaywallSheetView(
                            entitlementManager: entitlementManager,
                            onDismiss: {
                                showPaywall = false
                            }
                        )
                    }
                    .onAppear {
                        // Only check paywall if user doesn't have, and has never had, premium access
                        // This prevents paywall from reappearing after successful purchase
                        if !entitlementManager.hasPremiumAccess && !entitlementManager.hasEverHadPremium {
                            checkAndShowPaywallIfNeeded()
                        }
                    }
                    .onChange(of: entitlementManager.hasPremiumAccess) { _, hasAccess in
                        // Hide paywall if user gets premium access
                        if hasAccess {
                            showPaywall = false
                            #if DEBUG
                            TraceLogger.trace("AppRootView", "Premium access detected - dismissing paywall and preventing future shows")
                            #endif
                        }
                    }
            }
        }
        .onAppear {
            // Initial check when app launches
            if !showOnboarding {
                // Only check paywall if user doesn't already have, and has never had, premium access.
                // This prevents unnecessary checks and avoids any App Store sign-in prompts.
                if !entitlementManager.hasPremiumAccess && !entitlementManager.hasEverHadPremium {
                    // Let EntitlementManager finish its initial check, then decide about paywall.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkAndShowPaywallIfNeeded()
                    }
                } else {
                    #if DEBUG
                    TraceLogger.trace("AppRootView", "onAppear: Premium access already active (hasPremiumAccess=\(entitlementManager.hasPremiumAccess), hasEverHadPremium=\(entitlementManager.hasEverHadPremium)) - skipping paywall check on launch")
                    #endif
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccountDeleted"))) { _ in
            // Reset app to onboarding state after account deletion
            #if DEBUG
            TraceLogger.trace("AppRootView", "AccountDeleted notification received - resetting to onboarding")
            #endif
            showOnboarding = true
            showPaywall = false
        }
    }
    
    private func checkAndShowPaywallIfNeeded() {
        // CRITICAL: Never show paywall if user already has, or has EVER had, premium access
        // Also, never show while a new purchase is in its justPurchased window (debounce).
        // Respect skipPaywall for testing (bypasses post-onboarding paywall).
        if skipPaywall || entitlementManager.hasPremiumAccess || entitlementManager.hasEverHadPremium || entitlementManager.justPurchased {
            #if DEBUG
            TraceLogger.trace(
                "AppRootView",
                "checkAndShowPaywallIfNeeded: Skipping (skipPaywall=\(skipPaywall), hasPremiumAccess=\(entitlementManager.hasPremiumAccess), hasEverHadPremium=\(entitlementManager.hasEverHadPremium), justPurchased=\(entitlementManager.justPurchased))"
            )
            #endif
            // Ensure paywall is dismissed if it's somehow still showing
            if showPaywall {
                showPaywall = false
            }
            return
        }
        
        // Show paywall if user has completed onboarding but doesn't have premium access
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Wait for initial entitlement check to complete before showing paywall
        guard hasCompleted else { return }
        
        // If initial check hasn't completed, wait for it
        if !entitlementManager.isInitialCheckComplete {
            #if DEBUG
            TraceLogger.trace("AppRootView", "checkAndShowPaywallIfNeeded: Waiting for initial entitlement check to complete")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkAndShowPaywallIfNeeded()
            }
            return
        }
        
        // If still loading, wait a bit longer
        if entitlementManager.isLoading {
            #if DEBUG
            TraceLogger.trace("AppRootView", "checkAndShowPaywallIfNeeded: Entitlement check in progress, waiting...")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkAndShowPaywallIfNeeded()
            }
            return
        }
        
        // Initial check complete and not loading - check if we need to show paywall
        if !entitlementManager.hasPremiumAccess {
            #if DEBUG
            TraceLogger.trace("AppRootView", "checkAndShowPaywallIfNeeded: No premium access found - showing paywall")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Double-check premium access hasn't changed before showing
                if !entitlementManager.hasPremiumAccess {
                    showPaywall = true
                }
            }
        } else {
            #if DEBUG
            TraceLogger.trace("AppRootView", "checkAndShowPaywallIfNeeded: Premium access found - not showing paywall")
            #endif
        }
    }
}
