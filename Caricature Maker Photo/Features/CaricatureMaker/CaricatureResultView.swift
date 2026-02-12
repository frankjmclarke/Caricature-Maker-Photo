//
//  CaricatureResultView.swift
//  Caricature Maker Photo
//

import SwiftUI
import Photos

struct CaricatureResultView: View {
    let item: CaricatureHistoryItem
    @ObservedObject var historyStore: CaricatureHistoryStore
    var onDelete: (() -> Void)?
    @State private var beforeAfterRatio: Double = 1
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var saveMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .leading) {
                    if let original = loadImage(from: item.originalURL),
                       let result = loadImage(from: item.resultURL) {
                        Image(uiImage: original)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                        Image(uiImage: result)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .mask(
                                GeometryReader { geo in
                                    Rectangle()
                                        .frame(width: geo.size.width * beforeAfterRatio, height: geo.size.height)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            )
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: 400)
                .clipped()

                Slider(value: $beforeAfterRatio, in: 0...1)
                    .padding(.horizontal)
                Text("Drag to compare before and after")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    Button {
                        if let img = loadImage(from: item.resultURL) {
                            saveToPhotos(img)
                        }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        if let img = loadImage(from: item.resultURL) {
                            shareImage = img
                            showShareSheet = true
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if let msg = saveMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    historyStore.delete(item)
                    onDelete?()
                } label: {
                    Label("Delete from History", systemImage: "trash")
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Result")
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    private func loadImage(from url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data)
        else { return nil }
        return image
    }

    private func saveToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    saveMessage = "Photo library access denied."
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    saveMessage = success ? "Saved to Photos" : (error?.localizedDescription ?? "Save failed.")
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
