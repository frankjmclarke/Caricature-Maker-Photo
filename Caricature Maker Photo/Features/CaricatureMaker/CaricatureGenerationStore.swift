//
//  CaricatureGenerationStore.swift
//  Caricature Maker Photo
//
//  Runs pipeline: analyze -> warp -> upload job -> poll -> download -> persist.
//

import SwiftUI

@MainActor
final class CaricatureGenerationStore: ObservableObject {
    @Published var progressMessage: String = ""
    @Published var isCancellable: Bool = true

    private var currentTask: Task<Void, Never>?
    private let faceAnalyzer = FaceAnalyzer()
    private let apiClient = CaricatureAPIClient()

    func run(sessionStore: CaricatureSessionStore, historyStore: CaricatureHistoryStore) {
        currentTask?.cancel()
        currentTask = Task {
            await executePipeline(sessionStore: sessionStore, historyStore: historyStore)
        }
    }

    func cancel() {
        currentTask?.cancel()
    }

    private func executePipeline(sessionStore: CaricatureSessionStore, historyStore: CaricatureHistoryStore) async {
        isCancellable = true
        progressMessage = "Analyzing face..."

        guard let image = sessionStore.selectedImage else {
            sessionStore.transitionToError("No image selected.")
            return
        }
        guard let face = sessionStore.selectedFace else {
            sessionStore.transitionToError("Please select a face.")
            return
        }

        sessionStore.transitionToAnalyzing()

        do {
            try Task.checkCancellation()
        } catch {
            sessionStore.transitionToEditing(faces: sessionStore.faces)
            return
        }

        progressMessage = "Warping image..."
#if DEBUG
        TraceLogger.trace("CaricatureGenerationStore", "Warping image")
#endif

        guard let warpedImage = CaricatureWarper.warp(image, face: face, params: sessionStore.params) else {
            sessionStore.transitionToError("Warp failed.")
            return
        }

        sessionStore.transitionToGenerating()
        progressMessage = "Uploading..."

        guard let warpedData = warpedImage.jpegData(compressionQuality: 0.9) else {
            sessionStore.transitionToError("Failed to prepare image.")
            return
        }

        let jobId: String
        do {
            try Task.checkCancellation()
            jobId = try await apiClient.createJob(
                image: warpedData,
                styleId: sessionStore.selectedStyle.id,
                params: sessionStore.params
            )
        } catch {
#if DEBUG
            TraceLogger.trace("CaricatureGenerationStore", "Create job failed: \(error)")
#endif
            // Fallback: when server unreachable (e.g. placeholder URL, no backend), use warped image as result
            if CaricatureConfig.isPlaceholderURL || (error as NSError).code == NSURLErrorCannotFindHost {
                progressMessage = "Using local result (server not configured)"
#if DEBUG
                TraceLogger.trace("CaricatureGenerationStore", "Using warped image as result (no server)")
#endif
                historyStore.add(
                    originalImage: image,
                    warpedImage: warpedImage,
                    resultImage: warpedImage,
                    styleId: sessionStore.selectedStyle.id,
                    params: sessionStore.params
                )
                sessionStore.transitionToDone()
                return
            }
            sessionStore.transitionToError("Generation failed. Please check your connection and try again.")
            return
        }

        progressMessage = "Generating caricature..."

        let jobStatus: JobStatus
        do {
            try Task.checkCancellation()
            jobStatus = try await apiClient.pollJob(id: jobId)
        } catch is CancellationError {
            sessionStore.transitionToEditing(faces: sessionStore.faces)
            return
        } catch {
#if DEBUG
            TraceLogger.trace("CaricatureGenerationStore", "Poll failed: \(error)")
#endif
            sessionStore.transitionToError("Generation failed. Please check your connection and try again.")
            return
        }

        switch jobStatus {
        case .succeeded(let resultURL):
            progressMessage = "Downloading result..."
            do {
                try Task.checkCancellation()
                let resultData = try await apiClient.downloadResult(url: resultURL)
                guard let resultImage = UIImage(data: resultData) else {
                    sessionStore.transitionToError("Invalid result image.")
                    return
                }
#if DEBUG
                TraceLogger.trace("CaricatureGenerationStore", "Saving to history")
#endif
                historyStore.add(
                    originalImage: image,
                    warpedImage: warpedImage,
                    resultImage: resultImage,
                    styleId: sessionStore.selectedStyle.id,
                    params: sessionStore.params
                )
                sessionStore.transitionToDone()
            } catch is CancellationError {
                sessionStore.transitionToEditing(faces: sessionStore.faces)
            } catch {
#if DEBUG
                TraceLogger.trace("CaricatureGenerationStore", "Download failed: \(error)")
#endif
                sessionStore.transitionToError("Generation failed. Please check your connection and try again.")
            }
        case .failed(let message):
            sessionStore.transitionToError(message)
        case .pending:
            sessionStore.transitionToError("Generation failed. Please check your connection and try again.")
        }
    }
}
