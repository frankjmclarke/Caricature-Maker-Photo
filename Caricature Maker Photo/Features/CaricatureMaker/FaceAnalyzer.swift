//
//  FaceAnalyzer.swift
//  Caricature Maker Photo
//
//  Vision-based face and landmark detection.
//

import Foundation
import Vision
import UIKit
import ImageIO

actor FaceAnalyzer {
    func analyze(_ image: UIImage) throws -> [FaceCandidate] {
        // Normalize image: draw with orientation applied so Vision gets a consistent CGImage.
        // Photos from camera often have EXIF orientation (.right etc) which can confuse Vision.
        let normalizedImage = image.normalizedForVision()
        guard let cgImage = normalizedImage?.cgImage ?? image.cgImage else {
            throw FaceAnalyzerError.invalidImage
        }

        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision2
        #if targetEnvironment(simulator)
        // Simulator has no Neural Engine; force CPU to avoid "Could not create inference context" (Code=9)
        request.usesCPUOnly = true
        #endif

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        guard let results = request.results else { return [] }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        var candidates: [FaceCandidate] = []

        for observation in results {
            let boundingBox = convertBoundingBox(observation.boundingBox, imageSize: imageSize)
            guard let landmarks = observation.landmarks else { continue }

            let faceLandmarks = extractLandmarks(landmarks, boundingBox: observation.boundingBox, imageSize: imageSize)
            let candidate = FaceCandidate(boundingBox: boundingBox, landmarksInImageCoords: faceLandmarks)
            candidates.append(candidate)
        }

#if DEBUG
        TraceLogger.trace("FaceAnalyzer", "Detected \(candidates.count) face(s)")
#endif

        return candidates
    }

    private func convertBoundingBox(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let flipped = rect.applying(transform)
        return VNImageRectForNormalizedRect(flipped, Int(imageSize.width), Int(imageSize.height))
    }

    private func normalizedToImage(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        let yFlipped = 1 - point.y
        return CGPoint(
            x: point.x * imageSize.width,
            y: yFlipped * imageSize.height
        )
    }

    private func centerOfNormalizedPoints(_ points: [CGPoint]?, imageSize: CGSize) -> CGPoint? {
        guard let points = points, !points.isEmpty else { return nil }
        let sum = points.reduce(CGPoint.zero) { r, p in CGPoint(x: r.x + p.x, y: r.y + p.y) }
        let avg = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
        return normalizedToImage(avg, imageSize: imageSize)
    }

    private func extractLandmarks(_ landmarks: VNFaceLandmarks2D, boundingBox: CGRect, imageSize: CGSize) -> FaceLandmarks {
        let leftEye = centerOfNormalizedPoints(
            landmarks.leftEye?.normalizedPoints,
            imageSize: imageSize
        ) ?? CGPoint(x: imageSize.width * 0.35, y: imageSize.height * 0.45)
        let rightEye = centerOfNormalizedPoints(
            landmarks.rightEye?.normalizedPoints,
            imageSize: imageSize
        ) ?? CGPoint(x: imageSize.width * 0.65, y: imageSize.height * 0.45)
        let nose = centerOfNormalizedPoints(
            landmarks.nose?.normalizedPoints ?? landmarks.noseCrest?.normalizedPoints,
            imageSize: imageSize
        ) ?? CGPoint(x: imageSize.width * 0.5, y: imageSize.height * 0.55)
        let mouth = centerOfNormalizedPoints(
            landmarks.outerLips?.normalizedPoints ?? landmarks.innerLips?.normalizedPoints,
            imageSize: imageSize
        ) ?? CGPoint(x: imageSize.width * 0.5, y: imageSize.height * 0.7)
        let faceContour = centerOfNormalizedPoints(
            landmarks.faceContour?.normalizedPoints,
            imageSize: imageSize
        ) ?? CGPoint(x: imageSize.width * 0.5, y: imageSize.height * 0.6)

        return FaceLandmarks(
            leftEyeCenter: leftEye,
            rightEyeCenter: rightEye,
            noseCenter: nose,
            mouthCenter: mouth,
            faceContourCenter: faceContour
        )
    }
}

enum FaceAnalyzerError: Error {
    case invalidImage
}

extension UIImage {
    /// Draws the image with orientation applied, producing a consistently oriented image for Vision.
    /// Fixes face detection failures with PhotosPicker images that have EXIF orientation.
    func normalizedForVision() -> UIImage? {
        guard imageOrientation != .up else {
            return cgImage != nil ? self : nil
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalized = renderer.image { _ in
            draw(at: .zero)
        }
        return normalized.cgImage != nil ? normalized : nil
    }
}
