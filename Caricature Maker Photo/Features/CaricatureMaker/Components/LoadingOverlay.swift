//
//  LoadingOverlay.swift
//  Caricature Maker Photo
//

import SwiftUI

struct LoadingOverlay: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                if let message {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
