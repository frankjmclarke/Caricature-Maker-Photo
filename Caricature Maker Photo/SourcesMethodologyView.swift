//
//  SourcesMethodologyView.swift
//  Caricature Maker Photo
//
//  Created on 2026-01-20.
//

import SwiftUI

struct SourcesMethodologyView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Source URLs
    private let mifflinPubMedURL = URL(string: "https://pubmed.ncbi.nlm.nih.gov/2305711/")!
    private let faoWHOURL = URL(string: "https://www.fao.org/3/y5686e/y5686e.pdf")!
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sources & Methodology")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("How we calculate your estimated maintenance calories")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    
                    // How It Works Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("We estimate basal metabolic rate (BMR) using Mifflin–St Jeor, then multiply by an activity factor to estimate TDEE (Total Daily Energy Expenditure).")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Formulas Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Formulas")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basal Metabolic Rate (BMR)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Male:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text("BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age + 5")
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                                
                                Text("Female:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                Text("BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161")
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("Total Daily Energy Expenditure (TDEE)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("TDEE = BMR × activity factor")
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Activity Factors Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity Factors")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("\(level.multiplier)")
                                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .frame(width: 50, alignment: .leading)
                                    
                                    Text(level.rawValue)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.primary)
                                }
                                
                                if level != ActivityLevel.allCases.last {
                                    Divider()
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Disclaimer Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Disclaimer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("This estimate is for general informational purposes and is not medical advice.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Sources Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sources")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Link(destination: mifflinPubMedURL) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mifflin MD, et al. A new predictive equation for resting energy expenditure in healthy individuals.")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.blue)
                                    
                                    Text("Am J Clin Nutr. 1990;51(2):241-7.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Link(destination: faoWHOURL) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("FAO/WHO/UNU. Human energy requirements.")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.blue)
                                    
                                    Text("Food and Agriculture Organization of the United Nations. 2004.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SourcesMethodologyView()
}
