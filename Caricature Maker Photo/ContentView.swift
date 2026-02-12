//
//  ContentView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//	

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TodayViewModel()
    
    // Diagnostic feature flag - set to true to show date navigation buttons
    #if DEBUG
    private let showDiagnosticButtons = true
    #else
    private let showDiagnosticButtons = false
    #endif
    
    var body: some View {
        contentView
            .onAppear {
                // Initialize ViewModel with actual modelContext once
                if viewModel.dataManager == nil {
                    let dataManager = DataManager(modelContext: modelContext)
                    viewModel.dataManager = dataManager
                    viewModel.updateData()
                    #if DEBUG
                    debugPrint("DEBUG: Initializing debug meals")
                    dataManager.initializeDebugMealsIfNeeded()
                    #endif
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))) { _ in
                // Refresh when settings change
                viewModel.updateData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MealsChanged"))) { _ in
                // Refresh when meals are added/updated/deleted
                viewModel.updateData()
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                // Refresh when date changes
                viewModel.updateData()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(getFormattedDate())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Text(isToday ? "Today's Progress" : getProgressTitle())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                // Circular Progress Indicator
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: {
                                let percentage = CGFloat(viewModel.completionPercentage) / 100.0
                                if percentage.isNaN || percentage.isInfinite {
                                    return 0.0
                                }
                                if percentage < 0.0 || percentage > 1.0 {
                                    return max(0.0, min(1.0, percentage))
                                }
                                return percentage
                            }())
                            .stroke(
                                viewModel.ringColor,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        // Center content
                        VStack(spacing: 4) {
                            Text("\(viewModel.remainingCalories)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("cal remaining")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Completion percentage badge
                    NavigationLink(destination: YourProgressView()) {
                        Text("\(viewModel.completionPercentage)% complete")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.ringColor
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                
                // Cards
                VStack(spacing: 16) {
                    // Consumed Calories Card
                    NavigationLink(destination: LogFoodView(selectedDate: $viewModel.selectedDate)) {
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.6, blue: 0.2)) // Vibrant orange
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONSUMED")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(formatNumber(viewModel.consumedCalories)) cal")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("of \(formatNumber(viewModel.totalCalories))")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Target Deficit Card
                    NavigationLink(destination: ConsistencyView()) {
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "arrow.down.right")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TARGET DEFICIT")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("\(viewModel.targetDeficit) cal/day")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                
                // Diagnostic navigation buttons
                if showDiagnosticButtons {
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.goToPreviousDay()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Yesterday")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.goToNextDay()
                        }) {
                            HStack {
                                Text("Tomorrow")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: GoalSettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
            }
        }
        }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }
    
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewModel.selectedDate).uppercased()
    }
    
    private func getProgressTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: viewModel.selectedDate) + "'s Progress"
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    ContentView()
}
