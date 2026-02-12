//
//  EntitlementManager.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-13.
//

import Foundation
import SuperwallKit
import Combine
import StoreKit

#if DEBUG
import Foundation
#endif

/// Observes StoreKit subscription state and publishes changes reactively
/// This is the single source of truth for premium access status
@MainActor
class EntitlementManager: ObservableObject {
    @Published var hasPremiumAccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var justPurchased: Bool = false // True only when purchase just completed
    @Published var isInitialCheckComplete: Bool = false // Track if initial entitlement check has completed
    /// Becomes true once premium access has ever been detected during this app session.
    /// Used to suppress any future paywall presentation, even if there are transient
    /// entitlement glitches while StoreKit catches up.
    @Published var hasEverHadPremium: Bool = false
    
    private var isNewPurchase: Bool = false // Track if current loading is from a new purchase
    private var wasJustReset: Bool = false // Track if we just did a force reset
    private var cancellables = Set<AnyCancellable>()
    private var observationTask: Task<Void, Never>?
    private var transactionUpdateTask: Task<Void, Never>?
    
    private let subscriptionProductIDs = ["cariactureMonthly", "cariactureYearly"]
    
    #if DEBUG
    // Track last logged state to prevent duplicate logs
    private var lastLoggedState: (hasPremiumAccess: Bool, isLoading: Bool, justPurchased: Bool)?
    #endif
    
    init() {
        // Ensure we start with no access (will update when StoreKit verifies)
        hasPremiumAccess = false
        isLoading = false
        justPurchased = false
        isInitialCheckComplete = false
        
        #if DEBUG
        TraceLogger.trace("EntitlementManager", "INIT: Starting with hasPremiumAccess=false, isLoading=false, justPurchased=false, isInitialCheckComplete=false")
        #endif
        
        // Check initial state
        // Note: We don't call AppStore.sync() here because:
        // 1. It can trigger unwanted App Store sign-in prompts
        // 2. StoreKit 2's Transaction.currentEntitlements works without explicit sync
        // 3. Transaction.updates stream handles real-time changes automatically
        Task {
            await checkEntitlements()
            await MainActor.run {
                isInitialCheckComplete = true
                #if DEBUG
                TraceLogger.trace("EntitlementManager", "Initial entitlement check completed")
                #endif
            }
        }
        
        // Observe StoreKit transaction updates
        startObserving()
        
        // Listen for reset notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResetEntitlementManager"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.forceReset()
            }
        }
    }
    
    /// Start observing StoreKit transaction updates
    private func startObserving() {
        // Observe Transaction.updates stream for real-time changes
        transactionUpdateTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                await self.handleTransactionUpdate(result)
            }
        }
        
        // Also poll periodically to catch any missed updates
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkEntitlements()
                
                // Poll more frequently when loading (waiting for purchase)
                let interval: TimeInterval = self?.isLoading ?? false ? 0.5 : 5.0
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    /// Handle a transaction update from StoreKit
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // Check if this is one of our subscription products
            if subscriptionProductIDs.contains(transaction.productID) {
                #if DEBUG
                TraceLogger.trace("EntitlementManager", "Transaction update: \(transaction.productID)")
                #endif
                await checkEntitlements()
                await transaction.finish()
            }
        case .unverified:
            // Ignore unverified transactions
            break
        }
    }
    
    /// Check current entitlements from StoreKit
    private func checkEntitlements() async {
        var foundActive = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if this is one of our subscription products
                if subscriptionProductIDs.contains(transaction.productID) {
                    #if DEBUG
                    TraceLogger.trace("EntitlementManager", "StoreKit: Found active transaction - \(transaction.productID)")
                    #endif
                    foundActive = true
                    break
                }
            case .unverified:
                // Transaction exists but couldn't verify - don't trust it
                continue
            }
        }
        
        await MainActor.run {
            let wasActive = hasPremiumAccess
            hasPremiumAccess = foundActive
            if foundActive && !hasEverHadPremium {
                hasEverHadPremium = true
                #if DEBUG
                TraceLogger.trace("EntitlementManager", "FLAG: hasEverHadPremium set to true (premium detected at least once this session)")
                #endif
            }
            
            #if DEBUG
            // Only log if state actually changed
            let currentState = (hasPremiumAccess: hasPremiumAccess, isLoading: isLoading, justPurchased: justPurchased)
            if let lastState = lastLoggedState,
               lastState.hasPremiumAccess == currentState.hasPremiumAccess,
               lastState.isLoading == currentState.isLoading,
               lastState.justPurchased == currentState.justPurchased {
                // State unchanged, skip logging
            } else {
                lastLoggedState = currentState
                TraceLogger.traceState("EntitlementManager", [
                    "hasPremiumAccess": hasPremiumAccess,
                    "isLoading": isLoading,
                    "justPurchased": justPurchased
                ])
            }
            #endif
            
            // Stop loading when entitlement check completes
            if isLoading {
                isLoading = false
            }
            
            // Handle active entitlement
            if foundActive {
                // Only set justPurchased if this was a new purchase (not restore or existing access)
                if isNewPurchase {
                    justPurchased = true
                    #if DEBUG
                    TraceLogger.trace("EntitlementManager", "ACTIVATED: New purchase detected - setting justPurchased=true")
                    #endif
                    // Reset justPurchased after a delay (so UI can show welcome message)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        justPurchased = false
                    }
                } else {
                    #if DEBUG
                    TraceLogger.trace("EntitlementManager", "ACTIVATED: Restore or existing access - justPurchased=false")
                    #endif
                    justPurchased = false
                }
                isNewPurchase = false // Reset flag
            } else {
                // No active entitlement found
                justPurchased = false
                isNewPurchase = false
            }
            
            // Log state changes for debugging
            if wasActive != foundActive {
                #if DEBUG
                TraceLogger.trace("EntitlementManager", "STATE_CHANGE: hasPremiumAccess \(wasActive) → \(foundActive)")
                #endif
            }
            
            if !foundActive {
                #if DEBUG
                TraceLogger.trace("EntitlementManager", "StoreKit: No active transactions found")
                #endif
            }
        }
    }
    
    /// Manually check entitlement (e.g., after purchase or restore)
    func refreshEntitlement() {
        // Don't refresh if we just did a force reset (prevents spinner after reset)
        if wasJustReset {
            #if DEBUG
            TraceLogger.trace("EntitlementManager", "refreshEntitlement() called but skipping (wasJustReset=true)")
            #endif
            return
        }
        
        #if DEBUG
        TraceLogger.trace("EntitlementManager", "refreshEntitlement() called - setting isLoading=true")
        #endif
        isLoading = true
        Task {
            await checkEntitlements()
        }
    }
    
    /// Mark that a new purchase is in progress (not restore)
    func markNewPurchase() {
        #if DEBUG
        TraceLogger.trace("EntitlementManager", "markNewPurchase() called - setting isNewPurchase=true, isLoading=true")
        #endif
        isNewPurchase = true
        isLoading = true
    }
    
    /// Force reset all entitlement state (for testing/debugging)
    func forceReset() {
        #if DEBUG
        TraceLogger.trace("EntitlementManager", "FORCE_RESET: Clearing all state")
        lastLoggedState = nil // Reset logged state to force next update to log
        #endif
        
        // Stop any ongoing observation temporarily
        observationTask?.cancel()
        transactionUpdateTask?.cancel()
        
        // Set flag to prevent immediate refresh
        wasJustReset = true
        
        // Reset all state
        hasPremiumAccess = false
        isLoading = false
        justPurchased = false
        isNewPurchase = false
        isInitialCheckComplete = false
        hasEverHadPremium = false
        
        #if DEBUG
        TraceLogger.traceState("EntitlementManager", [
            "afterReset_hasPremiumAccess": hasPremiumAccess,
            "afterReset_isLoading": isLoading,
            "afterReset_justPurchased": justPurchased
        ])
        lastLoggedState = (false, false, false)
        #endif
        
        // Restart observation with clean state
        startObserving()
        
        // Clear the reset flag after a delay (so onAppear won't trigger refresh)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            wasJustReset = false
            #if DEBUG
            TraceLogger.trace("EntitlementManager", "Reset flag cleared - normal operation resumed")
            #endif
        }
    }
    
    #if DEBUG
    /// Debug helper: Clear all StoreKit transactions for testing
    /// This will revoke premium access by finishing all transactions
    func clearTransactionsForTesting() async {
        TraceLogger.trace("EntitlementManager", "clearTransactionsForTesting() called")
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if subscriptionProductIDs.contains(transaction.productID) {
                    await transaction.finish()
                    TraceLogger.trace("EntitlementManager", "Finished transaction: \(transaction.productID)")
                }
            case .unverified:
                continue
            }
        }
        hasPremiumAccess = false
        isLoading = false
        TraceLogger.trace("EntitlementManager", "All transactions cleared - state reset")
    }
    #endif
    
    deinit {
        observationTask?.cancel()
        transactionUpdateTask?.cancel()
    }
}
