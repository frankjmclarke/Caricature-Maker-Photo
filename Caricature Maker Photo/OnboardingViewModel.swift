//
//  OnboardingViewModel.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var sex: String = "Male" {
        didSet { recalculateCalories() }
    }
    @Published var age: Int = 32 {
        didSet { recalculateCalories() }
    }
    @Published var height: Double = 178.0 {
        didSet { recalculateCalories() }
    }
    @Published var weight: Double = 82.5 {
        didSet { recalculateCalories() }
    }
    @Published var activityLevel: String = "Regular movement" {
        didSet { recalculateCalories() }
    }
    @Published var deficitRate: String = "Steady"
    @Published var estimatedCalories: Int = 1900
    
    var dataManager: DataManager?
    
    init() { }
    
    private func recalculateCalories() {
        guard let dataManager = dataManager else { return }
        estimatedCalories = dataManager.calculateTDEE(
            sex: sex,
            age: age,
            height: height,
            weight: weight,
            activityLevel: activityLevel
        )
    }
    
    func incrementAge() {
        age += 1
    }
    
    func decrementAge() {
        age = max(1, age - 1)
    }
    
    func saveSettings() {
        guard let dataManager = dataManager else { return }
        dataManager.updateSettings(
            targetDeficit: nil, // Will be calculated from deficitRate
            totalCalories: estimatedCalories,
            startingWeight: weight,
            targetWeight: nil,
            activityLevel: activityLevel,
            deficitRate: deficitRate,
            weeklyRestDayEnabled: true,
            sex: sex,
            age: age,
            height: height
        )
    }
}
