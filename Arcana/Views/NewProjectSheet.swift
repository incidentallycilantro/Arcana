// NewProjectSheet.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, ChatMessage.swift, WorkspaceManager.swift

import SwiftUI

struct NewProjectSheet: View {
    let onProjectCreated: ((title: String, description: String)) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var showingSuggestions = false
    @State private var selectedSuggestion: String? = nil
    @State private var detectedType: WorkspaceManager.WorkspaceType = .general
    @State private var intelligentDescription = ""
    
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var descriptionFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with intelligent type detection
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.blue.gradient)
                        .symbolEffect(.pulse)
                    
                    if !title.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(detectedType.emoji)
                                .font(.title2)
                            Text(detectedType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                VStack(spacing: 4) {
                    Text("Create New Workspace")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !title.isEmpty {
                        Text("Arcana detected: \(detectedType.displayName) workspace")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .transition(.opacity)
                    } else {
                        Text("Design a dedicated space for focused AI collaboration")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            // Main content with intelligent suggestions
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workspace Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., Creative Writing, Code Review, Market Research", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($titleFieldFocused)
                        .onChange(of: title) {
                            handleTitleChange()
                        }
                        .onSubmit {
                            if !title.isEmpty && description.isEmpty && !intelligentDescription.isEmpty {
                                description = intelligentDescription
                                descriptionFieldFocused = true
                            } else if canCreate {
                                createProject()
                            }
                        }
                    
                    // Smart suggestions appear as you type
                    if !workspaceManager.smartSuggestions.isEmpty && !title.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(workspaceManager.smartSuggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        title = suggestion
                                        handleTitleChange()
                                        if description.isEmpty && !intelligentDescription.isEmpty {
                                            description = intelligentDescription
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if !intelligentDescription.isEmpty && description.isEmpty {
                            Button("Use AI suggestion") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    description = intelligentDescription
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if !intelligentDescription.isEmpty && description.isEmpty {
                        Text("💡 \(intelligentDescription)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.vertical, 4)
                            .transition(.opacity)
                    }
                    
                    TextField("Describe what you'll use this workspace for...", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                        .focused($descriptionFieldFocused)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            
            Spacer()
            
            // Action buttons with intelligent suggestions
            VStack(spacing: 12) {
                if !title.isEmpty && detectedType != .general {
                    Text("Arcana will optimize this workspace for \(detectedType.displayName.lowercased()) work")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Create Workspace") {
                        createProject()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canCreate)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(width: 520, height: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            titleFieldFocused = true
        }
    }
    
    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleTitleChange() {
        // Generate smart suggestions as user types
        workspaceManager.generateSmartSuggestions(for: title)
        
        // Detect workspace type
        let newType = detectWorkspaceType(title: title, description: description)
        if newType != detectedType {
            withAnimation(.easeInOut(duration: 0.3)) {
                detectedType = newType
            }
        }
        
        // Generate intelligent description suggestion
        if !title.isEmpty {
            intelligentDescription = generateIntelligentDescription(title: title, type: detectedType)
        } else {
            intelligentDescription = ""
        }
    }
    
    private func detectWorkspaceType(title: String, description: String) -> WorkspaceManager.WorkspaceType {
        let combinedText = "\(title) \(description)".lowercased()
        
        // Enhanced detection with better keyword matching
        let codeKeywords = ["code", "programming", "development", "swift", "python", "javascript", "api", "debug", "software", "algorithm", "framework", "app", "system", "technical", "engineering"]
        let creativeKeywords = ["creative", "writing", "story", "novel", "poem", "art", "design", "content", "blog", "creative", "brainstorm", "idea", "marketing", "copy", "brand"]
        let researchKeywords = ["research", "analysis", "study", "report", "data", "market", "survey", "academic", "investigation", "findings", "business", "strategy", "industry"]
        
        let codeMatches = codeKeywords.filter { combinedText.contains($0) }.count
        let creativeMatches = creativeKeywords.filter { combinedText.contains($0) }.count
        let researchMatches = researchKeywords.filter { combinedText.contains($0) }.count
        
        let maxMatches = max(codeMatches, creativeMatches, researchMatches)
        
        if maxMatches == 0 {
            return .general
        } else if codeMatches == maxMatches {
            return .code
        } else if creativeMatches == maxMatches {
            return .creative
        } else {
            return .research
        }
    }
    
    private func generateIntelligentDescription(title: String, type: WorkspaceManager.WorkspaceType) -> String {
        let titleLower = title.lowercased()
        
        switch type {
        case .code:
            if titleLower.contains("review") {
                return "Development workspace for code review, debugging, and technical discussions"
            } else if titleLower.contains("project") || titleLower.contains("app") {
                return "Development workspace for building, testing, and documenting software projects"
            } else {
                return "Development workspace for coding, debugging, and technical problem-solving"
            }
            
        case .creative:
            if titleLower.contains("writing") {
                return "Creative workspace for writing, editing, and storytelling collaboration"
            } else if titleLower.contains("content") || titleLower.contains("marketing") {
                return "Creative workspace for content creation, copywriting, and brand development"
            } else {
                return "Creative workspace for brainstorming, artistic exploration, and creative projects"
            }
            
        case .research:
            if titleLower.contains("market") {
                return "Research workspace for market analysis, competitive intelligence, and business insights"
            } else if titleLower.contains("academic") || titleLower.contains("study") {
                return "Research workspace for academic investigation, data analysis, and scholarly work"
            } else {
                return "Research workspace for investigation, analysis, and evidence-based exploration"
            }
            
        case .general:
            return "General workspace for discussions, planning, and collaborative thinking"
        }
    }
    
    private func createProject() {
        let finalDescription = description.isEmpty ? intelligentDescription : description
        onProjectCreated((title: title, description: finalDescription))
        dismiss()
    }
}

#Preview {
    NewProjectSheet { title, description in
        print("Created: \(title) - \(description)")
    }
}
