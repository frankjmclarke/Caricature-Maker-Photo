//
//  ErrorBanner.swift
//  Caricature Maker Photo
//

import SwiftUI

struct ErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
            if let onRetry {
                Button("Retry") {
                    onRetry()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
