//
//  Models.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import Foundation
import SwiftData

// MARK: - Deficit Rate
enum DeficitRate: String, CaseIterable {
    case gentle = "Gentle"
    case steady = "Steady"
    case fast = "Fast"
    
    // Map old values to new ones for backward compatibility
    static func normalize(_ value: String) -> String {
        switch value {
        case "Conservative": return "Gentle"
        case "Moderate": return "Steady"
        case "Aggressive": return "Fast"
        default: return value
        }
    }
}

// MARK: - Activity Level
enum ActivityLevel: String, CaseIterable {
    case mostlySeated = "Mostly seated"
    case lightMovement = "Light movement"
    case regularMovement = "Regular movement"
    case veryActive = "Very active"
    
    var multiplier: Double {
        switch self {
        case .mostlySeated: return 1.2
        case .lightMovement: return 1.375
        case .regularMovement: return 1.55
        case .veryActive: return 1.725
        }
    }
}

// MARK: - User Settings
@Model
final class UserSettings {
    var targetDeficit: Int // calories per day
    var totalCalories: Int // daily calorie goal
    var startingWeight: Double // kg
    var targetWeight: Double // kg
    var activityLevel: String // e.g., "Regular movement"
    var deficitRate: String // "Gentle", "Steady", "Fast" (or legacy: "Conservative", "Moderate", "Aggressive")
    var weeklyRestDayEnabled: Bool
    var restDayCalories: Int // maintenance calories on rest day
    
    // New fields for BMR calculation (optional for migration compatibility)
    var sex: String? // "Male" or "Female"
    var age: Int? // years
    var height: Double? // cm
    
    init(
        targetDeficit: Int = 500,
        totalCalories: Int = 1900,
        startingWeight: Double = 82.5,
        targetWeight: Double = 75.0,
        activityLevel: String = "Regular movement",
        deficitRate: String = "Steady",
        weeklyRestDayEnabled: Bool = true,
        restDayCalories: Int = 2400,
        sex: String? = "Male",
        age: Int? = 32,
        height: Double? = 178.0
    ) {
        self.targetDeficit = targetDeficit
        self.totalCalories = totalCalories
        self.startingWeight = startingWeight
        self.targetWeight = targetWeight
        self.activityLevel = activityLevel
        self.deficitRate = deficitRate
        self.weeklyRestDayEnabled = weeklyRestDayEnabled
        self.restDayCalories = restDayCalories
        self.sex = sex
        self.age = age
        self.height = height
    }
}

// MARK: - Daily Entry
@Model
final class DailyEntry {
    var date: Date
    var caloriesConsumed: Int
    var caloriesBurned: Int // optional, for future use
    var deficitAchieved: Int // calculated: totalCalories - caloriesConsumed
    var weight: Double? // optional daily weight
    var metDeficitTarget: Bool // whether deficit target was met
    
    @Relationship(deleteRule: .cascade) var meals: [Meal]?
    
    init(
        date: Date = Date(),
        caloriesConsumed: Int = 0,
        caloriesBurned: Int = 0,
        deficitAchieved: Int = 0,
        weight: Double? = nil,
        metDeficitTarget: Bool = false
    ) {
        self.date = date
        self.caloriesConsumed = caloriesConsumed
        self.caloriesBurned = caloriesBurned
        self.deficitAchieved = deficitAchieved
        self.weight = weight
        self.metDeficitTarget = metDeficitTarget
        self.meals = []
    }
    
    // Helper to check if entry is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Helper to get date without time
    var dateOnly: Date {
        Calendar.current.startOfDay(for: date)
    }
}

// MARK: - Meal
@Model
final class Meal {
    var name: String
    var timestamp: Date
    var calories: Int
    var protein: Int // grams
    var carbs: Int // grams
    var fat: Int // grams
    var mealType: String // "Breakfast", "Lunch", "Dinner", "Snack"
    
    // AI estimation metadata (optional to allow migration)
    var aiEstimated: Bool?
    var aiMetadataJSON: String? // Full AI response as JSON string
    var aiCaloriesLow: Int?
    var aiCaloriesHigh: Int?
    var aiConfidence: String?
    var aiAdjustmentFactor: Double?
    
    @Relationship(inverse: \DailyEntry.meals) var dailyEntry: DailyEntry?
    
    init(
        name: String,
        timestamp: Date = Date(),
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
        self.name = name
        self.timestamp = timestamp
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.mealType = mealType
        self.aiEstimated = aiEstimated
        self.aiMetadataJSON = aiMetadataJSON
        self.aiCaloriesLow = aiCaloriesLow
        self.aiCaloriesHigh = aiCaloriesHigh
        self.aiConfidence = aiConfidence
        self.aiAdjustmentFactor = aiAdjustmentFactor
    }
    
    // Helper to format time
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Helper to get meal type display name
    var mealTypeDisplay: String {
        switch mealType.lowercased() {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        case "snack": return "Snack"
        default: return mealType
        }
    }
}

// MARK: - Weight Entry
@Model
final class WeightEntry {
    var date: Date
    var weight: Double // kg
    var notes: String?
    
    init(
        date: Date = Date(),
        weight: Double,
        notes: String? = nil
    ) {
        self.date = date
        self.weight = weight
        self.notes = notes
    }
    
    // Helper to get date without time
    var dateOnly: Date {
        Calendar.current.startOfDay(for: date)
    }
}

// MARK: - Helper Extensions
extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
    
    func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
