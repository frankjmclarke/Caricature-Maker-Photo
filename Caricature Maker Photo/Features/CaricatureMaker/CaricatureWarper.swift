//
//  CaricatureWarper.swift
//  Caricature Maker Photo
//
//  Local geometric warping using CoreImage, guided by face landmarks.
//

import UIKit
import CoreImage

struct CaricatureWarper {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])
    private static let maxScale: Float = 1.3
    private static let minScale: Float = 0.9

    /// Warps the image using face landmarks and params. Keeps warps subtle to avoid grotesque artifacts.
    static func warp(
        _ image: UIImage,
        face: FaceCandidate,
        params: CaricatureWarpParams
    ) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let landmarks = face.landmarksInImageCoords
        let size = image.size

        // Clamp intensity to moderate range (0.5 = neutral, 1 = max exaggeration)
        let scaleFactor = Float(0.5 + params.intensity * 0.5)

        var currentImage = ciImage
        // Convert from top-left (UIKit) to bottom-left (Core Image) coordinate system
        func toCICoords(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x, y: size.height - p.y)
        }

        // Eyes: apply bump at both eye centers with eyes param
        let eyesScale = mapParam(params.eyes, base: scaleFactor)
        currentImage = applyBump(to: currentImage, center: toCICoords(landmarks.leftEyeCenter), radius: size.width * 0.08, scale: eyesScale)
        currentImage = applyBump(to: currentImage, center: toCICoords(landmarks.rightEyeCenter), radius: size.width * 0.08, scale: eyesScale)

        // Nose: bump at nose center
        let noseScale = mapParam(params.nose, base: scaleFactor)
        currentImage = applyBump(to: currentImage, center: toCICoords(landmarks.noseCenter), radius: size.width * 0.1, scale: noseScale)

        // Mouth: bump at mouth center
        let mouthScale = mapParam(params.mouth, base: scaleFactor)
        currentImage = applyBump(to: currentImage, center: toCICoords(landmarks.mouthCenter), radius: size.width * 0.06, scale: mouthScale)

        // Jaw: pinch at face contour (slight jaw exaggeration)
        let jawScale = mapParam(params.jaw, base: scaleFactor)
        currentImage = applyPinch(to: currentImage, center: toCICoords(landmarks.faceContourCenter), radius: size.width * 0.2, scale: jawScale)

        guard let outputCGImage = context.createCGImage(currentImage, from: currentImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage)
    }

    private static func mapParam(_ value: Double, base: Float) -> Float {
        let scaled = Float(value) * (base - 1) + 1
        return min(max(scaled, Self.minScale), Self.maxScale)
    }

    private static func applyBump(to image: CIImage, center: CGPoint, radius: CGFloat, scale: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIBumpDistortion") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: center), forKey: "inputCenter")
        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(scale, forKey: "inputScale")
        return filter.outputImage ?? image
    }

    private static func applyPinch(to image: CIImage, center: CGPoint, radius: CGFloat, scale: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIPinchDistortion") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: center), forKey: "inputCenter")
        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(-(scale - 1) * 0.5, forKey: "inputScale")
        return filter.outputImage ?? image
    }
}

