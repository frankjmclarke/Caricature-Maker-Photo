//
//  GoalSettingsView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import SwiftUI
import SwiftData

struct GoalSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: GoalSettingsViewModel = {
        // Temporary initialization - will be updated in onAppear
        let container = try! ModelContainer(for: UserSettings.self, DailyEntry.self, Meal.self, WeightEntry.self)
        let context = ModelContext(container)
        let dataManager = DataManager(modelContext: context)
        return GoalSettingsViewModel(dataManager: dataManager)
    }()
    
    var body: some View {
        contentView
            .onAppear {
                // Update ViewModel with actual modelContext
                let dataManager = DataManager(modelContext: modelContext)
                viewModel.dataManager = dataManager
                viewModel.loadSettings()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Assumptions")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                    
                    Text("Used to estimate daily calorie needs. Change anytime.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
                
                // Settings Sections
                VStack(spacing: 24) {
                    // BASICS Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("BASICS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        // Sex
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sex")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Picker("Sex", selection: Binding(
                                get: { viewModel.sex },
                                set: { viewModel.updateSex($0) }
                            )) {
                                Text("Female").tag("Female")
                                Text("Male").tag("Male")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Button(action: {
                                    viewModel.decrementAge()
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("\(viewModel.age)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 60)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.incrementAge()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(String(format: "%.0f cm", viewModel.height))
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Stepper("", value: Binding(
                                    get: { viewModel.height },
                                    set: { viewModel.updateHeight($0) }
                                ), in: 100...250, step: 1)
                            }
                        }
                        
                        // Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(String(format: "%.1f kg", viewModel.startingWeight))
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Stepper("", value: Binding(
                                    get: { viewModel.startingWeight },
                                    set: { viewModel.updateWeight($0) }
                                ), in: 30...200, step: 0.1)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // TYPICAL ACTIVITY Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TYPICAL ACTIVITY")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        VStack(spacing: 12) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                Button(action: {
                                    viewModel.updateActivityLevel(level.rawValue)
                                }) {
                                    HStack {
                                        Text(level.rawValue)
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if viewModel.activityLevel == level.rawValue {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.6))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if level != ActivityLevel.allCases.last {
                                    Divider()
                                }
                            }
                        }
                        
                        Text("Used only to estimate daily calorie needs.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // WEEKLY REST DAY Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WEEKLY REST DAY")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            Text("Enable weekly rest day")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.weeklyRestDayEnabled },
                                set: { viewModel.updateWeeklyRestDay($0) }
                            ))
                            .tint(Color(red: 0.2, green: 0.7, blue: 0.6))
                        }
                        
                        Text("Treats one day per week as maintenance to smooth weekly trends.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // DEFICIT PACE Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DEFICIT PACE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Picker("Deficit Pace", selection: Binding(
                            get: { DeficitRate.normalize(viewModel.deficitRate) },
                            set: { viewModel.updateDeficitRate($0) }
                        )) {
                            ForEach(DeficitRate.allCases, id: \.self) { rate in
                                Text(rate.rawValue).tag(rate.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Affects how progress is assessed, not your logged data.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // CALCULATED Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CALCULATED")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text("Estimated daily calories: ~\(viewModel.estimatedCalories) kcal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Calculated using standard metabolic equations.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // ACCOUNT Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        NavigationLink(destination: AccountDeletionView()) {
                            HStack {
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Delete all your local data and reset the app to its initial state. Your subscription will not be affected.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        NavigationLink(destination: SourcesMethodologyView()) {
                            HStack {
                                Text("Sources & Methodology")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GoalSettingsView()
    }
}
