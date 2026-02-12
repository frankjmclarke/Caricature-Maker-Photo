//
//  ProgressView.swift
//  Caricature Maker Photo
//
//  Created by Francis Clarke on 2026-01-08.
//

import SwiftUI
import SwiftData
import Charts

struct YourProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProgressViewModel?
    
    private func initializeViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = ProgressViewModel(dataManager: dataManager)
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
    
    @ViewBuilder
    private func contentView(viewModel: ProgressViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.weeksTracking) weeks of tracking")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Metrics Grid (2x2)
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        MetricCard(label: "CURRENT", value: String(format: "%.1f", viewModel.currentWeight), unit: "kg")
                        MetricCard(label: "STARTING", value: String(format: "%.1f", viewModel.startingWeight), unit: "kg")
                    }
                    
                    HStack(spacing: 12) {
                        MetricCard(label: "LOST", value: String(format: "%.1f", viewModel.lostWeight), unit: "kg", isHighlighted: true)
                        MetricCard(label: "REMAINING", value: String(format: "%.1f", viewModel.remainingWeight), unit: "kg")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Weight Trend Graph Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Weight Trend")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Trend Badge
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            
                            Text("\(String(format: "%.2f", viewModel.weeklyTrend)) kg/week")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15)
                        )
                        .cornerRadius(12)
                    }
                    
                    // Chart
                    Chart {
                        ForEach(viewModel.weightData) { data in
                            LineMark(
                                x: .value("Week", data.week),
                                y: .value("Weight", data.weight)
                            )
                            .foregroundStyle(Color(red: 0.1, green: 0.6, blue: 0.3))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            
                            PointMark(
                                x: .value("Week", data.week),
                                y: .value("Weight", data.weight)
                            )
                            .foregroundStyle(Color(red: 0.1, green: 0.6, blue: 0.3))
                            .symbolSize(80)
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 79...83)
                    .chartYAxis {
                        AxisMarks(values: .stride(by: 1)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let stringValue = value.as(String.self) {
                                    Text(stringValue)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetricCard: View {
    let label: String
    let value: String
    let unit: String
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHighlighted ? .white.opacity(0.9) : .gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isHighlighted ? .white : .primary)
                
                Text(unit)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isHighlighted ? .white.opacity(0.9) : .primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            isHighlighted 
                ? Color(red: 0.2, green: 0.8, blue: 0.4)
                : Color(.systemBackground)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        YourProgressView()
    }
}
