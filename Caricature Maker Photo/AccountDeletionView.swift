//
//  AccountDeletionView.swift
//  Caricature Maker Photo
//
//  Created on 2026-01-20.
//

import SwiftUI
import SwiftData

struct AccountDeletionView: View {
    @Environment(\.modelContext) private var modelContext
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
                        Label("All meal logs and food entries", systemImage: "fork.knife")
                        Label("All weight entries and progress data", systemImage: "chart.line.uptrend.xyaxis")
                        Label("All daily calorie tracking data", systemImage: "calendar")
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
        
        let dataManager = DataManager(modelContext: modelContext)
        dataManager.deleteAllUserData()
        
        // Small delay to ensure data is deleted before dismissing
        // Note: DataManager.deleteAllUserData() already posts "AccountDeleted" notification
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
