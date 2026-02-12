//
//  LogFoodView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//	

import SwiftUI
import SwiftData

struct LogFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = LogFoodViewModel()
    @Binding var selectedDate: Date
    @State private var showAddMealSheet = false
    @State private var mealToEdit: Meal? = nil
    
    var body: some View {
        contentView
            .sheet(isPresented: $showAddMealSheet) {
                AddMealSheet(viewModel: viewModel, isPresented: $showAddMealSheet, mealToEdit: mealToEdit)
            }
            .onAppear {
                // Initialize ViewModel with actual modelContext once
                if viewModel.dataManager == nil {
                    let dataManager = DataManager(modelContext: modelContext)
                    viewModel.dataManager = dataManager
                }
                // Sync ViewModel's date with binding and load meals
                viewModel.selectedDate = selectedDate
                viewModel.loadMeals()
            }
            .onChange(of: selectedDate) { _, newDate in
                // Keep ViewModel's date in sync with parent
                viewModel.selectedDate = newDate
                viewModel.loadMeals()
            }
            .onChange(of: showAddMealSheet) { oldValue, newValue in
                // Reload meals when sheet is dismissed
                if oldValue == true && newValue == false {
                    // Reset mealToEdit when sheet is dismissed
                    mealToEdit = nil
                    // Small delay to ensure data is saved
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.loadMeals()
                    }
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Log Food")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        mealToEdit = nil
                        showAddMealSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            
            // Today's Meals Section
            VStack(alignment: .leading, spacing: 16) {
                Text("TODAY'S MEALS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                
                // Meal Cards
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.todayMeals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No meals logged today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("Tap the + button to add a meal")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(viewModel.todayMeals) { meal in
                                MealCard(meal: meal, viewModel: viewModel) {
                                    mealToEdit = meal
                                    showAddMealSheet = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct MealCard: View {
    let meal: Meal
    let viewModel: LogFoodViewModel
    let onTap: () -> Void
    
    // Calculate progress percentage (assuming max calories per meal is 600 for visualization)
    private var progressPercentage: Double {
        guard meal.calories > 0 else { return 0 }
        let calories = Double(meal.calories)
        if calories.isNaN || calories.isInfinite {
            return 0.0
        }
        let percentage = calories / 600.0
        if percentage.isNaN || percentage.isInfinite {
            return 0.0
        }
        let clamped = min(1.0, max(0.0, percentage))
        if clamped.isNaN || clamped.isInfinite {
            return 0.0
        }
        return clamped
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side - Meal info
            VStack(alignment: .leading, spacing: 8) {
                Text(meal.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(meal.mealTypeDisplay) • \(meal.timeString)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Right side - Circular calorie indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: {
                        let value = progressPercentage
                        if value.isNaN || value.isInfinite {
                            return 0.0
                        }
                        if value < 0.0 || value > 1.0 {
                            return max(0.0, min(1.0, value))
                        }
                        return value
                    }())
                    .stroke(
                        Color(red: 1.0, green: 0.6, blue: 0.2), // Orange
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                // Calories text
                Text("\(meal.calories)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteMeal(meal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Meal Sheet
struct AddMealSheet: View {
    @ObservedObject var viewModel: LogFoodViewModel
    @Binding var isPresented: Bool
    let mealToEdit: Meal?
    
    @State private var mealName: String = ""
    @State private var calories: String = ""
    @State private var selectedMealType: String = "Breakfast"
    
    // AI Estimation states
    @State private var isEstimating: Bool = false
    @State private var aiEstimation: AIEstimationResponse? = nil
    @State private var aiError: String? = nil
    @State private var adjustmentFactor: Double = 1.0
    @State private var showAIResults: Bool = false
    
    private let aiService = AIService()
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    private var adjustmentPercentage: Int {
        // FIRST check - return immediately, no property access
        if !showAIResults { return 100 }
        
        // DIAGNOSTIC: Check if adjustmentFactor is invalid
        if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
            print("ERROR: adjustmentPercentage - adjustmentFactor is NaN/Infinite: \(adjustmentFactor)")
            return 100
        }
        
        // Get safe factor directly, no computed property call, no side effects
        let factor: Double = {
            if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
                print("ERROR: adjustmentPercentage - factor check found NaN/Infinite")
                return 1.0
            }
            return max(0.5, min(2.0, adjustmentFactor))
        }()
        
        let percent = factor * 100.0
        if percent.isNaN || percent.isInfinite {
            print("ERROR: adjustmentPercentage - percent calculation produced NaN/Infinite: factor=\(factor)")
            return 100
        }
        
        return safeInt(from: percent, fallback: 100)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    TextField("Meal name", text: $mealName)
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    // AI Estimate Button (only show when meal name is not empty)
                    if !mealName.isEmpty {
                        Button(action: {
                            Task {
                                await estimateMeal()
                            }
                        }) {
                            HStack {
                                if isEstimating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isEstimating ? "Estimating..." : "Estimate with AI")
                            }
                        }
                        .disabled(isEstimating)
                    }
                }
                
                // AI Results Section
                if showAIResults, let estimation = aiEstimation {
                    Section {
                        // Total Calories (prominently displayed)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Estimated Calories")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("\(adjustedCalories)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                            
                            if estimation.total.calories.low != estimation.total.calories.high {
                                Text("Range: \(estimation.total.calories.low) - \(estimation.total.calories.high) cal")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            
                            // Adjustment Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Adjust: \(adjustmentPercentage)%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Slider(
                                    value: Binding(
                                        get: {
                                            // Direct check, no computed property
                                            if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
                                                return 1.0
                                            }
                                            return max(0.5, min(2.0, adjustmentFactor))
                                        },
                                        set: { newValue in
                                            adjustmentFactor = newValue.isNaN || newValue.isInfinite ? 1.0 : max(0.5, min(2.0, newValue))
                                        }
                                    ),
                                    in: 0.5...2.0,
                                    step: 0.05
                                )
                                .tint(Color(red: 0.2, green: 0.8, blue: 0.4))
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                        
                        // Macros
                        // Assumptions
                        if !estimation.items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assumptions")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                ForEach(estimation.items, id: \.name) { item in
                                    Text("• \(item.name): \(item.assumptions)")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // Confidence
                        Text("Confidence: \(estimation.confidence.capitalized)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        // One-tap log button
                        Button(action: {
                            logAIEstimatedMeal()
                        }) {
                            HStack {
                                Spacer()
                                Text("Log Meal")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .cornerRadius(10)
                        }
                        .padding(.top, 12)
                    } header: {
                        Text("AI Estimation")
                    }
                }
                
                Section("Calories") {
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(mealToEdit == nil ? "Add Meal" : "Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mealToEdit == nil ? "Add" : "Save") {
                        if mealToEdit != nil {
                            updateMeal()
                        } else {
                            addMeal()
                        }
                    }
                    .disabled(mealName.isEmpty || calories.isEmpty)
                }
            }
            .onAppear {
                // ALWAYS ensure adjustmentFactor is valid FIRST, before anything else
                if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
                    adjustmentFactor = 1.0
                } else {
                    adjustmentFactor = max(0.5, min(2.0, adjustmentFactor))
                }
                
                if let meal = mealToEdit {
                    // Pre-fill form with meal data
                    mealName = meal.name
                    calories = "\(meal.calories)"
                    selectedMealType = meal.mealType
                    
                    // Load AI estimation if available
                    if let aiMetadataJSON = meal.aiMetadataJSON,
                       let data = aiMetadataJSON.data(using: .utf8),
                       let estimation = try? JSONDecoder().decode(AIEstimationResponse.self, from: data) {
                        aiEstimation = estimation
                        showAIResults = true
                        let loadedFactor = meal.aiAdjustmentFactor ?? 1.0
                        // Validate loaded factor before setting
                        if loadedFactor.isNaN || loadedFactor.isInfinite {
                            adjustmentFactor = 1.0
                        } else {
                            adjustmentFactor = max(0.5, min(2.0, loadedFactor))
                        }
                    }
                }
            }
            .onChange(of: adjustmentFactor) { oldValue, newValue in
                // Direct validation, no computed property calls
                if newValue.isNaN || newValue.isInfinite {
                    adjustmentFactor = 1.0
                } else {
                    adjustmentFactor = max(0.5, min(2.0, newValue))
                }
            }
            .onChange(of: mealName) { oldValue, newValue in
                // DIAGNOSTIC: Log when mealName changes
                #if DEBUG
                print("DIAGNOSTIC: mealName changed from '\(oldValue)' to '\(newValue)'")
                print("DIAGNOSTIC: adjustmentFactor = \(adjustmentFactor), isNaN=\(adjustmentFactor.isNaN), isInfinite=\(adjustmentFactor.isInfinite)")
                print("DIAGNOSTIC: showAIResults = \(showAIResults)")
                #endif
                
                // Reset AI results when meal name changes - but ONLY if it was showing
                if showAIResults {
                    showAIResults = false
                    aiEstimation = nil
                }
                // DO NOTHING ELSE - no calculations, no validations, nothing
            }
            .alert("AI Estimation Error", isPresented: .constant(aiError != nil)) {
                Button("OK") {
                    aiError = nil
                }
            } message: {
                Text(aiError ?? "")
            }
        }
    }
    
    // MARK: - Number Validation Helpers
    
    /// Returns a safe adjustment factor (0.5-2.0, never NaN/Infinite)
    private var safeAdjustmentFactor: Double {
        if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
            return 1.0
        }
        return max(0.5, min(2.0, adjustmentFactor))
    }
    
    /// Validates a Double value and converts it to a safe Int
    private func safeInt(from double: Double, fallback: Int = 0) -> Int {
        guard !double.isNaN && !double.isInfinite && double >= 0 && double < Double(Int.max) else {
            return fallback
        }
        return max(0, Int(double.rounded()))
    }
    
    /// Validates an Int value is within safe bounds
    private func safeInt(_ value: Int, fallback: Int = 0) -> Int {
        guard value >= 0 && value < Int.max else {
            return fallback
        }
        return value
    }
    
    /// Calculates adjusted value from midpoint and factor, returning a safe Int
    /// NEVER returns NaN - always returns a valid integer
    private func calculateAdjustedValue(midpoint: Int, factor: Double, fallback: Int = 0) -> Int {
        // Validate factor FIRST - if invalid, return fallback immediately
        guard !factor.isNaN && !factor.isInfinite && factor > 0 && factor < 1000 else {
            return fallback
        }
        
        let safeMidpoint = safeInt(midpoint, fallback: fallback)
        guard safeMidpoint > 0 && safeMidpoint < Int.max / 2 else {
            return fallback
        }
        
        let midpointDouble = Double(safeMidpoint)
        guard !midpointDouble.isNaN && !midpointDouble.isInfinite && midpointDouble > 0 else {
            return fallback
        }
        
        let result = midpointDouble * factor
        guard !result.isNaN && !result.isInfinite && result >= 0 && result < Double(Int.max) else {
            return fallback
        }
        
        let finalValue = Int(result.rounded())
        guard finalValue >= 0 && finalValue < Int.max else {
            return fallback
        }
        
        return finalValue
    }
    
    // MARK: - Computed Properties for Adjusted Values
    // These MUST return immediately with safe values when showAIResults is false
    // to prevent ANY evaluation during typing
    
    private var adjustedCalories: Int {
        // FIRST check - return immediately, no property access
        if !showAIResults { return 0 }
        guard let estimation = aiEstimation else { return 0 }
        
        // DIAGNOSTIC: Check if adjustmentFactor is invalid
        if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
            print("ERROR: adjustedCalories - adjustmentFactor is NaN/Infinite: \(adjustmentFactor)")
            return 0
        }
        
        // Get safe factor directly without computed property
        let factor: Double = {
            if adjustmentFactor.isNaN || adjustmentFactor.isInfinite {
                print("ERROR: adjustedCalories - factor check found NaN/Infinite")
                return 1.0
            }
            return max(0.5, min(2.0, adjustmentFactor))
        }()
        
        let midpoint = estimation.total.calories.midpoint
        // midpoint is Int, so it can't be NaN/Infinite, but check bounds
        if midpoint < 0 || midpoint > Int.max / 2 {
            print("ERROR: adjustedCalories - midpoint out of bounds: \(midpoint)")
            return 0
        }
        
        return calculateAdjustedValue(
            midpoint: midpoint,
            factor: factor
        )
    }
    
    private func estimateMeal() async {
        isEstimating = true
        aiError = nil
        
        do {
            let response = try await aiService.estimateMeal(
                description: mealName,
                mealTime: selectedMealType.lowercased()
            )
            
            await MainActor.run {
                aiEstimation = response
                showAIResults = true
                
                // Pre-fill with midpoint values
                calories = "\(response.total.calories.midpoint)"
                
                // Reset adjustment factor
                adjustmentFactor = 1.0
                isEstimating = false
            }
        } catch {
            await MainActor.run {
                aiError = error.localizedDescription
                isEstimating = false
            }
        }
    }
    
    private func logAIEstimatedMeal() {
        guard let estimation = aiEstimation else { return }
        
        // Encode AI metadata to JSON
        let encoder = JSONEncoder()
        let metadataJSON = try? encoder.encode(estimation)
        let metadataString = metadataJSON.flatMap { String(data: $0, encoding: .utf8) }
        
        viewModel.addMeal(
            name: mealName,
            calories: adjustedCalories,
            mealType: selectedMealType,
            aiEstimated: true,
            aiMetadataJSON: metadataString,
            aiCaloriesLow: estimation.total.calories.low,
            aiCaloriesHigh: estimation.total.calories.high,
            aiConfidence: estimation.confidence,
            aiAdjustmentFactor: adjustmentFactor
        )
        
        resetForm()
        isPresented = false
    }
    
    private func addMeal() {
        guard let caloriesInt = Int(calories) else { return }
        
        viewModel.addMeal(
            name: mealName,
            calories: caloriesInt,
            mealType: selectedMealType
        )
        
        // Reset form
        resetForm()
        isPresented = false
    }
    
    private func updateMeal() {
        guard let meal = mealToEdit,
              let caloriesInt = Int(calories) else { return }
        
        // If we have AI estimation, use it; otherwise use manual values
        if let estimation = aiEstimation {
            // Encode AI metadata to JSON
            let encoder = JSONEncoder()
            let metadataJSON = try? encoder.encode(estimation)
            let metadataString = metadataJSON.flatMap { String(data: $0, encoding: .utf8) }
            
            viewModel.updateMeal(
                meal: meal,
                name: mealName,
                calories: adjustedCalories,
                mealType: selectedMealType,
                aiEstimated: true,
                aiMetadataJSON: metadataString,
                aiCaloriesLow: estimation.total.calories.low,
                aiCaloriesHigh: estimation.total.calories.high,
                aiConfidence: estimation.confidence,
                aiAdjustmentFactor: adjustmentFactor
            )
        } else {
            viewModel.updateMeal(
                meal: meal,
                name: mealName,
                calories: caloriesInt,
                mealType: selectedMealType
            )
        }
        
        // Reset form
        resetForm()
        isPresented = false
    }
    
    private func resetForm() {
        mealName = ""
        calories = ""
        selectedMealType = "Breakfast"
        aiEstimation = nil
        showAIResults = false
        adjustmentFactor = 1.0
        aiError = nil
        isEstimating = false
    }
}

struct MacronutrientBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.8))
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

#Preview {
    LogFoodView(selectedDate: .constant(Date()))
}
