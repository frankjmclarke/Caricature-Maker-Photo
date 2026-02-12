//
//  ConsistencyView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import SwiftUI
import SwiftData

struct ConsistencyView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ConsistencyViewModel?
    
    private func initializeViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = ConsistencyViewModel(dataManager: dataManager)
    }
    
    var daysTrackedPercentage: Int {
        guard let viewModel = viewModel else { return 0 }
        if viewModel.daysTrackedTarget > 0 {
            let percentage = (Double(viewModel.daysTracked) / Double(viewModel.daysTrackedTarget)) * 100
            return min(100, max(0, Int(percentage)))
        }
        return 0
    }
    
    var hitDeficitPercentage: Int {
        guard let viewModel = viewModel else { return 0 }
        if viewModel.daysWithEntriesThisWeek > 0 {
            let percentage = (Double(viewModel.hitDeficitTarget) / Double(viewModel.daysWithEntriesThisWeek)) * 100
            return min(100, max(0, Int(percentage)))
        }
        return 0
    }
    
    var body: some View {
        if let viewModel = viewModel {
            contentView(viewModel: viewModel)
        } else {
            ProgressView()
                .onAppear {
                    initializeViewModel()
                }
        }
    }
    
    private func getCircleColor(
        remainingCalories: Int,
        isRestDay: Bool,
        totalCalories: Int
    ) -> Color {
        if isRestDay {
            // Lighter green for rest day
            return Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.6)
        }
        
        let isNegative = remainingCalories < 0
        if !isNegative {
            return Color(red: 0.2, green: 0.65, blue: 0.55)
        }
        
        // Calculate if negative remaining is more than 15% of total calories
        let threshold = Int(Double(totalCalories) * 0.15)
        let isSeverelyOver = abs(remainingCalories) > threshold
        
        if isSeverelyOver {
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        } else {
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }
    
    @ViewBuilder
    private func contentView(viewModel: ConsistencyViewModel) -> some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let isSmallScreen = screenWidth < 375 // iPhone SE width
            let horizontalPadding: CGFloat = isSmallScreen ? 16 : 20
            let circleSize: CGFloat = isSmallScreen ? 32 : 40
            let circleSpacing: CGFloat = isSmallScreen ? 4 : 8
            let iconSize: CGFloat = isSmallScreen ? 40 : 50
            let cardPadding: CGFloat = isSmallScreen ? 16 : 20
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Am I still on track?")
                            .font(.system(size: isSmallScreen ? 30 : 34, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isSmallScreen ? 20 : 24)
                    .padding(.bottom, isSmallScreen ? 20 : 24)
                    
                    // Hero Status Block
                    let status = viewModel.onTrackStatus
                    VStack(alignment: .leading, spacing: 6) {
                        Text(status.title)
                            .font(.system(size: isSmallScreen ? 22 : 26, weight: .bold))
                            .foregroundColor(status.color)
                        
                        Text("Based on your recent activity")
                            .font(.system(size: isSmallScreen ? 12 : 13, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.statusExplanation)
                            .font(.system(size: isSmallScreen ? 14 : 15, weight: .regular))
                            .foregroundColor(.primary)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(cardPadding)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                status.color.opacity(0.1),
                                status.color.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: status.color.opacity(0.15), radius: 12, x: 0, y: 3)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 24)
                    
                    // This Week Engagement Indicators
                    VStack(alignment: .leading, spacing: isSmallScreen ? 12 : 16) {
                        Text("This Week")
                            .font(.system(size: isSmallScreen ? 18 : 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: circleSpacing) {
                            ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, day in
                                VStack(spacing: 4) {
                                    ZStack {
                                        if viewModel.weekProgress[index] {
                                            // Engaged day - check remaining calories status
                                            let remainingCalories = viewModel.weekRemainingCalories[index] ?? 0
                                            let isRestDay = viewModel.restDayIndex == index
                                            let circleColor = getCircleColor(
                                                remainingCalories: remainingCalories,
                                                isRestDay: isRestDay,
                                                totalCalories: viewModel.totalCalories
                                            )
                                            
                                            Circle()
                                                .fill(circleColor)
                                                .frame(width: circleSize, height: circleSize)
                                            
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: isSmallScreen ? 8 : 10, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            // Not yet engaged
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(width: circleSize, height: circleSize)
                                                .background(Circle().fill(Color(.systemBackground)))
                                        }
                                    }
                                    
                                    Text(day)
                                        .font(.system(size: isSmallScreen ? 10 : 11, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Legend
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.65, blue: 0.55)) // Reduced green saturation
                                    .frame(width: 12, height: 12)
                                
                                Text("Counted (logged or estimated)")
                                    .font(.system(size: isSmallScreen ? 11 : 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 12, height: 12)
                                
                                Text("No data")
                                    .font(.system(size: isSmallScreen ? 11 : 12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    .padding(cardPadding)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.systemBackground),
                                Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.05) // Reduced green saturation
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.15), radius: 12, x: 0, y: 3) // Reduced green saturation
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 16)
                    
                    // Engagement Streak (Secondary - Reduced prominence)
                    if viewModel.daysEngaged > 0 {
                        HStack {
                            if viewModel.daysEngaged < 5 {
                                Text("\(viewModel.daysEngaged) \(viewModel.daysEngaged == 1 ? "day" : "days") · building")
                                    .font(.system(size: isSmallScreen ? 13 : 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Engagement: \(viewModel.daysEngaged) active days")
                                    .font(.system(size: isSmallScreen ? 13 : 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 16)
                    }
                
                    // Stats Cards
                    VStack(spacing: 16) {
                        // Days Tracked Card
                        HStack(spacing: isSmallScreen ? 12 : 16) {
                            // Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.5, blue: 0.9)) // Blue
                                    .frame(width: iconSize, height: iconSize)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: isSmallScreen ? 16 : 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAYS\nENGAGED")
                                    .font(.system(size: isSmallScreen ? 10 : 11, weight: .medium))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                
                                HStack(alignment: .firstTextBaseline, spacing: isSmallScreen ? 4 : 8) {
                                    Text("\(viewModel.daysTracked) / \(viewModel.daysTrackedTarget)")
                                        .font(.system(size: isSmallScreen ? 18 : 22, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    
                                    Spacer(minLength: 4)
                                    
                                    // Percentage Badge
                                    Text("\(daysTrackedPercentage)%")
                                        .font(.system(size: isSmallScreen ? 11 : 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, isSmallScreen ? 8 : 10)
                                        .padding(.vertical, isSmallScreen ? 4 : 5)
                                        .background(
                                            Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.2) // Reduced green saturation
                                        )
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(cardPadding)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemBackground),
                                    Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.05) // Reduced green saturation
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.15), radius: 12, x: 0, y: 3)
                        
                        // Hit Deficit Target Card
                        HStack(spacing: isSmallScreen ? 12 : 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.6, green: 0.4, blue: 0.8)) // Purple
                                    .frame(width: iconSize, height: iconSize)
                                
                                Image(systemName: "target")
                                    .font(.system(size: isSmallScreen ? 16 : 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TARGET DAYS\nMET")
                                    .font(.system(size: isSmallScreen ? 10 : 11, weight: .medium))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                
                                HStack(alignment: .firstTextBaseline, spacing: isSmallScreen ? 4 : 8) {
                                    Text("\(viewModel.hitDeficitTarget) / \(viewModel.daysWithEntriesThisWeek)")
                                        .font(.system(size: isSmallScreen ? 18 : 22, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    
                                    Spacer(minLength: 4)
                                    
                                    // Percentage Badge
                                    Text("\(hitDeficitPercentage)%")
                                        .font(.system(size: isSmallScreen ? 11 : 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, isSmallScreen ? 8 : 10)
                                        .padding(.vertical, isSmallScreen ? 4 : 5)
                                        .background(
                                            Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.2) // Reduced green saturation
                                        )
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(cardPadding)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemBackground),
                                    Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.05) // Reduced green saturation
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.6).opacity(0.15), radius: 12, x: 0, y: 3)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGroupedBackground),
                    Color(red: 0.2, green: 0.65, blue: 0.55).opacity(0.03) // Reduced green saturation
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ConsistencyView()
    }
}
