//
//  SimplePaywallView.swift
//  Caricature Maker Photo
//
//  Created on 2026-01-15.
//

import SwiftUI
import StoreKit

#if DEBUG
import Foundation
#endif

enum PaywallResult {
    case purchased(productID: String)
    case restored
    case declined
    case error(String)
}

struct SimplePaywallView: View {
    let productIDs = ["cariactureMonthly", "cariactureYearly"]
    let onResult: (PaywallResult) -> Void
    
    @State private var products: [Product] = []
    @State private var isLoadingProducts = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var purchasingProductID: String?
    
    // Legal document URLs - Update these with your actual URLs
    private let privacyPolicyURL = URL(string: "https://francisclarke.com/apple/privacy-policy-apple-calories.html")!
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    init(onResult: @escaping (PaywallResult) -> Void) {
        self.onResult = onResult
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Compact for iPad visibility
                    VStack(spacing: 8) {
                        Text("Premium Subscription")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Access all features with a subscription")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Text("Includes food logging, calorie estimation, and trend analysis.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        VStack(spacing: 8) {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                loadProducts()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Products
                    if isLoadingProducts {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.vertical, 40)
                    } else if products.isEmpty {
                        VStack(spacing: 12) {
                            Text("Unable to load subscription options")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            Button("Retry") {
                                loadProducts()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            // Find yearly product for trial info
                            let yearlyProduct = products.first { $0.id == "cariactureYearly" }
                            
                            // Debug logging (wrapped to avoid view builder issues)
                            let _ = {
                                #if DEBUG
                                if let yearlyProduct = yearlyProduct {
                                    if let subscription = yearlyProduct.subscription {
                                        if let trialOffer = subscription.introductoryOffer {
                                            TraceLogger.trace("SimplePaywallView", "Found trial offer: period=\(trialOffer.period.value) \(trialOffer.period.unit), price=\(trialOffer.displayPrice)")
                                        } else {
                                            TraceLogger.trace("SimplePaywallView", "Yearly product has subscription but no introductoryOffer")
                                        }
                                    } else {
                                        TraceLogger.trace("SimplePaywallView", "Yearly product has no subscription info")
                                    }
                                } else {
                                    TraceLogger.trace("SimplePaywallView", "Yearly product not found in products")
                                }
                                #endif
                            }()
                            
                            // Show Free Trial button only if yearly product has an introductory offer from StoreKit
                            let hasYearlyTrial = yearlyProduct?.subscription?.introductoryOffer != nil
                            
                            if let yearlyProduct = yearlyProduct,
                               let subscription = yearlyProduct.subscription,
                               subscription.introductoryOffer != nil {
                                let _ = {
                                    #if DEBUG
                                    TraceLogger.trace("SimplePaywallView", "Showing FreeTrialCard")
                                    #endif
                                }()
                                FreeTrialCard(
                                    product: yearlyProduct,
                                    subscription: subscription,
                                    isPurchasing: isPurchasing && purchasingProductID == yearlyProduct.id,
                                    onPurchase: {
                                        purchaseProduct(yearlyProduct)
                                    }
                                )
                            }
                            
                            // Show regular subscription options (exclude yearly if already shown in FreeTrialCard)
                            ForEach(products.filter { product in
                                // Exclude yearly product if it's shown in FreeTrialCard
                                if hasYearlyTrial && product.id == "cariactureYearly" {
                                    return false
                                }
                                return true
                            }, id: \.id) { product in
                                ProductCard(
                                    product: product,
                                    isPurchasing: isPurchasing && purchasingProductID == product.id,
                                    onPurchase: {
                                        purchaseProduct(product)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Restore button - Must be visible without scrolling
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restore Purchases")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                    }
                    .disabled(isRestoring || isPurchasing || isLoadingProducts)
                    .padding(.top, 12)
                    
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.top, 4)
                    }
                    
                    // Legal links - Required for App Store compliance
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: privacyPolicyURL)
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                            
                            Text("•")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Link("Terms of Use", destination: termsOfUseURL)
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Privacy Policy and Terms of Use links")
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .task {
            loadProducts()
        }
    }
    
    private func loadProducts() {
        #if DEBUG
        TraceLogger.trace("SimplePaywallView", "loadProducts: Loading products for IDs: \(productIDs)")
        #endif
        
        Task {
            isLoadingProducts = true
            errorMessage = nil
            
            do {
                let loadedProducts = try await Product.products(for: productIDs)
                
                #if DEBUG
                TraceLogger.trace("SimplePaywallView", "loadProducts: Loaded \(loadedProducts.count) products")
                #endif
                await MainActor.run {
                    self.products = loadedProducts.sorted { product1, product2 in
                        // Sort: yearly first, then monthly
                        if product1.id == "cariactureYearly" { return true }
                        if product2.id == "cariactureYearly" { return false }
                        return product1.id < product2.id
                    }
                    self.isLoadingProducts = false
                    
                    #if DEBUG
                    TraceLogger.trace("SimplePaywallView", "loadProducts: Products loaded - count: \(self.products.count), IDs: \(self.products.map { $0.id })")
                    #endif
                    
                    if loadedProducts.isEmpty {
                        self.errorMessage = "No subscription options available. Please check your connection and try again."
                        #if DEBUG
                        TraceLogger.trace("SimplePaywallView", "loadProducts: No products loaded - showing error")
                        #endif
                    }
                }
            } catch {
                #if DEBUG
                TraceLogger.trace("SimplePaywallView", "loadProducts: Error loading products - \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    self.isLoadingProducts = false
                    self.errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        guard !isPurchasing else { return }
        
        #if DEBUG
        TraceLogger.trace("SimplePaywallView", "purchaseProduct: Starting purchase for \(product.id)")
        #endif
        
        Task {
            isPurchasing = true
            purchasingProductID = product.id
            errorMessage = nil
            
            #if DEBUG
            TraceLogger.trace("SimplePaywallView", "purchaseProduct: Calling product.purchase()")
            #endif
            
            do {
                let result = try await product.purchase()
                
                #if DEBUG
                // Log the raw result type for debugging
                let resultType: String
                switch result {
                case .success:
                    resultType = "success"
                case .userCancelled:
                    resultType = "userCancelled"
                case .pending:
                    resultType = "pending"
                @unknown default:
                    resultType = "unknown"
                }
                TraceLogger.trace("SimplePaywallView", "purchaseProduct: Purchase result received - type: \(resultType)")
                #endif
                
                switch result {
                case .success(let verification):
                    #if DEBUG
                    TraceLogger.trace("SimplePaywallView", "purchaseProduct: Purchase successful, verifying transaction")
                    #endif
                    switch verification {
                    case .verified(let transaction):
                        #if DEBUG
                        TraceLogger.trace("SimplePaywallView", "purchaseProduct: Transaction verified - \(transaction.productID)")
                        #endif
                        // Finish the transaction - it will now appear in Transaction.currentEntitlements
                        await transaction.finish()
                        #if DEBUG
                        TraceLogger.trace("SimplePaywallView", "purchaseProduct: Transaction finished, calling onResult")
                        #endif
                        await MainActor.run {
                            isPurchasing = false
                            purchasingProductID = nil
                            onResult(.purchased(productID: product.id))
                        }
                    case .unverified(_, let error):
                        #if DEBUG
                        TraceLogger.trace("SimplePaywallView", "purchaseProduct: Transaction unverified - \(error.localizedDescription)")
                        #endif
                        await MainActor.run {
                            isPurchasing = false
                            purchasingProductID = nil
                            errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                            onResult(.error("Purchase verification failed: \(error.localizedDescription)"))
                        }
                    }
                case .userCancelled:
                    #if DEBUG
                    TraceLogger.trace("SimplePaywallView", "purchaseProduct: StoreKit reported userCancelled - checking entitlements anyway (sandbox can report false negatives)")
                    #endif
                    // Sometimes StoreKit reports userCancelled even when purchase succeeds (sandbox/testing issue)
                    // Check entitlements anyway - if purchase succeeded, we'll detect it
                    await MainActor.run {
                        isPurchasing = false
                        purchasingProductID = nil
                        onResult(.declined)
                    }
                    // Removed the delayed onResult(.restored) call, internal entitlement recheck should happen externally via EntitlementManager polling/observing
                    // No further action here.
                case .pending:
                    #if DEBUG
                    TraceLogger.trace("SimplePaywallView", "purchaseProduct: Purchase pending approval")
                    #endif
                    await MainActor.run {
                        isPurchasing = false
                        purchasingProductID = nil
                        errorMessage = "Purchase is pending approval"
                        onResult(.error("Purchase is pending approval"))
                    }
                @unknown default:
                    #if DEBUG
                    TraceLogger.trace("SimplePaywallView", "purchaseProduct: Unknown purchase result")
                    #endif
                    await MainActor.run {
                        isPurchasing = false
                        purchasingProductID = nil
                        errorMessage = "Unknown purchase result"
                        onResult(.error("Unknown purchase result"))
                    }
                }
            } catch {
                #if DEBUG
                TraceLogger.trace("SimplePaywallView", "purchaseProduct: Purchase error - \(error.localizedDescription)")
                TraceLogger.trace("SimplePaywallView", "purchaseProduct: Error type - \(type(of: error))")
                if let storeKitError = error as? StoreKitError {
                    TraceLogger.trace("SimplePaywallView", "purchaseProduct: StoreKitError - \(storeKitError)")
                }
                #endif
                await MainActor.run {
                    isPurchasing = false
                    purchasingProductID = nil
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    onResult(.error("Purchase failed: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func restorePurchases() {
        guard !isRestoring else { return }
        
        Task {
            isRestoring = true
            errorMessage = nil
            
            do {
                try await AppStore.sync()
                await MainActor.run {
                    isRestoring = false
                    onResult(.restored)
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = "Restore failed: \(error.localizedDescription)"
                    onResult(.error("Restore failed: \(error.localizedDescription)"))
                }
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    private var displayName: String {
        if product.id == "cariactureMonthly" {
            return "Monthly"
        } else if product.id == "cariactureYearly" {
            return "Yearly"
        }
        return product.displayName
    }
    
    private var price: String {
        product.displayPrice
    }
    
    // Get subscription period string (e.g., "/month", "/year")
    private var periodString: String {
        guard let subscription = product.subscription else {
            return ""
        }
        return formatPeriodString(subscription.subscriptionPeriod)
    }
    
    // Get charging frequency string for disclosure (e.g., "monthly", "annually")
    private var chargingFrequency: String {
        guard let subscription = product.subscription else {
            return ""
        }
        return formatChargingFrequency(subscription.subscriptionPeriod)
    }
    
    // Check if product has an introductory offer (trial)
    private var hasTrial: Bool {
        product.subscription?.introductoryOffer != nil
    }
    
    // Get trial period string if exists
    private var trialPeriodString: String {
        guard let subscription = product.subscription,
              let trialOffer = subscription.introductoryOffer else {
            return ""
        }
        return formatTrialPeriod(trialOffer.period)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // BILLED AMOUNT - MOST PROMINENT (top, largest font)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if !periodString.isEmpty {
                        Text(periodString)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Trial info - SUBORDINATE (smaller, secondary)
                if hasTrial, !trialPeriodString.isEmpty {
                    Text("Includes \(trialPeriodString) free trial")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Plan name and badge
            HStack {
                Text(displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if product.id == "cariactureYearly" {
                    Text("Best Value")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            
            // EXPLICIT AUTO-RENEWAL DISCLOSURE
            VStack(alignment: .leading, spacing: 4) {
                Text("Then \(price)\(periodString), charged \(chargingFrequency). Auto-renews until canceled.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if hasTrial {
                    Text("Payment starts automatically after trial unless canceled at least 24 hours before trial ends.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
            
            // CTA with billed amount
            Button(action: {
                #if DEBUG
                TraceLogger.trace("SimplePaywallView", "ProductCard: Subscribe button tapped for \(product.id)")
                #endif
                onPurchase()
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        if hasTrial {
                            Text("Start trial, then \(price)\(periodString)")
                                .font(.system(size: 16, weight: .semibold))
                        } else {
                            Text("Subscribe — \(price)\(periodString)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isPurchasing)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // Format subscription period as "/month" or "/year"
    private func formatPeriodString(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "/day"
            } else {
                return "/\(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "/week"
            } else {
                return "/\(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "/month"
            } else {
                return "/\(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "/year"
            } else {
                return "/\(period.value) years"
            }
        @unknown default:
            return "/\(period.value) \(period.unit)"
        }
    }
    
    // Format charging frequency for disclosure text (e.g., "monthly", "annually")
    private func formatChargingFrequency(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "daily"
            } else {
                return "every \(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "weekly"
            } else {
                return "every \(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "monthly"
            } else {
                return "every \(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "annually"
            } else {
                return "every \(period.value) years"
            }
        @unknown default:
            return "every \(period.value) \(period.unit)"
        }
    }
    
    // Format trial period duration
    private func formatTrialPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "1 day"
            } else if period.value == 7 {
                return "1 week"
            } else {
                return "\(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "1 week"
            } else {
                return "\(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "1 month"
            } else {
                return "\(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "1 year"
            } else {
                return "\(period.value) years"
            }
        @unknown default:
            return "\(period.value) \(period.unit)"
        }
    }
}

// Separate Free Trial card using yearly product's trial info
// NOTE: This card is being replaced by ProductCard with trial info, but kept for backward compatibility
// The FreeTrialCard now shows billed amount prominently per 3.1.2 requirements
struct FreeTrialCard: View {
    let product: Product
    let subscription: Product.SubscriptionInfo
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    // Get billed amount (what user will be charged after trial)
    private var billedPrice: String {
        product.displayPrice
    }
    
    // Get subscription period string (e.g., "/month", "/year")
    private var periodString: String {
        return formatPeriodString(subscription.subscriptionPeriod)
    }
    
    // Get charging frequency string for disclosure (e.g., "monthly", "annually")
    private var chargingFrequency: String {
        return formatChargingFrequency(subscription.subscriptionPeriod)
    }
    
    // Get trial period from subscription's introductory offer
    private var trialPeriod: String {
        guard let offer = subscription.introductoryOffer else { return "" }
        return formatTrialPeriod(offer.period)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // BILLED AMOUNT - MOST PROMINENT (top, largest font)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(billedPrice)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if !periodString.isEmpty {
                        Text(periodString)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Trial info - SUBORDINATE (smaller, secondary)
                if !trialPeriod.isEmpty {
                    Text("Includes \(trialPeriod) free trial")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // Plan name and badge
            HStack {
                Text("Yearly")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Best Value")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            // EXPLICIT AUTO-RENEWAL DISCLOSURE
            VStack(alignment: .leading, spacing: 4) {
                Text("Then \(billedPrice)\(periodString), charged \(chargingFrequency). Auto-renews until canceled.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !trialPeriod.isEmpty {
                    Text("Payment starts automatically after trial unless canceled at least 24 hours before trial ends.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
            
            // CTA with billed amount
            Button(action: {
                #if DEBUG
                TraceLogger.trace("SimplePaywallView", "FreeTrialCard: Start Free Trial button tapped for \(product.id)")
                #endif
                onPurchase()
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Start trial, then \(billedPrice)\(periodString)")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isPurchasing)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 2)
        )
    }
    
    // Format subscription period as "/month" or "/year"
    private func formatPeriodString(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "/day"
            } else {
                return "/\(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "/week"
            } else {
                return "/\(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "/month"
            } else {
                return "/\(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "/year"
            } else {
                return "/\(period.value) years"
            }
        @unknown default:
            return "/\(period.value) \(period.unit)"
        }
    }
    
    // Format charging frequency for disclosure text (e.g., "monthly", "annually")
    private func formatChargingFrequency(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "daily"
            } else {
                return "every \(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "weekly"
            } else {
                return "every \(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "monthly"
            } else {
                return "every \(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "annually"
            } else {
                return "every \(period.value) years"
            }
        @unknown default:
            return "every \(period.value) \(period.unit)"
        }
    }
    
    // Format trial period duration
    private func formatTrialPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            if period.value == 1 {
                return "1 day"
            } else if period.value == 7 {
                return "1 week"
            } else {
                return "\(period.value) days"
            }
        case .week:
            if period.value == 1 {
                return "1 week"
            } else {
                return "\(period.value) weeks"
            }
        case .month:
            if period.value == 1 {
                return "1 month"
            } else {
                return "\(period.value) months"
            }
        case .year:
            if period.value == 1 {
                return "1 year"
            } else {
                return "\(period.value) years"
            }
        @unknown default:
            return "\(period.value) \(period.unit)"
        }
    }
}
