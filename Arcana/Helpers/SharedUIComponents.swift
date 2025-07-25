// SharedUIComponents.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

// MARK: - Shared Typing Indicator (used by both ChatView and InvisibleChatView)

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 6, height: 6)
                            .opacity(animationPhase == index ? 1 : 0.3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                Text("Arcana is thinking...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Invisible Workspace Type Indicator

struct InvisibleWorkspaceTypeIndicator: View {
    let workspaceType: WorkspaceManager.WorkspaceType
    let isInHeader: Bool
    
    init(_ workspaceType: WorkspaceManager.WorkspaceType, inHeader: Bool = false) {
        self.workspaceType = workspaceType
        self.isInHeader = inHeader
    }
    
    var body: some View {
        if isInHeader {
            // In chat header: subtle, barely visible unless you look for it
            Circle()
                .fill(typeColor.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(typeColor.opacity(0.6), lineWidth: 1)
                )
                .help((workspaceType as WorkspaceManager.WorkspaceType).displayName + " workspace")
        } else {
            // In sidebar: only visible on hover or selection
            Text(workspaceType.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(typeColor.opacity(0.1))
                        .stroke(typeColor.opacity(0.3), lineWidth: 0.5)
                )
                .foregroundStyle(typeColor)
                .opacity(0.7) // Subtle by default
        }
    }
    
    private var typeColor: Color {
        switch workspaceType {
        case .code: return .blue
        case .creative: return .purple
        case .research: return .orange
        case .general: return .gray
        }
    }
}

// MARK: - Hover-Reveal Type Badge (for sidebar)

struct HoverRevealTypeBadge: View {
    let workspaceType: WorkspaceManager.WorkspaceType
    let isSelected: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Spacer()
            
            // Only show type badge on hover or when selected
            if isHovered || isSelected {
                InvisibleWorkspaceTypeIndicator(workspaceType)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
