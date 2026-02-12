//
//  ViewModels.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Today's Progress ViewModel
@MainActor
class TodayViewModel: ObservableObject {
    @Published var remainingCalories: Int = 0
    @Published var consumedCalories: Int = 0
    @Published var totalCalories: Int = 1900
    @Published var completionPercentage: Int = 0
    @Published var targetDeficit: Int = 500
    @Published var selectedDate: Date = Date()
    
    var dataManager: DataManager?
    
    // Computed properties for status-first display
    var isOverTarget: Bool {
        remainingCalories < 0
    }
    
    var statusText: String {
        if isOverTarget {
            // Show current deficit when over target (will be negative)
            return "If you finish like this today: \(currentDeficit) cal deficit"
        } else {
            // Calculate current deficit achieved
            let currentDeficit = totalCalories - consumedCalories
            
            // Compare to target deficit
            let difference = currentDeficit - targetDeficit
            
            if abs(difference) <= 50 {
                // Within 50 cal of target is "on track"
                return "On track"
            } else if difference > 0 {
                // Ahead of target
                return "Ahead by \(difference) cal"
            } else {
                // Behind target
                return "Behind by \(abs(difference)) cal"
            }
        }
    }
    
    var currentDeficit: Int {
        // Deficit if the day ended now (not a time-based projection)
        // This is the deficit based on current consumption (totalCalories - consumedCalories)
        // Can be negative when over target
        return totalCalories - consumedCalories
    }
    
    var ringColor: Color {
        if isOverTarget {
            return Color(red: 1.0, green: 0.4, blue: 0.4) // Red for over
        } else {
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Green for on track
        }
    }
    
    init() { }
    
    func updateData() {
        guard let dataManager = dataManager else { return }
        
        let settings = dataManager.getUserSettings()
        let entry = dataManager.getOrCreateEntry(for: selectedDate)
        
        // Defensive default if settings not available (e.g., pre-onboarding)
        totalCalories = settings?.totalCalories ?? 1900
        // Defensive default if settings not available (e.g., pre-onboarding)
        targetDeficit = settings?.targetDeficit ?? 500
        consumedCalories = entry.caloriesConsumed
        remainingCalories = totalCalories - (consumedCalories + targetDeficit)
        
        if totalCalories > 0 {
            let percentage = (Double(consumedCalories) / Double(totalCalories)) * 100
            completionPercentage = min(100, max(0, Int(percentage)))
        } else {
            completionPercentage = 0
        }
    }
    
    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        #if DEBUG
        print("📅 [TodayViewModel] goToPreviousDay - new date: \(selectedDate)")
        #endif
        updateData()
    }
    
    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        #if DEBUG
        print("📅 [TodayViewModel] goToNextDay - new date: \(selectedDate)")
        #endif
        updateData()
    }
}

// MARK: - Log Food ViewModel
@MainActor
class LogFoodViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var todayMeals: [Meal] = []
    @Published var selectedDate: Date = Date() {
        didSet {
            #if DEBUG
            print("📅 [LogFoodViewModel] selectedDate changed to: \(selectedDate)")
            #endif
            loadMeals()
        }
    }
    
    var dataManager: DataManager?
    
    init() { }
    
    func loadMeals() {
        guard let dataManager = dataManager else { return }
        todayMeals = dataManager.getMeals(for: selectedDate)
    }
    
    func addMeal(
        name: String,
        calories: Int,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0,
        mealType: String = "Meal",
        aiEstimated: Bool? = nil,
        aiMetadataJSON: String? = nil,
        aiCaloriesLow: Int? = nil,
        aiCaloriesHigh: Int? = nil,
        aiConfidence: String? = nil,
        aiAdjustmentFactor: Double? = nil
    ) {
        guard let dataManager = dataManager else { return }
        dataManager.addMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: mealType,
            aiEstimated: aiEstimated,
            aiMetadataJSON: aiMetadataJSON,
            aiCaloriesLow: aiCaloriesLow,
            aiCaloriesHigh: aiCaloriesHigh,
            aiConfidence: aiConfidence,
            aiAdjustmentFactor: aiAdjustmentFactor,
            date: selectedDate
        )
        loadMeals()
    }
    
    func updateMeal(
        meal: Meal,
        name: String,
        calories: Int,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0,
        mealType: String = "Meal",
        aiEstimated: Bool? = nil,
        aiMetadataJSON: String? = nil,
        aiCaloriesLow: Int? = nil,
        aiCaloriesHigh: Int? = nil,
        aiConfidence: String? = nil,
        aiAdjustmentFactor: Double? = nil
    ) {
        guard let dataManager = dataManager else { return }
        dataManager.updateMeal(
            meal: meal,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: mealType,
            aiEstimated: aiEstimated,
            aiMetadataJSON: aiMetadataJSON,
            aiCaloriesLow: aiCaloriesLow,
            aiCaloriesHigh: aiCaloriesHigh,
            aiConfidence: aiConfidence,
            aiAdjustmentFactor: aiAdjustmentFactor
        )
        loadMeals()
    }
    
    func deleteMeal(_ meal: Meal) {
        guard let dataManager = dataManager else { return }
        dataManager.deleteMeal(meal)
        loadMeals()
    }
}

// MARK: - Weight Data Point
struct WeightDataPoint: Identifiable {
    let id = UUID()
    let week: String
    let weekNumber: Int
    let weight: Double
}

// MARK: - Progress ViewModel
@MainActor
class ProgressViewModel: ObservableObject {
    @Published var currentWeight: Double = 0
    @Published var startingWeight: Double = 82.5
    @Published var lostWeight: Double = 0
    @Published var remainingWeight: Double = 0
    @Published var weeksTracking: Int = 0
    @Published var weeklyTrend: Double = 0
    @Published var weightData: [WeightDataPoint] = []
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        updateData()
    }
    
    func updateData() {
        let settings = dataManager.getUserSettings()
        startingWeight = settings?.startingWeight ?? 82.5
        let targetWeight = settings?.targetWeight ?? 75.0
        
        // Get latest weight or use starting weight
        if let latestWeight = dataManager.getLatestWeight() {
            currentWeight = latestWeight
        } else {
            currentWeight = startingWeight
        }
        
        lostWeight = startingWeight - currentWeight
        remainingWeight = max(0, currentWeight - targetWeight)
        
        // Calculate weeks tracking from first entry
        let allEntries = dataManager.getDailyEntries()
        if let firstEntry = allEntries.last {
            let days = Calendar.current.dateComponents([.day], from: firstEntry.date, to: Date()).day ?? 0
            weeksTracking = max(1, (days / 7))
        } else {
            weeksTracking = 1
        }
        
        // Get weight entries for chart
        let weightEntries = dataManager.getWeightEntries()
        // Explicitly sort by date ascending (oldest to newest) to ensure deterministic labeling
        // Oldest entry = W1, newest entry = Wk. This order must be maintained to avoid regressions.
        let sorted = weightEntries.sorted(by: { $0.date < $1.date })
        weightData = sorted.enumerated().map { index, entry in
            let weekNumber = index + 1 // Sequential: 1, 2, 3, ... (oldest = W1)
            let weekLabel = "W\(weekNumber)"
            return WeightDataPoint(week: weekLabel, weekNumber: weekNumber, weight: entry.weight)
        }
        
        // Calculate weekly trend (average slope between first and last points)
        calculateWeeklyTrend()
    }
    
    private func calculateWeeklyTrend() {
        guard weightData.count >= 2 else {
            weeklyTrend = 0
            return
        }
        
        // Calculate average slope between first and last points (not a linear regression)
        let sortedData = weightData.sorted { $0.weekNumber < $1.weekNumber }
        let firstWeight = sortedData.first?.weight ?? currentWeight
        let lastWeight = sortedData.last?.weight ?? currentWeight
        let weeks = max(1, sortedData.count)
        
        let trend = (lastWeight - firstWeight) / Double(weeks)
        weeklyTrend = trend.isNaN || trend.isInfinite ? 0 : trend
    }
}

// MARK: - Goal Settings ViewModel
@MainActor
class GoalSettingsViewModel: ObservableObject {
    @Published var targetDeficit: Int = 500
    @Published var totalCalories: Int = 1900
    @Published var deficitRate: String = "Steady"
    @Published var weeklyRestDayEnabled: Bool = true
    @Published var sex: String = "Male" {
        didSet { recalculateEstimatedCalories() }
    }
    @Published var age: Int = 32 {
        didSet { recalculateEstimatedCalories() }
    }
    @Published var height: Double = 178.0 {
        didSet { recalculateEstimatedCalories() }
    }
    @Published var startingWeight: Double = 82.5 {
        didSet { recalculateEstimatedCalories() }
    }
    @Published var activityLevel: String = "Regular movement" {
        didSet { recalculateEstimatedCalories() }
    }
    
    @Published var estimatedCalories: Int = 1900
    
    private func recalculateEstimatedCalories() {
        estimatedCalories = dataManager.calculateTDEE(
            sex: sex,
            age: age,
            height: height,
            weight: startingWeight,
            activityLevel: activityLevel
        )
    }
    
    var dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadSettings()
    }
    
    func loadSettings() {
        if let settings = dataManager.getUserSettings() {
            targetDeficit = settings.targetDeficit
            totalCalories = settings.totalCalories
            startingWeight = settings.startingWeight
            
            // Normalize activity level from old values
            let normalizedActivity = normalizeActivityLevel(settings.activityLevel)
            activityLevel = normalizedActivity
            
            // Normalize old deficit rate values to new ones
            let normalizedRate = DeficitRate.normalize(settings.deficitRate)
            deficitRate = normalizedRate
            
            sex = settings.sex ?? "Male"
            age = settings.age ?? 32
            height = settings.height ?? 178.0
            
            // Update stored values if they were changed
            if normalizedActivity != settings.activityLevel || normalizedRate != settings.deficitRate {
                saveSettings()
            }
            weeklyRestDayEnabled = settings.weeklyRestDayEnabled
            
            // Recalculate estimated calories after loading settings
            recalculateEstimatedCalories()
        }
    }
    
    private func normalizeActivityLevel(_ level: String) -> String {
        // Map old activity level values to new ones
        switch level {
        case "Sedentary", "Mostly seated": return "Mostly seated"
        case "Lightly active", "Light movement": return "Light movement"
        case "Moderately active", "Regular movement": return "Regular movement"
        case "Very active", "Extremely active": return "Very active"
        default:
            // If it's already a new value, return it
            if ActivityLevel.allCases.contains(where: { $0.rawValue == level }) {
                return level
            }
            // Default to Regular movement
            return "Regular movement"
        }
    }
    
    func saveSettings() {
        // Recalculate estimated calories before saving to ensure it's up to date
        recalculateEstimatedCalories()
        
        dataManager.updateSettings(
            targetDeficit: targetDeficit,
            // TDEE is derived from BMR inputs and activity level, then persisted as totalCalories
            totalCalories: estimatedCalories,
            startingWeight: startingWeight,
            targetWeight: nil, // No longer managed in UI
            activityLevel: activityLevel,
            deficitRate: deficitRate,
            weeklyRestDayEnabled: weeklyRestDayEnabled,
            sex: sex,
            age: age,
            height: height
        )
        // Refresh values from settings after save
        if let settings = dataManager.getUserSettings() {
            totalCalories = settings.totalCalories
            targetDeficit = settings.targetDeficit
        }
    }
    
    func updateDeficitRate(_ rate: String) {
        deficitRate = rate
        saveSettings()
    }
    
    func updateWeeklyRestDay(_ enabled: Bool) {
        weeklyRestDayEnabled = enabled
        saveSettings()
    }
    
    func updateActivityLevel(_ level: String) {
        activityLevel = level
        saveSettings()
    }
    
    func updateSex(_ newSex: String) {
        sex = newSex
        saveSettings()
    }
    
    func incrementAge() {
        age += 1
        saveSettings()
    }
    
    func decrementAge() {
        age = max(1, age - 1)
        saveSettings()
    }
    
    func updateHeight(_ newHeight: Double) {
        height = newHeight
        saveSettings()
    }
    
    func updateWeight(_ newWeight: Double) {
        startingWeight = newWeight
        saveSettings()
    }
}

// MARK: - Consistency ViewModel
@MainActor
class ConsistencyViewModel: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var daysTracked: Int = 0
    @Published var daysTrackedTarget: Int = 60
    @Published var hitDeficitTarget: Int = 0
    // Number of days in the current week that have entries (not necessarily target hits)
    @Published var daysWithEntriesThisWeek: Int = 0
    @Published var weekProgress: [Bool] = [false, false, false, false, false, false, false]
    @Published var weekRemainingCalories: [Int?] = [nil, nil, nil, nil, nil, nil, nil] // nil = no data, Int = remaining calories
    @Published var restDayIndex: Int? = nil // Index of the rest day in the week (0-6), nil if no rest day
    @Published var weeklyAverageDeficit: Int = 0
    @Published var targetDeficit: Int = 500
    @Published var totalCalories: Int = 1900
    @Published var daysEngaged: Int = 0
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        updateData()
    }
    
    func updateData() {
        currentStreak = dataManager.getCurrentStreak()
        daysTracked = dataManager.getDaysTracked()
        daysEngaged = daysTracked // Engagement streak is number of days engaged
        
        // Get target days met for current week (with rest day adjustment)
        hitDeficitTarget = dataManager.getDaysHitDeficitTargetForCurrentWeek()
        // Total is the number of days in current week that have entries
        let weeklyDeficitsRaw = dataManager.getWeeklyDeficits()
        daysWithEntriesThisWeek = weeklyDeficitsRaw.count
        
        // Get target deficit and total calories from settings
        let settings = dataManager.getUserSettings()
        // Defensive default if settings not available (e.g., pre-onboarding)
        targetDeficit = settings?.targetDeficit ?? 500
        // Defensive default if settings not available (e.g., pre-onboarding)
        totalCalories = settings?.totalCalories ?? 1900
        
        // Calculate weekly average deficit
        let weeklyDeficits = dataManager.getWeeklyDeficitsWithRestDayAdjustment()
        if !weeklyDeficits.isEmpty {
            let total = weeklyDeficits.reduce(0) { $0 + Int($1.deficit) }
            weeklyAverageDeficit = total / weeklyDeficits.count
        } else {
            weeklyAverageDeficit = 0
        }
        
        // Update week progress
        updateWeekProgress()
    }
    
    private func updateWeekProgress() {
        // Use stored properties totalCalories and targetDeficit from view model (updated in updateData())
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        weekProgress = (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                return false
            }
            
            let entry = dataManager.getDailyEntry(for: date)
            return entry != nil // Engagement indicator: has data (not just met target)
        }
        
        weekRemainingCalories = (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                return nil
            }
            
            guard let entry = dataManager.getDailyEntry(for: date) else {
                return nil // No data for this day
            }
            
            // Calculate remaining calories: totalCalories - (consumedCalories + targetDeficit)
            let remaining = self.totalCalories - (entry.caloriesConsumed + self.targetDeficit)
            return remaining
        }
        
        // Determine rest day index if rest day is enabled
        restDayIndex = nil
        if let settings = dataManager.getUserSettings(), settings.weeklyRestDayEnabled {
            // Find the worst non-green day (same logic as getWeeklyDeficitsWithRestDayAdjustment)
            var worstDayIndex: Int?
            var worstDeficit = Int.max
            
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                    continue
                }
                
                guard let entry = dataManager.getDailyEntry(for: date) else {
                    continue
                }
                
                // Check if this day is not in green (deficit < targetDeficit)
                if entry.deficitAchieved < self.targetDeficit {
                    // This is a non-green day, check if it's the worst
                    if entry.deficitAchieved < worstDeficit {
                        worstDeficit = entry.deficitAchieved
                        worstDayIndex = dayOffset
                    }
                }
            }
            
            restDayIndex = worstDayIndex
        }
    }
    
    // Status determination based on weekly average deficit
    // Thresholds are relative to targetDeficit for clarity
    var onTrackStatus: (title: String, color: Color) {
        if weeklyAverageDeficit < 0 {
            return ("Above target range", Color(red: 1.0, green: 0.4, blue: 0.4))
        } else if weeklyAverageDeficit >= targetDeficit {
            return ("You're on track", Color(red: 0.2, green: 0.65, blue: 0.55))
        } else if weeklyAverageDeficit >= Int(Double(targetDeficit) * 0.7) {
            return ("You're mostly on track", Color(red: 1.0, green: 0.6, blue: 0.2))
        } else {
            return ("You're not on track (yet)", Color(red: 0.9, green: 0.5, blue: 0.5))
        }
    }
    
    var engagementStreakText: String {
        if daysEngaged >= 2 {
            return "\(daysEngaged) days · building"
        } else if daysEngaged == 1 {
            return "1 day · building"
        } else {
            return ""
        }
    }
    
    var statusExplanation: String {
        return "Weekly average deficit: ~\(weeklyAverageDeficit) kcal"
    }
}

