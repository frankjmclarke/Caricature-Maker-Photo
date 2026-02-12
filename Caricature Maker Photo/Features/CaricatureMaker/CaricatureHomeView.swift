//
//  CaricatureHomeView.swift
//  Caricature Maker Photo
//

import SwiftUI
import PhotosUI

struct CaricatureHomeView: View {
    @StateObject private var sessionStore = CaricatureSessionStore()
    @StateObject private var historyStore = CaricatureHistoryStore()
    @StateObject private var generationStore = CaricatureGenerationStore()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var navigationPath = NavigationPath()

    private let faceAnalyzer = FaceAnalyzer()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink(value: "create") {
                        HStack {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create Caricature")
                                    .font(.headline)
                                Text("Pick a photo and transform it")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        sessionStore.reset()
                    })

                    if !historyStore.items.isEmpty {
                        Text("Recent Results")
                            .font(.headline)
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(historyStore.items) { item in
                                NavigationLink(value: item) {
                                    if let thumb = loadThumb(from: item.resultURL) {
                                        Image(uiImage: thumb)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No caricatures yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Caricature Maker")
            .navigationDestination(for: String.self) { value in
                if value == "create" {
                    CreateCaricatureFlowView(
                        sessionStore: sessionStore,
                        historyStore: historyStore,
                        generationStore: generationStore
                    )
                }
            }
            .navigationDestination(for: CaricatureHistoryItem.self) { item in
                CaricatureResultView(item: item, historyStore: historyStore)
            }
        }
    }

    private func loadThumb(from url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else { return nil }
        return image
    }
}

struct CreateCaricatureFlowView: View {
    @ObservedObject var sessionStore: CaricatureSessionStore
    @ObservedObject var historyStore: CaricatureHistoryStore
    @ObservedObject var generationStore: CaricatureGenerationStore
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    private let faceAnalyzer = FaceAnalyzer()

    var body: some View {
        Group {
            switch sessionStore.stage {
            case .idle, .selected:
                if sessionStore.selectedImage == nil {
                    PhotoPickerView(selectedItem: $selectedPhotoItem) { image in
                        sessionStore.transitionToSelected(image: image)
                    }
                } else {
                    ZStack {
                        if let img = sessionStore.selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .opacity(0.3)
                        }
                        LoadingOverlay(message: "Detecting faces...")
                    }
                    .onAppear { runAnalysis() }
                }
            case .analyzing:
                LoadingOverlay(message: "Detecting faces...")
            case .editing:
                if sessionStore.faces.count > 1 && sessionStore.selectedFace == nil {
                    FacePickerView(
                        image: sessionStore.selectedImage!,
                        faces: sessionStore.faces,
                        onFaceSelected: { sessionStore.selectFace($0) }
                    )
                } else if sessionStore.selectedFace != nil {
                    CaricatureEditorView(
                        sessionStore: sessionStore,
                        historyStore: historyStore,
                        generationStore: generationStore
                    )
                } else {
                    LoadingOverlay(message: "Loading editor...")
                }
            case .generating:
                CaricatureGeneratingView(generationStore: generationStore)
            case .done:
                if let latest = historyStore.items.first {
                    CaricatureResultView(
                        item: latest,
                        historyStore: historyStore,
                        onDelete: { sessionStore.reset() }
                    )
                } else {
                    EmptyView()
                }
            case .error(let message):
                ErrorFlowView(
                    message: message,
                    sessionStore: sessionStore,
                    onRetry: { sessionStore.reset() }
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard newItem != nil else { return }
        }
    }

    private func runAnalysis() {
        guard let image = sessionStore.selectedImage else { return }
        sessionStore.transitionToAnalyzing()
        Task {
            do {
                let faces = try await faceAnalyzer.analyze(image)
                await MainActor.run {
                    if faces.isEmpty {
                        sessionStore.transitionToError("No face detected. Please choose a photo with a clear, front-facing face.")
                    } else {
                        sessionStore.transitionToEditing(faces: faces)
                    }
                }
            } catch {
#if DEBUG
                TraceLogger.trace("CreateCaricatureFlowView", "Face analysis error: \(error)")
#endif
                await MainActor.run {
                    sessionStore.transitionToError("Face detection failed. Please try another photo.")
                }
            }
        }
    }
}

struct ErrorFlowView: View {
    let message: String
    @ObservedObject var sessionStore: CaricatureSessionStore
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ErrorBanner(message: message, onRetry: onRetry)
            Button("Choose Different Photo") {
                sessionStore.reset()
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}
