// UXAnimations.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct UXAnimations {
    // Shimmer effect for loading states
    static func shimmerEffect() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: 0.8)
                    .rotationEffect(.degrees(10))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
            )
    }
    
    // Pulse animation for status indicators
    static func pulseAnimation() -> Animation {
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }
    
    // Smooth slide transitions
    static func slideTransition() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}
