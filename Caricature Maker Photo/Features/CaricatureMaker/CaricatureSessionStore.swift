//
//  CaricatureSessionStore.swift
//  Caricature Maker Photo
//
//  Central session state machine for the caricature flow.
//

import SwiftUI

@MainActor
final class CaricatureSessionStore: ObservableObject {
    @Published var stage: CaricatureStage = .idle
    @Published var selectedImage: UIImage?
    @Published var selectedFace: FaceCandidate?
    @Published var faces: [FaceCandidate] = []
    @Published var params: CaricatureWarpParams = .init()
    @Published var selectedStyle: CaricatureStyle = CaricatureStyle.all[0]
    @Published var warpedPreview: UIImage?
    @Published var errorMessage: String?

    func transitionToSelected(image: UIImage) {
        stage = .selected
        selectedImage = image
        selectedFace = nil
        faces = []
        warpedPreview = nil
        errorMessage = nil
    }

    func transitionToAnalyzing() {
        stage = .analyzing
        errorMessage = nil
    }

    func transitionToEditing(faces: [FaceCandidate]) {
        self.faces = faces
        if faces.count == 1 {
            selectedFace = faces[0]
            stage = .editing
        } else {
            selectedFace = nil
            stage = .editing
        }
        errorMessage = nil
    }

    func selectFace(_ face: FaceCandidate) {
        selectedFace = face
        errorMessage = nil
    }

    func transitionToGenerating() {
        stage = .generating
        errorMessage = nil
    }

    func transitionToDone() {
        stage = .done
        errorMessage = nil
    }

    func transitionToError(_ message: String) {
        stage = .error(message)
        errorMessage = message
    }

    func reset() {
        stage = .idle
        selectedImage = nil
        selectedFace = nil
        faces = []
        warpedPreview = nil
        errorMessage = nil
    }
}
