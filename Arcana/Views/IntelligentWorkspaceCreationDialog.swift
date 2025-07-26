// IntelligentWorkspaceCreationDialog.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, ChatMessage.swift, WorkspaceManager.swift

import SwiftUI

struct IntelligentWorkspaceCreationDialog: View {
    let context: WorkspaceCreationContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var threadManager = ThreadManager.shared
    
    @State private var customTitle = ""
    @State private var customDescription = ""
    @State private var showCustomization = false
    @State private var selectedExistingWorkspace: Project?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI reasoning
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue.gradient)
                        .symbolEffect(.pulse)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.suggestedType.emoji)
                            .font(.title2)
                        Text(context.suggestedType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Workspace Suggestion")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("I've analyzed our conversation about \(context.conversationSummary). This seems like it could benefit from organized workspace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            // Main content
            VStack(spacing: 24) {
                // Intelligent workspace suggestion
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("💡 Suggested Workspace")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if !showCustomization {
                                Button("Customize") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showCustomization = true
                                        customTitle = context.intelligentTitle
                                        customDescription = context.intelligentDescription
                                    }
                                }
                                .font(.caption)
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        if showCustomization {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workspace Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("Enter workspace name", text: $customTitle)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("Enter description", text: $customDescription, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(2...4)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(context.intelligentTitle)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Text(context.intelligentDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.05))
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Existing workspace suggestions (if any)
                    if !context.existingWorkspaceSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Or add to existing workspace:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            ForEach(context.existingWorkspaceSuggestions, id: \.id) { workspace in
                                Button(action: {
                                    selectedExistingWorkspace = workspace
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workspace.title)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            if !workspace.description.isEmpty {
                                                Text(workspace.description)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(2)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedExistingWorkspace?.id == workspace.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedExistingWorkspace?.id == workspace.id ? Color.blue.opacity(0.1) : Color.clear)
                                            .stroke(selectedExistingWorkspace?.id == workspace.id ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Conversation preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This conversation includes:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            Label("\(context.messages.count) messages", systemImage: "message")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Label("Started recently", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                if selectedExistingWorkspace == nil {
                    Text("Future related conversations will be automatically suggested for this workspace")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                
                HStack(spacing: 12) {
                    Button("Not Now") {
                        threadManager.dismissWorkspaceCreation()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    if let existingWorkspace = selectedExistingWorkspace {
                        Button("Add to \(existingWorkspace.title)") {
                            threadManager.assignToExistingWorkspace(from: context, workspace: existingWorkspace)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Button("Create Workspace") {
                            if showCustomization {
                                threadManager.createIntelligentWorkspace(
                                    from: context,
                                    customTitle: customTitle.isEmpty ? nil : customTitle,
                                    customDescription: customDescription.isEmpty ? nil : customDescription
                                )
                            } else {
                                threadManager.createIntelligentWorkspace(from: context)
                            }
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 520, height: selectedExistingWorkspace != nil ? 580 : (showCustomization ? 620 : 520))
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            // Clear any existing selection
            selectedExistingWorkspace = nil
        }
    }
}
