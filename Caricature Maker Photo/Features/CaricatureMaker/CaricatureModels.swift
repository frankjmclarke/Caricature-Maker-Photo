//
//  CaricatureModels.swift
//  Caricature Maker Photo
//
//  Caricature feature models.
//

import Foundation
import CoreGraphics

// MARK: - Caricature Stage

enum CaricatureStage: Equatable {
    case idle
    case selected
    case analyzing
    case editing
    case generating
    case done
    case error(String)
}

// MARK: - Caricature Warp Params

struct CaricatureWarpParams: Codable, Equatable, Hashable {
    var intensity: Double
    var eyes: Double
    var nose: Double
    var mouth: Double
    var jaw: Double

    init(
        intensity: Double = 0.5,
        eyes: Double = 0.5,
        nose: Double = 0.5,
        mouth: Double = 0.5,
        jaw: Double = 0.5
    ) {
        self.intensity = max(0, min(1, intensity))
        self.eyes = max(0, min(1, eyes))
        self.nose = max(0, min(1, nose))
        self.mouth = max(0, min(1, mouth))
        self.jaw = max(0, min(1, jaw))
    }
}

// MARK: - Caricature Style

struct CaricatureStyle: Identifiable, Equatable, Hashable {
    let id: String
    let displayName: String

    static let all: [CaricatureStyle] = [
        .init(id: "cartoon", displayName: "Cartoon"),
        .init(id: "sketch", displayName: "Sketch"),
        .init(id: "pop_art", displayName: "Pop Art"),
        .init(id: "watercolor", displayName: "Watercolor"),
        .init(id: "comic", displayName: "Comic")
    ]

    static func with(id: String) -> CaricatureStyle? {
        all.first { $0.id == id }
    }
}

// MARK: - Face Candidate

struct FaceCandidate: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    /// Landmark centers in image pixel coordinates for warping
    let landmarksInImageCoords: FaceLandmarks
}

struct FaceLandmarks {
    let leftEyeCenter: CGPoint
    let rightEyeCenter: CGPoint
    let noseCenter: CGPoint
    let mouthCenter: CGPoint
    let faceContourCenter: CGPoint
}

// MARK: - Caricature History Item

struct CaricatureHistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let originalURL: URL
    let warpedURL: URL
    let resultURL: URL
    let styleId: String
    let params: CaricatureWarpParams

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        originalURL: URL,
        warpedURL: URL,
        resultURL: URL,
        styleId: String,
        params: CaricatureWarpParams
    ) {
        self.id = id
        self.createdAt = createdAt
        self.originalURL = originalURL
        self.warpedURL = warpedURL
        self.resultURL = resultURL
        self.styleId = styleId
        self.params = params
    }
}
