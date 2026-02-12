//
//  CaricatureEditorView.swift
//  Caricature Maker Photo
//

import SwiftUI

struct CaricatureEditorView: View {
    @EnvironmentObject var entitlementManager: EntitlementManager
    @ObservedObject var sessionStore: CaricatureSessionStore
    @ObservedObject var historyStore: CaricatureHistoryStore
    @ObservedObject var generationStore: CaricatureGenerationStore
    @State private var showPaywallForCaricature = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let image = sessionStore.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Caricature Intensity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Slider(value: $sessionStore.params.intensity, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Eyes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Slider(value: $sessionStore.params.eyes, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Nose")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Slider(value: $sessionStore.params.nose, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Mouth")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Slider(value: $sessionStore.params.mouth, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Jaw")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Slider(value: $sessionStore.params.jaw, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("Style", selection: $sessionStore.selectedStyle) {
                        ForEach(CaricatureStyle.all) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Button {
                    if skipPaywall || entitlementManager.hasPremiumAccess {
                        generationStore.run(sessionStore: sessionStore, historyStore: historyStore)
                    } else {
                        showPaywallForCaricature = true
                    }
                } label: {
                    Text("Generate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(sessionStore.selectedFace == nil)
            }
            .padding()
        }
        .navigationTitle("Editor")
        .sheet(isPresented: $showPaywallForCaricature) {
            PaywallSheetView(
                entitlementManager: entitlementManager,
                onDismiss: { showPaywallForCaricature = false }
            )
        }
    }
}
