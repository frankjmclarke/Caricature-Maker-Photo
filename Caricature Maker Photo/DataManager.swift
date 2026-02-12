//
//  DataManager.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import Foundation
import SwiftData

@MainActor
class DataManager: ObservableObject {
    private var modelContext: ModelContext
    
    // Centralized save helper so we never silently ignore persistence errors
    @discardableResult
    private func saveContext(file: StaticString = #fileID, line: UInt = #line) -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            #if DEBUG
            print("❌ DataManager.saveContext failed at \(file):\(line) – \(error)")
            #endif
            return false
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        initializeDefaultSettings()
    }
    
    // MARK: - User Settings
    
    func getUserSettings() -> UserSettings? {
        let descriptor = FetchDescriptor<UserSettings>()
        return try? modelContext.fetch(descriptor).first
    }
    
    func initializeDefaultSettings() {
        if let settings = getUserSettings() {
            // Ensure new fields have default values if they're nil (migration fix)
            if settings.sex == nil {
                settings.sex = "Male"
            }
            if settings.age == nil {
                settings.age = 32
            }
            if settings.height == nil {
                settings.height = 178.0
            }
            _ = saveContext()
        } else {
            let settings = UserSettings()
            modelContext.insert(settings)
            _ = saveContext()
        }
    }
    
    func updateSettings(
        targetDeficit: Int? = nil,
        totalCalories: Int? = nil,
        startingWeight: Double? = nil,
        targetWeight: Double? = nil,
        activityLevel: String? = nil,
        deficitRate: String? = nil,
        weeklyRestDayEnabled: Bool? = nil,
        sex: String? = nil,
        age: Int? = nil,
        height: Double? = nil
    ) {
        guard let settings = getUserSettings() else { return }
        
        if let targetDeficit = targetDeficit {
            settings.targetDeficit = targetDeficit
        }
        if let totalCalories = totalCalories {
            settings.totalCalories = totalCalories
        }
        if let startingWeight = startingWeight {
            settings.startingWeight = startingWeight
        }
        if let targetWeight = targetWeight {
            settings.targetWeight = targetWeight
        }
        if let activityLevel = activityLevel {
            settings.activityLevel = activityLevel
        }
        if let deficitRate = deficitRate {
            settings.deficitRate = deficitRate
            // Update target deficit based on deficit rate
            let deficitAmount: Int
            switch DeficitRate.normalize(deficitRate) {
            case "Gentle": deficitAmount = 300
            case "Steady": deficitAmount = 500
            case "Fast": deficitAmount = 750
            default: deficitAmount = 500
            }
            settings.targetDeficit = deficitAmount
        }
        if let weeklyRestDayEnabled = weeklyRestDayEnabled {
            settings.weeklyRestDayEnabled = weeklyRestDayEnabled
        }
        if let sex = sex {
            settings.sex = sex
        }
        if let age = age {
            settings.age = age
        }
        if let height = height {
            settings.height = height
        }
        
        // Ensure new fields have default values if they're nil (migration fix)
        if settings.sex == nil {
            settings.sex = "Male"
        }
        if settings.age == nil {
            settings.age = 32
        }
        if settings.height == nil {
            settings.height = 178.0
        }
        
        // Recalculate totalCalories if BMR inputs changed
        if sex != nil || age != nil || height != nil || startingWeight != nil || activityLevel != nil {
            let calculatedCalories = calculateTDEE(
                sex: settings.sex ?? "Male",
                age: settings.age ?? 32,
                height: settings.height ?? 178.0,
                weight: settings.startingWeight,
                activityLevel: settings.activityLevel
            )
            settings.totalCalories = calculatedCalories
            
            // Update target deficit based on deficit rate
            let deficitAmount: Int
            switch DeficitRate.normalize(settings.deficitRate) {
            case "Gentle": deficitAmount = 300
            case "Steady": deficitAmount = 500
            case "Fast": deficitAmount = 750
            default: deficitAmount = 500
            }
            settings.targetDeficit = deficitAmount
        }
        
        _ = saveContext()
        
        // Notify that settings have changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
    }
    
    // Calculate TDEE (Total Daily Energy Expenditure) using Mifflin-St Jeor equation
    func calculateTDEE(sex: String, age: Int, height: Double, weight: Double, activityLevel: String) -> Int {
        // Calculate BMR using Mifflin-St Jeor equation
        // BMR (men) = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
        // BMR (women) = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
        
        let isMale = sex.lowercased() == "male"
        let bmr: Double
        if isMale {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        
        // Apply activity multiplier
        let activity = ActivityLevel.allCases.first { $0.rawValue == activityLevel } ?? .regularMovement
        let tdee = bmr * activity.multiplier
        
        return Int(round(tdee))
    }
    
    // MARK: - Daily Entries
    
    func getTodayEntry() -> DailyEntry? {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func getOrCreateTodayEntry() -> DailyEntry {
        return getOrCreateEntry(for: Date())
    }
    
    func getEntry(for date: Date) -> DailyEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func getOrCreateEntry(for date: Date) -> DailyEntry {
        if let entry = getEntry(for: date) {
            return entry
        }
        
        let settings = getUserSettings()
        let totalCalories = settings?.totalCalories ?? 1900
        
        let entry = DailyEntry(
            date: date,
            caloriesConsumed: 0,
            deficitAchieved: totalCalories
        )
        modelContext.insert(entry)
        _ = saveContext()
        return entry
    }
    
    func getDailyEntries(limit: Int? = nil) -> [DailyEntry] {
        var descriptor = FetchDescriptor<DailyEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getDailyEntries(for week: Date) -> [DailyEntry] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week) else {
            return []
        }
        let startOfWeek = weekInterval.start
        let endOfWeek = weekInterval.end
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= startOfWeek && entry.date < endOfWeek
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func updateDailyEntry(_ entry: DailyEntry) {
        let settings = getUserSettings()
        let totalCalories = settings?.totalCalories ?? 1900
        
        entry.deficitAchieved = totalCalories - entry.caloriesConsumed
        entry.metDeficitTarget = entry.deficitAchieved >= (settings?.targetDeficit ?? 500)
        
        _ = saveContext()
    }
    
    // MARK: - Meals
    
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
        aiAdjustmentFactor: Double? = nil,
        date: Date? = nil
    ) {
        let targetDate = date ?? Date()
        let entry = getOrCreateEntry(for: targetDate)
        
        let meal = Meal(
            name: name,
            timestamp: Date(),
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
        
        meal.dailyEntry = entry
        if entry.meals == nil {
            entry.meals = []
        }
        entry.meals?.append(meal)
        
        // Recalculate consumed calories from actual meals to ensure accuracy
        recalculateConsumedCalories(for: entry)
        updateDailyEntry(entry)
        
        // Ensure the context is saved
        _ = saveContext()
        
        // Notify that meals have changed
        NotificationCenter.default.post(name: NSNotification.Name("MealsChanged"), object: nil)
    }
    
    func getTodayMeals() -> [Meal] {
        return getMeals(for: Date())
    }
    
    func getMeals(for date: Date) -> [Meal] {
        guard let entry = getEntry(for: date) else { return [] }
        return entry.meals?.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
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
        guard let entry = meal.dailyEntry else { return }
        
        // Update meal properties
        meal.name = name
        meal.calories = calories
        meal.protein = protein
        meal.carbs = carbs
        meal.fat = fat
        meal.mealType = mealType
        
        // Update AI metadata if provided
        if let aiEstimated = aiEstimated {
            meal.aiEstimated = aiEstimated
        }
        if let aiMetadataJSON = aiMetadataJSON {
            meal.aiMetadataJSON = aiMetadataJSON
        }
        if let aiCaloriesLow = aiCaloriesLow {
            meal.aiCaloriesLow = aiCaloriesLow
        }
        if let aiCaloriesHigh = aiCaloriesHigh {
            meal.aiCaloriesHigh = aiCaloriesHigh
        }
        if let aiConfidence = aiConfidence {
            meal.aiConfidence = aiConfidence
        }
        if let aiAdjustmentFactor = aiAdjustmentFactor {
            meal.aiAdjustmentFactor = aiAdjustmentFactor
        }
        
        // Recalculate consumed calories from actual meals to ensure accuracy
        recalculateConsumedCalories(for: entry)
        updateDailyEntry(entry)
        
        _ = saveContext()
        
        // Notify that meals have changed
        NotificationCenter.default.post(name: NSNotification.Name("MealsChanged"), object: nil)
    }
    
    func deleteMeal(_ meal: Meal) {
        if let entry = meal.dailyEntry {
            entry.meals?.removeAll(where: { $0.id == meal.id })
            // Recalculate consumed calories from actual meals to ensure accuracy
            recalculateConsumedCalories(for: entry)
            updateDailyEntry(entry)
        }
        modelContext.delete(meal)
        _ = saveContext()
        
        // Notify that meals have changed
        NotificationCenter.default.post(name: NSNotification.Name("MealsChanged"), object: nil)
    }
    
    // Recalculate consumed calories from actual meals to ensure accuracy
    private func recalculateConsumedCalories(for entry: DailyEntry) {
        let actualTotal = entry.meals?.reduce(0) { $0 + $1.calories } ?? 0
        entry.caloriesConsumed = actualTotal
    }
    
    // MARK: - Weight Entries
    
    func addWeightEntry(weight: Double, date: Date = Date(), notes: String? = nil) {
        let entry = WeightEntry(date: date, weight: weight, notes: notes)
        modelContext.insert(entry)
        _ = saveContext()
    }
    
    func getWeightEntries(limit: Int? = nil) -> [WeightEntry] {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getLatestWeight() -> Double? {
        return getWeightEntries(limit: 1).first?.weight
    }
    
    // MARK: - Statistics
    
    func getDaysTracked() -> Int {
        let descriptor = FetchDescriptor<DailyEntry>()
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    func getDaysHitDeficitTarget() -> Int {
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.metDeficitTarget == true }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    func getDaysHitDeficitTargetForCurrentWeek() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekEntries = getDailyEntries(for: today)
        
        // Get settings to check if rest day is enabled
        guard let settings = getUserSettings() else {
            // No settings, just count normally
            return weekEntries.filter { $0.metDeficitTarget }.count
        }
        
        let targetDeficit = settings.targetDeficit
        
        // If rest day is not enabled, just count normally
        guard settings.weeklyRestDayEnabled else {
            return weekEntries.filter { $0.metDeficitTarget }.count
        }
        
        // Find the worst non-green day (same logic as getWeeklyDeficitsWithRestDayAdjustment)
        var worstDayEntry: DailyEntry?
        var worstDeficit = Int.max
        
        for entry in weekEntries {
            // Check if this day is not in green (deficit < targetDeficit)
            if entry.deficitAchieved < targetDeficit {
                // This is a non-green day, check if it's the worst
                if entry.deficitAchieved < worstDeficit {
                    worstDeficit = entry.deficitAchieved
                    worstDayEntry = entry
                }
            }
        }
        
        // Count days that met target OR are the rest day
        var count = 0
        for entry in weekEntries {
            if entry.metDeficitTarget {
                count += 1
            } else if let worstDay = worstDayEntry, calendar.isDate(entry.date, inSameDayAs: worstDay.date) {
                // This is the rest day (worst non-green day), count it as meeting target
                count += 1
            }
        }
        
        return count
    }
    
    func getCurrentStreak() -> Int {
        let entries = getDailyEntries()
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in entries {
            let entryDate = calendar.startOfDay(for: entry.date)
            if entryDate == currentDate && entry.metDeficitTarget {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if entryDate == currentDate {
                break
            } else if entryDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    func getWeeklyDeficits() -> [DailyDeficitData] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var deficits: [DailyDeficitData] = []
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let entry = getDailyEntry(for: date)
            // Only include days that have data (entry exists)
            guard let entry = entry else { continue }
            let deficit = entry.deficitAchieved
            let weekday = calendar.component(.weekday, from: date)
            let dayName = dayNames[weekday - 1]
            
            deficits.append(DailyDeficitData(day: dayName, dayIndex: weekday - 1, deficit: Double(deficit)))
        }
        
        return deficits
    }
    
    func getWeeklyDeficitsWithRestDayAdjustment() -> [DailyDeficitData] {
        let deficits = getWeeklyDeficits()
        
        // Get settings to check if rest day is enabled
        guard let settings = getUserSettings(), settings.weeklyRestDayEnabled else {
            // Rest day not enabled, return original deficits
            return deficits
        }
        
        let targetDeficit = Double(settings.targetDeficit)
        
        // Filter to days not in green area (deficit < targetDeficit)
        let nonGreenDays = deficits.filter { $0.deficit < targetDeficit }
        
        // If no non-green days, return original deficits
        guard !nonGreenDays.isEmpty else {
            return deficits
        }
        
        // Find the worst day (minimum deficit value)
        guard let worstDay = nonGreenDays.min(by: { $0.deficit < $1.deficit }) else {
            return deficits
        }
        
        // Create adjusted array with worst day's deficit set to 0
        return deficits.map { dayData in
            if dayData.dayIndex == worstDay.dayIndex {
                // Return new instance with deficit set to 0
                return DailyDeficitData(day: dayData.day, dayIndex: dayData.dayIndex, deficit: 0.0)
            } else {
                return dayData
            }
        }
    }
    
    func getDailyEntry(for date: Date) -> DailyEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    func initializeDebugMealsIfNeeded() {
        // Check if we should skip debug meal creation (first run after account deletion)
        let shouldSkip = UserDefaults.standard.bool(forKey: "skipDebugMealsOnNextRun")
        if shouldSkip {
            // Clear the flag so next run will create data if needed
            UserDefaults.standard.set(false, forKey: "skipDebugMealsOnNextRun")
            UserDefaults.standard.synchronize()
            #if DEBUG
            debugPrint("DEBUG: Skipping debug meal creation (first run after account deletion)")
            #endif
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Get current week's entries
        let weekEntries = getDailyEntries(for: today)
        
        // Check if any meals exist in the current week
        let hasMeals = weekEntries.contains { entry in
            !(entry.meals?.isEmpty ?? true)
        }
        
        // If meals already exist, do nothing
        guard !hasMeals else {
            return
        }
        
        // Get week boundaries
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return
        }
        let startOfWeek = weekInterval.start
        
        // Add meals for each day in the current week
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else {
                continue
            }
            
            // Get or create entry for this day
            let entry = getOrCreateEntry(for: date)
            
            // Create timestamps for each meal
            let breakfastTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
            let lunchTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let dinnerTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
            
            // Create breakfast meal
            let breakfast = Meal(
                name: "Debug Breakfast",
                timestamp: breakfastTime,
                calories: 700,
                protein: 25,
                carbs: 50,
                fat: 50,
                mealType: "Breakfast"
            )
            breakfast.dailyEntry = entry
            if entry.meals == nil {
                entry.meals = []
            }
            entry.meals?.append(breakfast)
            modelContext.insert(breakfast)
            
            // Create lunch meal
            let lunch = Meal(
                name: "Debug Lunch",
                timestamp: lunchTime,
                calories: 700,
                protein: 25,
                carbs: 50,
                fat: 50,
                mealType: "Lunch"
            )
            lunch.dailyEntry = entry
            entry.meals?.append(lunch)
            modelContext.insert(lunch)
            
            // Create dinner meal
            let dinner = Meal(
                name: "Debug Dinner",
                timestamp: dinnerTime,
                calories: 700,
                protein: 25,
                carbs: 50,
                fat: 50,
                mealType: "Dinner"
            )
            dinner.dailyEntry = entry
            entry.meals?.append(dinner)
            modelContext.insert(dinner)
            
            // Recalculate consumed calories and update entry
            recalculateConsumedCalories(for: entry)
            updateDailyEntry(entry)
        }
        
        // Save context once after all meals are added
        _ = saveContext()
        
        // Notify that meals have changed
        NotificationCenter.default.post(name: NSNotification.Name("MealsChanged"), object: nil)
    }
    #endif
    
    // MARK: - Account Deletion
    
    /// Delete all user data and reset app to initial state
    /// This does NOT affect StoreKit subscriptions (managed by Apple)
    func deleteAllUserData() {
        #if DEBUG
        TraceLogger.trace("DataManager", "deleteAllUserData: Starting account deletion")
        #endif
        
        // CRITICAL: Delete all Meal records first with explicit save
        // This ensures all food data is removed before deleting DailyEntry records
        do {
            let mealsDescriptor = FetchDescriptor<Meal>()
            let meals = try modelContext.fetch(mealsDescriptor)
            let mealCount = meals.count
            
            for meal in meals {
                // Remove from relationship first to avoid cascade issues
                if let entry = meal.dailyEntry {
                    entry.meals?.removeAll(where: { $0.id == meal.id })
                }
                modelContext.delete(meal)
            }
            
            // Save immediately after deleting meals
            let saved = saveContext()
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: Deleted \(mealCount) Meal records, save result: \(saved)")
            #endif
            
            // Verify deletion by checking count
            let remainingMeals = try? modelContext.fetch(mealsDescriptor)
            if let remaining = remainingMeals, !remaining.isEmpty {
                #if DEBUG
                TraceLogger.trace("DataManager", "deleteAllUserData: WARNING - \(remaining.count) meals still remain after deletion")
                #endif
                // Force delete remaining meals
                for meal in remaining {
                    modelContext.delete(meal)
                }
                _ = saveContext()
            }
        } catch {
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: ERROR deleting meals - \(error)")
            #endif
        }
        
        // Delete all DailyEntry records
        do {
            let dailyEntriesDescriptor = FetchDescriptor<DailyEntry>()
            let dailyEntries = try modelContext.fetch(dailyEntriesDescriptor)
            let entryCount = dailyEntries.count
            
            for entry in dailyEntries {
                // Clear meals relationship before deletion
                entry.meals = nil
                modelContext.delete(entry)
            }
            
            // Save after deleting daily entries
            _ = saveContext()
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: Deleted \(entryCount) DailyEntry records")
            #endif
        } catch {
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: ERROR deleting daily entries - \(error)")
            #endif
        }
        
        // Delete all WeightEntry records
        do {
            let weightEntriesDescriptor = FetchDescriptor<WeightEntry>()
            let weightEntries = try modelContext.fetch(weightEntriesDescriptor)
            let weightCount = weightEntries.count
            
            for entry in weightEntries {
                modelContext.delete(entry)
            }
            
            _ = saveContext()
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: Deleted \(weightCount) WeightEntry records")
            #endif
        } catch {
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: ERROR deleting weight entries - \(error)")
            #endif
        }
        
        // Delete UserSettings record
        if let settings = getUserSettings() {
            modelContext.delete(settings)
            _ = saveContext()
            #if DEBUG
            TraceLogger.trace("DataManager", "deleteAllUserData: Deleted UserSettings record")
            #endif
        }
        
        // Final save to ensure all deletions are persisted
        let finalSave = saveContext()
        #if DEBUG
        TraceLogger.trace("DataManager", "deleteAllUserData: Final save result: \(finalSave)")
        
        // Final verification - check if any meals remain
        let finalMealsCheck = try? modelContext.fetch(FetchDescriptor<Meal>())
        if let remaining = finalMealsCheck, !remaining.isEmpty {
            TraceLogger.trace("DataManager", "deleteAllUserData: CRITICAL - \(remaining.count) meals still exist after all deletions!")
        } else {
            TraceLogger.trace("DataManager", "deleteAllUserData: Verification passed - all meals deleted")
        }
        #endif
        
        // Reset UserDefaults
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        #if DEBUG
        // Set flag to skip debug meal creation on next app run (allows verification of deletion)
        UserDefaults.standard.set(true, forKey: "skipDebugMealsOnNextRun")
        TraceLogger.trace("DataManager", "deleteAllUserData: Reset hasCompletedOnboarding to false, set skipDebugMealsOnNextRun to true")
        #endif
        
        UserDefaults.standard.synchronize()
        
        // Post notification to trigger app reset
        NotificationCenter.default.post(name: NSNotification.Name("AccountDeleted"), object: nil)
        
        #if DEBUG
        TraceLogger.trace("DataManager", "deleteAllUserData: Account deletion completed")
        #endif
    }
}

// Helper struct for deficit analysis
struct DailyDeficitData: Identifiable {
    let id = UUID()
    let day: String
    let dayIndex: Int
    let deficit: Double
}
