//
//  CaricatureHistoryStore.swift
//  Caricature Maker Photo
//
//  Persists caricature results to Application Support; limit 50 items.
//

import SwiftUI

@MainActor
final class CaricatureHistoryStore: ObservableObject {
    @Published var items: [CaricatureHistoryItem] = []

    private let fileManager = FileManager.default
    private let maxItems = 50

    private var historyDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CaricatureHistory", isDirectory: true)
    }

    private var historyIndexURL: URL {
        historyDirectory.appendingPathComponent("history.json")
    }

    init() {
        loadHistory()
    }

    func loadHistory() {
        guard fileManager.fileExists(atPath: historyIndexURL.path) else {
            items = []
            return
        }
        do {
            let data = try Data(contentsOf: historyIndexURL)
            items = try JSONDecoder().decode([CaricatureHistoryItem].self, from: data)
            items.sort { $0.createdAt > $1.createdAt }
        } catch {
#if DEBUG
            TraceLogger.trace("CaricatureHistoryStore", "Load failed: \(error)")
#endif
            items = []
        }
    }

    func add(
        originalImage: UIImage,
        warpedImage: UIImage,
        resultImage: UIImage,
        styleId: String,
        params: CaricatureWarpParams
    ) {
        let id = UUID()
        let itemDir = historyDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        try? fileManager.createDirectory(at: itemDir, withIntermediateDirectories: true)

        let originalURL = itemDir.appendingPathComponent("original.jpg")
        let warpedURL = itemDir.appendingPathComponent("warped.jpg")
        let resultURL = itemDir.appendingPathComponent("result.jpg")

        guard saveImage(originalImage, to: originalURL),
              saveImage(warpedImage, to: warpedURL),
              saveImage(resultImage, to: resultURL)
        else {
#if DEBUG
            TraceLogger.trace("CaricatureHistoryStore", "Failed to save images")
#endif
            return
        }

        let item = CaricatureHistoryItem(
            id: id,
            createdAt: Date(),
            originalURL: originalURL,
            warpedURL: warpedURL,
            resultURL: resultURL,
            styleId: styleId,
            params: params
        )
        items.insert(item, at: 0)
        trimAndSave()
    }

    func delete(_ item: CaricatureHistoryItem) {
        let itemDir = historyDirectory.appendingPathComponent(item.id.uuidString)
        try? fileManager.removeItem(at: itemDir)
        items.removeAll { $0.id == item.id }
        saveIndex()
    }

    private func saveImage(_ image: UIImage, to url: URL) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    private func trimAndSave() {
        if items.count > maxItems {
            let toRemove = items.suffix(items.count - maxItems)
            for item in toRemove {
                let itemDir = historyDirectory.appendingPathComponent(item.id.uuidString)
                try? fileManager.removeItem(at: itemDir)
            }
            items = Array(items.prefix(maxItems))
        }
        saveIndex()
    }

    private func saveIndex() {
        try? fileManager.createDirectory(at: historyDirectory, withIntermediateDirectories: true)
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: historyIndexURL)
        } catch {
#if DEBUG
            TraceLogger.trace("CaricatureHistoryStore", "Save index failed: \(error)")
#endif
        }
    }
}
