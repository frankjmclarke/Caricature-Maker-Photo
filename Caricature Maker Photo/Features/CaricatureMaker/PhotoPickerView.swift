//
//  PhotoPickerView.swift
//  Caricature Maker Photo
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    let onImageLoaded: (UIImage) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Choose Photo")
                    .font(.headline)
                Text("Select a photo with a clear face")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        onImageLoaded(image)
                    }
                }
            }
        }
    }
}
