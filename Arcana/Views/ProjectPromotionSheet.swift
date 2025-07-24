// ProjectPromotionSheet.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ProjectPromotionSheet: View {
    let suggestion: ProjectPromotionSuggestion
    @Environment(\.dismiss) private var dismiss
    @StateObject private var threadManager = ThreadManager.shared
    
    @State private var customTitle = ""
    @State private var useCustomTitle = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with intelligent suggestion
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 28))
                        .foregroundStyle(.yellow.gradient)
                        .symbolEffect(.pulse)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.suggestedType.emoji)
                            .font(.title2)
                        Text(suggestion.suggestedType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Save as Project?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(suggestion.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            // Project configuration
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Project Details")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    // Suggested title with option to customize
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Project Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(useCustomTitle ? "Use Suggestion" : "Customize") {
                                useCustomTitle.toggle()
                                if !useCustomTitle {
                                    customTitle = ""
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }
                        
                        if useCustomTitle {
                            TextField("Enter custom name", text: $customTitle)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            HStack {
                                Text("💡 \(suggestion.suggestedTitle)")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                
                                Spacer()
                            }
                        }
                    }
                    
                    // Conversation preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This conversation will be saved:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(spacing: 4) {
                            Text("• \(suggestion.thread.messages.count) messages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if !suggestion.thread.attachedFiles.isEmpty {
                                Text("• \(suggestion.thread.attachedFiles.count) attached files")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("• Started \(suggestion.thread.lastModified, style: .relative)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Text("Future conversations on this topic will be automatically organized under this project")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                
                HStack(spacing: 12) {
                    Button("Not Now") {
                        threadManager.dismissPromotion()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Create Project") {
                        let title = useCustomTitle && !customTitle.isEmpty ? customTitle : suggestion.suggestedTitle
                        threadManager.promoteToProject(suggestion, title: title)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 480, height: 420)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    let thread = ConversationThread(title: "Code Review Discussion", type: .instant, projectId: nil)
    let suggestion = ProjectPromotionSuggestion(
        thread: thread,
        suggestedType: .code,
        suggestedTitle: "API Development Project",
        reason: "This looks like a coding discussion. Save as a project to keep track of solutions and code snippets?"
    )
    
    ProjectPromotionSheet(suggestion: suggestion)
}
