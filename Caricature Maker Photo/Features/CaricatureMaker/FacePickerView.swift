//
//  FacePickerView.swift
//  Caricature Maker Photo
//

import SwiftUI

struct FacePickerView: View {
    let image: UIImage
    let faces: [FaceCandidate]
    let onFaceSelected: (FaceCandidate) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Multiple faces found. Tap the face you want to caricature.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 16)
                ], spacing: 16) {
                    ForEach(faces) { face in
                        FaceThumbnailView(image: image, face: face)
                            .onTapGesture {
                                onFaceSelected(face)
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Select Face")
    }
}

private struct FaceThumbnailView: View {
    let image: UIImage
    let face: FaceCandidate

    var body: some View {
        GeometryReader { geo in
            let cropRect = face.boundingBox
            if let cropped = cropImage(image, to: cropRect) {
                Image(uiImage: cropped)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.width)
                    .clipped()
                    .cornerRadius(12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, w - 1)),
            y: max(0, min(rect.origin.y, h - 1)),
            width: min(rect.width, w - max(0, rect.origin.x)),
            height: min(rect.height, h - max(0, rect.origin.y))
        )
        guard clampedRect.width > 0, clampedRect.height > 0,
              let cropped = cgImage.cropping(to: clampedRect)
        else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
