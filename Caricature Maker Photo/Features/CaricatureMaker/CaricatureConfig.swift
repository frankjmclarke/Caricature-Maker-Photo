//
//  CaricatureConfig.swift
//  Caricature Maker Photo
//
//  How to configure server URL:
//  1. Copy Config.plist.example to Config.plist
//  2. Set CARICATURE_API_BASE_URL to your server (e.g. https://your-api.com)
//  3. Server must implement: POST /v1/jobs (multipart: image + json {style_id, warp_params}),
//     GET /v1/jobs/{id} (returns {status, result_url})
//

import Foundation

enum CaricatureConfig {
    private static let placeholderHost = "api.example.com"

    static var baseURL: URL {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let urlString = plist["CARICATURE_API_BASE_URL"] as? String,
              !urlString.isEmpty,
              let url = URL(string: urlString)
        else {
            return URL(string: "https://\(placeholderHost)/caricature")!
        }
        return url
    }

    /// True when using the placeholder URL (no real server configured). Enables local-only fallback.
    static var isPlaceholderURL: Bool {
        baseURL.host == placeholderHost
    }
}
