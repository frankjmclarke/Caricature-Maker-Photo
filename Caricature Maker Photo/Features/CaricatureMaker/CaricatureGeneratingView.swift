//
//  CaricatureGeneratingView.swift
//  Caricature Maker Photo
//

import SwiftUI

struct CaricatureGeneratingView: View {
    @ObservedObject var generationStore: CaricatureGenerationStore

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(2)
            Text(generationStore.progressMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if generationStore.isCancellable {
                Button("Cancel") {
                    generationStore.cancel()
                }
                .padding(.top, 16)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Generating")
        .navigationBarBackButtonHidden(true)
    }
}
