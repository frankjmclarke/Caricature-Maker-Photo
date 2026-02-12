//
//  OnboardingView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import SwiftUI
import SwiftData
import UIKit
import SuperwallKit
import StoreKit

var skipPaywall: Bool = true

struct OnboardingView: View {
    @State private var currentStep: Int = 0
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()
    /// Shared entitlement manager provided by the app root.
    /// This ensures onboarding and the main app agree on premium status,
    /// preventing duplicate instances and paywall flashes.
    @ObservedObject var entitlementManager: EntitlementManager
    
    var onComplete: () -> Void
    
    let totalSteps = 13 // screenshot1-4, intro, height, age, sex, weight, activity, deficit, calories, paywall
    
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
                    // Screen 1: Just describe what you ate (custom layout)
                    OnboardingAIDescriptionScreen(step: 0, entitlementManager: entitlementManager)
                        .tag(0)
                    // Screen 2: Burn vs eat (custom layout)
                    OnboardingBurnVsEatScreen(step: 1)
                        .tag(1)
                    // Screen 3: No target weight (custom layout)
                    OnboardingNoTargetWeightScreen(step: 2)
                        .tag(2)
                    // Screen 4: Days don't matter (custom layout)
                    OnboardingDaysDontMatterScreen(step: 3)
                        .tag(3)
                    
                    // Intro to basics
                    OnboardingIntroView(step: 4)
                        .tag(4)
                    
                    // Height input
                    OnboardingHeightView(viewModel: viewModel, step: 5)
                        .tag(5)
                    
                    // Age input
                    OnboardingAgeView(viewModel: viewModel, step: 6)
                        .tag(6)
                    
                    // Sex selection
                    OnboardingSexView(viewModel: viewModel, step: 7)
                        .tag(7)
                    
                    // Weight input
                    OnboardingWeightView(viewModel: viewModel, step: 8)
                        .tag(8)
                    
                    // Activity level
                    OnboardingActivityView(viewModel: viewModel, step: 9)
                        .tag(9)
                    
                    // Deficit pace
                    OnboardingDeficitPaceView(viewModel: viewModel, step: 10)
                        .tag(10)
                    
                    // Estimated daily calories
                    OnboardingCaloriesView(viewModel: viewModel, step: 11)
                        .tag(11)
                    
                    // Paywall
                    OnboardingPaywallView(
                        viewModel: viewModel,
                        entitlementManager: entitlementManager,
                        step: 12
                    )
                        .tag(12)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // Navigation buttons (hidden on paywall screen - PaywallView controls flow)
                if currentStep < totalSteps - 1 {
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                }
            }
            .onAppear {
                // Initialize onboarding ViewModel with real DataManager once
                if viewModel.dataManager == nil {
                    let dataManager = DataManager(modelContext: modelContext)
                    viewModel.dataManager = dataManager
                }
            }
        }
        .navigationViewStyle(.stack)
        .onChange(of: entitlementManager.hasPremiumAccess) { _, hasAccess in
            // When entitlement becomes active, complete onboarding
            if hasAccess && currentStep == totalSteps - 1 {
                // If it's a new purchase, wait a bit to show welcome message
                // If it's existing access, complete immediately
                let delay = entitlementManager.justPurchased ? 3.0 : 0.3
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    completeOnboarding()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompleteOnboarding"))) { _ in
            // Handle completion request from paywall view (for existing subscribers)
            if currentStep == totalSteps - 1 {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        viewModel.saveSettings()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

// MARK: - Onboarding Screen 1: AI Description
struct OnboardingAIDescriptionScreen: View {
    let step: Int
    @ObservedObject var entitlementManager: EntitlementManager
    
    @State private var aiGlow: Double = 0.0
    @State private var aiScale: Double = 1.0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Header
                Text("Just\ndescribe\nwhat you ate")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                
                // Teal-green input field example
                HStack {
                    Text("chicken salad and coffee")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(red: 0.2, green: 0.7, blue: 0.6))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                
                // Logged result box
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Logged ~520 calories")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                
                // Footer with animated AI
                HStack(alignment: .center, spacing: 6) {
                    Text("AI")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(
                            Color(
                                red: 0.0,
                                green: 0.3 + aiGlow * 0.5,
                                blue: 0.8 + aiGlow * 0.2
                            )
                        )
                        .scaleEffect(1.0 + aiScale * 0.15)
                        .shadow(
                            color: Color.cyan.opacity(0.9 + aiGlow * 0.1),
                            radius: 12 + aiGlow * 12
                        )
                        .shadow(
                            color: Color.blue.opacity(0.6 + aiGlow * 0.3),
                            radius: 6 + aiGlow * 6
                        )
                        .overlay(
                            Text("AI")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(
                                    Color.cyan.opacity(0.4 + aiGlow * 0.5)
                                )
                                .blur(radius: 6)
                                .scaleEffect(1.0 + aiScale * 0.15)
                        )
                    Text("estimates calories for you (subscription required)")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            NavigationLink(destination: DebugPurchasesPanel(entitlementManager: entitlementManager)) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
            }
            .padding(.top, 60)
            .padding(.trailing, 20)
            #endif
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                aiGlow = 1.0
            }
            withAnimation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
            ) {
                aiScale = 1.0
            }
        }
    }
}

// MARK: - Debug Purchases Panel
#if DEBUG
struct DebugPurchasesPanel: View {
    @ObservedObject var entitlementManager: EntitlementManager
    @State private var isRefreshing: Bool = false
    @State private var isClearing: Bool = false
    @State private var message: String = ""
    @State private var currentEntitlementStatus: String = ""
    @State private var isSandbox: Bool = false
    
    var body: some View {
        List {
            Section("Current Status") {
                HStack {
                    Text("Premium Active")
                    Spacer()
                    Text(entitlementManager.hasPremiumAccess ? "Yes" : "No")
                        .foregroundColor(entitlementManager.hasPremiumAccess ? .green : .red)
                }
                
                HStack {
                    Text("Sandbox Receipt")
                    Spacer()
                    Text(isSandbox ? "Yes" : "No")
                        .foregroundColor(.secondary)
                }
                
                if !currentEntitlementStatus.isEmpty {
                    HStack {
                        Text("Subscription Status")
                        Spacer()
                        Text(currentEntitlementStatus)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Actions") {
                Button(action: {
                    Task {
                        await refreshEntitlements()
                    }
                }) {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh Entitlements")
                    }
                }
                .disabled(isRefreshing)
                
                Button(action: {
                    clearLocalCache()
                }) {
                    HStack {
                        if isClearing {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                        }
                        Text("Clear Local Purchase Cache")
                    }
                }
                .disabled(isClearing)
            }
            
            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To Reset Sandbox Purchases:")
                        .fontWeight(.semibold)
                    
                    Text("1. App Store Connect → Users and Access → Sandbox → Testers")
                    
                    Text("2. Select your tester → Clear Purchase History")
                    
                    Text("OR use a different sandbox tester account")
                        .foregroundColor(.secondary)
                }
            }
            
            if !message.isEmpty {
                Section {
                    Text(message)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Debug Purchases")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateStatus()
        }
        .onChange(of: entitlementManager.hasPremiumAccess) { _, _ in
            updateStatus()
        }
    }
    
    private func updateStatus() {
        isSandbox = checkSandboxReceipt()
        
        // Get status from EntitlementManager instead of Superwall
        currentEntitlementStatus = entitlementManager.hasPremiumAccess ? "active" : "inactive"
    }
    
    private func checkSandboxReceipt() -> Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent.lowercased().contains("sandboxreceipt")
    }
    
    private func refreshEntitlements() async {
        isRefreshing = true
        message = ""
        
        #if DEBUG
        TraceLogger.trace("DebugPurchasesPanel", "Refreshing entitlements...")
        #endif
        
        // Sync with App Store
        do {
            try await AppStore.sync()
            #if DEBUG
            TraceLogger.trace("DebugPurchasesPanel", "AppStore.sync() completed")
            #endif
        } catch {
            #if DEBUG
            TraceLogger.trace("DebugPurchasesPanel", "AppStore.sync() failed: \(error.localizedDescription)")
            #endif
            message = "Sync failed: \(error.localizedDescription)"
            isRefreshing = false
            return
        }
        
        // Refresh EntitlementManager
        entitlementManager.refreshEntitlement()
        
        // Wait a moment for status to update
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        updateStatus()
        message = "Entitlements refreshed"
        isRefreshing = false
    }
    
    private func clearLocalCache() {
        isClearing = true
        message = ""
        
        #if DEBUG
        TraceLogger.trace("DebugPurchasesPanel", "Clearing local purchase cache...")
        #endif
        
        // Only clear our own cached flags - do NOT modify StoreKit state
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
        
        #if DEBUG
        TraceLogger.trace("DebugPurchasesPanel", "Local cache cleared (UserDefaults only)")
        #endif
        
        message = "Local cache cleared. This does NOT clear StoreKit purchases."
        isClearing = false
    }
}
#endif

// MARK: - Onboarding Screen 2: Burn vs Eat
struct OnboardingBurnVsEatScreen: View {
    let step: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            Text("Burn vs eat")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // You burn card
            VStack(alignment: .leading, spacing: 8) {
                Text("YOU BURN")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("2,520")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("cal/day")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 40)
            .padding(.bottom, 16)
            
            // Circular teal button with chevron
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(red: 0.2, green: 0.7, blue: 0.6))
                    .clipShape(Circle())
            }
            .padding(.bottom, 16)
            
            // You ate card
            VStack(alignment: .leading, spacing: 8) {
                Text("YOU ATE")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("2,020")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("cal today")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
            
            // Footer
            Text("We check if you're eating\nless than you burn")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Screen 3: No Target Weight
struct OnboardingNoTargetWeightScreen: View {
    let step: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            Text("No target\nweight")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // Target weight card with overlapping dismiss button
            GeometryReader { geometry in
                let cardWidth = geometry.size.width - 80 // Screen width minus horizontal padding (40 each side)
                // 80% of card width, then 20% bigger (circular button diameter),
                // but cap the size so it stays visually centered and not clipped on iPad.
                let rawButtonSize = cardWidth * 0.8 * 1.2
                let buttonSize = min(rawButtonSize, 260) // cap diameter for large iPad screens
                let iconSize = buttonSize * 0.6 // X icon size (60% of button diameter)
                
                ZStack(alignment: .center) {
                    // Card background
                    VStack(alignment: .leading, spacing: 0) {
                        // "TARGET WEIGHT" label at top
                        Text("TARGET WEIGHT")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.bottom, 16)
                        
                        // Large "75" number - left-aligned in card
                        HStack {
                            Text("75")
                                .font(.system(size: 72, weight: .bold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.bottom, 12)
                        
                        // "Expected: 15lbs" text at bottom
                        Text("Expected: 15lbs")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Dismiss button (dark blue, circular, 20% bigger, hides text)
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color(red: 0.0, green: 0.2, blue: 0.8))
                            .clipShape(Circle())
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            // Footer
            Text("We track patterns, not\ndestinations")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Screen 4: Days Don't Matter
struct OnboardingDaysDontMatterScreen: View {
    let step: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            Text("Days don't\nmatter")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // Weekly card
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("THIS WEEK")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    // Days of week
                    HStack(spacing: 12) {
                        ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, day in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(dayColor(for: day, at: index))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 32 * 0.15, height: 32 * 0.15)
                                    )
                                Text(day)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Weekly average - centered at bottom
                VStack(alignment: .center, spacing: 4) {
                    Text("WEEKLY AVERAGE")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text("On track")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                }
                .padding(19)
                .background(Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.15))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            // Footer
            Text("Weekly patterns do")
                .font(.system(size: 23, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private func dayColor(for day: String, at index: Int) -> Color {
        // Match the pattern from the image: M orange, T gray, W red, T/F/S/S green
        switch index {
        case 0: return Color.orange // M
        case 1: return Color.gray // T (Tuesday)
        case 2: return Color.red // W
        case 3, 4, 5, 6: return Color(red: 0.2, green: 0.7, blue: 0.6) // T (Thursday), F, S, S
        default: return Color.gray
        }
    }
}

// MARK: - Screenshot Screen
struct ScreenshotScreen: View {
    let imageName: String
    let step: Int
    let header: String
    let footer: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Header text
            Text(header)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Screenshot image from Assets
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 600)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else {
                // Fallback placeholder if image not found
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 300, height: 600)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Screenshot \(step + 1)")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            Text("Add \(imageName).png to Assets")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.top, 4)
                        }
                    )
            }
            
            // Footer text
            Text(footer)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Intro View
struct OnboardingIntroView: View {
    let step: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Now, we need a few basics")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("(to estimate calories)")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Sex View
struct OnboardingSexView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your sex?")
                .font(.system(size: 28, weight: .bold))
            
            Picker("Sex", selection: Binding(
                get: { viewModel.sex },
                set: { viewModel.sex = $0 }
            )) {
                Text("Female").tag("Female")
                Text("Male").tag("Male")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Age View
struct OnboardingAgeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("How old are you?")
                .font(.system(size: 28, weight: .bold))
            
            HStack(spacing: 30) {
                Button(action: {
                    viewModel.decrementAge()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                
                Text("\(viewModel.age)")
                    .font(.system(size: 48, weight: .bold))
                    .frame(minWidth: 80)
                
                Button(action: {
                    viewModel.incrementAge()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Height View
struct OnboardingHeightView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your height?")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 20) {
                Text(String(format: "%.0f cm", viewModel.height))
                    .font(.system(size: 48, weight: .bold))
                
                Stepper("", value: Binding(
                    get: { viewModel.height },
                    set: { viewModel.height = $0 }
                ), in: 100...250, step: 1)
                .labelsHidden()
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Weight View
struct OnboardingWeightView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your weight?")
                .font(.system(size: 28, weight: .bold))
            
            VStack(spacing: 20) {
                Text(String(format: "%.1f kg", viewModel.weight))
                    .font(.system(size: 48, weight: .bold))
                
                Stepper("", value: Binding(
                    get: { viewModel.weight },
                    set: { viewModel.weight = $0 }
                ), in: 30...200, step: 0.1)
                .labelsHidden()
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Activity View
struct OnboardingActivityView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your typical activity level?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button(action: {
                        viewModel.activityLevel = level.rawValue
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.activityLevel == level.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(viewModel.activityLevel == level.rawValue ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Deficit Pace View
struct OnboardingDeficitPaceView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your target pace?")
                .font(.system(size: 28, weight: .bold))
            
            Picker("Deficit Pace", selection: Binding(
                get: { viewModel.deficitRate },
                set: { viewModel.deficitRate = $0 }
            )) {
                ForEach(DeficitRate.allCases, id: \.self) { rate in
                    Text(rate.rawValue).tag(rate.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Calories View
struct OnboardingCaloriesView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let step: Int
    @State private var showSourcesSheet = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Estimated maintenance calories (TDEE)")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("~\(viewModel.estimatedCalories) kcal/day")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.blue)
            
            Text("Estimate based on the Mifflin–St Jeor equation and your selected activity level.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showSourcesSheet = true
            }) {
                Text("Sources & Methodology")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showSourcesSheet) {
            SourcesMethodologyView()
        }
    }
}

// MARK: - Onboarding Paywall View
struct OnboardingPaywallView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var entitlementManager: EntitlementManager
    let step: Int
    
    #if DEBUG
    private struct ViewState: Equatable {
        let isLoading: Bool
        let hasPremiumAccess: Bool
        let justPurchased: Bool
    }
    private static var lastLoggedViewState: ViewState?
    #endif
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Trace the decision path (only log on state changes)
            let _ = {
                #if DEBUG
                let currentState = ViewState(
                    isLoading: entitlementManager.isLoading,
                    hasPremiumAccess: entitlementManager.hasPremiumAccess,
                    justPurchased: entitlementManager.justPurchased
                )
                
                // Only log if state changed
                if Self.lastLoggedViewState != currentState {
                    Self.lastLoggedViewState = currentState
                    TraceLogger.trace("OnboardingPaywallView", "RENDERING: State changed")
                    TraceLogger.traceState("OnboardingPaywallView", [
                        "isLoading": entitlementManager.isLoading,
                        "hasPremiumAccess": entitlementManager.hasPremiumAccess,
                        "justPurchased": entitlementManager.justPurchased
                    ])
                    
                    if entitlementManager.isLoading && !entitlementManager.hasPremiumAccess {
                        TraceLogger.trace("OnboardingPaywallView", "DECISION: Showing Processing spinner")
                    } else if entitlementManager.hasPremiumAccess && entitlementManager.justPurchased {
                        TraceLogger.trace("OnboardingPaywallView", "DECISION: Showing Welcome message")
                    } else if entitlementManager.hasPremiumAccess && !entitlementManager.justPurchased {
                        TraceLogger.trace("OnboardingPaywallView", "DECISION: Skipping paywall (existing access)")
                    } else {
                        TraceLogger.trace("OnboardingPaywallView", "DECISION: Showing PaywallView")
                    }
                }
                #endif
            }()
            // UI driven by entitlement state changes, not callbacks or timing
            let _ = {
                #if DEBUG
                TraceLogger.trace(
                    "OnboardingPaywallView",
                    "BODY EVAL: skipPaywall=\(skipPaywall), hasPremiumAccess=\(entitlementManager.hasPremiumAccess), hasEverHadPremium=\(entitlementManager.hasEverHadPremium), condition=\(skipPaywall || entitlementManager.hasPremiumAccess || entitlementManager.hasEverHadPremium)"
                )
                #endif
            }()
            if skipPaywall || entitlementManager.hasPremiumAccess || entitlementManager.hasEverHadPremium {
                // User has premium access - show welcome or complete onboarding
                if entitlementManager.justPurchased {
                    // Just purchased - show welcome message briefly
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Welcome to Premium!")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .onAppear {
                        // Auto-complete after showing welcome message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            NotificationCenter.default.post(name: NSNotification.Name("CompleteOnboarding"), object: nil)
                        }
                    }
                } else {
                    // Existing access or skipPaywall - complete onboarding
                    Color.clear
                        .onAppear {
                            #if DEBUG
                            TraceLogger.trace("OnboardingPaywallView", "Color.clear.onAppear: Checking current state before completing")
                            #endif
                            // Complete if we have premium access OR if skipPaywall bypass is enabled
                            if entitlementManager.hasPremiumAccess || skipPaywall {
                                #if DEBUG
                                TraceLogger.trace("OnboardingPaywallView", "Completing onboarding (hasPremiumAccess=\(entitlementManager.hasPremiumAccess), skipPaywall=\(skipPaywall))")
                                #endif
                                NotificationCenter.default.post(name: NSNotification.Name("CompleteOnboarding"), object: nil)
                            } else {
                                #if DEBUG
                                TraceLogger.trace("OnboardingPaywallView", "Color.clear.onAppear: State changed - hasPremiumAccess=\(entitlementManager.hasPremiumAccess), skipPaywall=\(skipPaywall) - NOT completing")
                                #endif
                                // State was corrected - don't complete onboarding, view will re-render to show paywall
                            }
                        }
                }
            } else if entitlementManager.isLoading {
                // Loading - show spinner while checking entitlement
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Processing...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            } else {
                // No premium access and not loading - show paywall
                SimplePaywallView(
                    onResult: { result in
                        switch result {
                        case .purchased(let productID):
                            #if DEBUG
                            TraceLogger.trace("OnboardingPaywallView", "SimplePaywallView result: PURCHASED - \(productID)")
                            #endif
                            // Mark as new purchase and start loading state
                            entitlementManager.markNewPurchase()
                            // Immediately refresh entitlements to detect the new transaction
                            // The transaction should be available in Transaction.currentEntitlements
                            Task { @MainActor in
                                // Give StoreKit a moment to process the transaction
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                entitlementManager.refreshEntitlement()
                            }
                            // Existing refreshEntitlement logic will update hasPremiumAccess and
                            // trigger onboarding completion via onChange handlers.
                        case .restored:
                            #if DEBUG
                            TraceLogger.trace("OnboardingPaywallView", "SimplePaywallView result: RESTORED")
                            #endif
                            // Restore is not a new purchase - just refresh entitlement state
                            entitlementManager.isLoading = true
                            entitlementManager.justPurchased = false // Restore is not a new purchase
                            entitlementManager.refreshEntitlement()
                        case .declined:
                            #if DEBUG
                            TraceLogger.trace("OnboardingPaywallView", "SimplePaywallView result: DECLINED - should not happen (no skip button)")
                            #endif
                            // This should not happen - no skip button exists
                            break
                        case .error(let errorMessage):
                            #if DEBUG
                            TraceLogger.trace("OnboardingPaywallView", "SimplePaywallView result: ERROR - \(errorMessage)")
                            #endif
                            // Error occurred - user can retry
                        }
                    }
                )
            }
        }
        .onAppear {
            #if DEBUG
            TraceLogger.trace(
                "OnboardingPaywallView",
                "onAppear: currentState: hasPremiumAccess=\(entitlementManager.hasPremiumAccess), hasEverHadPremium=\(entitlementManager.hasEverHadPremium), isLoading=\(entitlementManager.isLoading)"
            )
            #endif
            // If we've ever had premium in this session, don't try to re-show or re-verify here.
            // Let the shared EntitlementManager state drive completion instead.
            if entitlementManager.hasEverHadPremium {
                #if DEBUG
                TraceLogger.trace("OnboardingPaywallView", "onAppear: hasEverHadPremium=true - skipping paywall refresh")
                #endif
                return
            }
            
            // Only refresh if we have premium access (to verify it's still valid)
            // If no access, show paywall immediately without refreshing
            if entitlementManager.hasPremiumAccess {
                #if DEBUG
                TraceLogger.trace("OnboardingPaywallView", "onAppear: Refreshing entitlement (has premium access - verifying)")
                #endif
                entitlementManager.refreshEntitlement()
            } else {
                #if DEBUG
                TraceLogger.trace("OnboardingPaywallView", "onAppear: No premium access - showing paywall")
                #endif
                // Ensure we're not in loading state when showing paywall
                if entitlementManager.isLoading {
                    entitlementManager.isLoading = false
                }
            }
        }
        .onChange(of: entitlementManager.hasPremiumAccess) { _, hasAccess in
            #if DEBUG
            TraceLogger.trace("OnboardingPaywallView", "onChange(hasPremiumAccess): \(hasAccess)")
            #endif
            // When entitlement becomes active, complete onboarding immediately
            // UI is driven by state changes, not callbacks
            if hasAccess {
                // Small delay to ensure UI has updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("CompleteOnboarding"), object: nil)
                }
            }
        }
        .onChange(of: entitlementManager.isLoading) { _, isLoading in
            #if DEBUG
            TraceLogger.trace("OnboardingPaywallView", "onChange(isLoading): \(isLoading)")
            #endif
            // When loading stops and we have access, UI will update via hasPremiumAccess change
        }
    }
}
