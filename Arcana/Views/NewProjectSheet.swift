//
// NewProjectSheet.swift
// Arcana - Intelligent Workspace Creation
// Created by Spectral Labs
//
// FOLDER: Arcana/Views/
// DEPENDENCIES: WorkspaceManager.swift, UnifiedTypes.swift

import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var workspaceManager = WorkspaceManager.shared
    
    // Form State
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var detectedType: WorkspaceManager.WorkspaceType = .general
    @State private var intelligentDescription: String = ""
    
    // UI State
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var descriptionFieldFocused: Bool
    @State private var showTypeSelection = false
    @State private var isCreating = false
    
    // Callback
    let onProjectCreated: (title: String, description: String) -> Void
    
    var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isCreating
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: detectedType.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(detectedType.color)
                        
                        Text("Create New Workspace")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("AI will help optimize your workspace for \(detectedType.displayName.lowercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
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
                                            .background(.quaternary)
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(height: 32)
                            }
                        }
                        
                        // Workspace Type Detection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Detected Type")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button("Change") {
                                    showTypeSelection.toggle()
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: detectedType.icon)
                                    .foregroundStyle(detectedType.color)
                                
                                Text(detectedType.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if !title.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(12)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Description
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
                                    .foregroundStyle(.blue)
                                }
                            }
                            
                            TextField("Describe your workspace purpose and goals...", text: $description, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .focused($descriptionFieldFocused)
                                .lineLimit(3...6)
                            
                            // AI Suggestion Preview
                            if !intelligentDescription.isEmpty && description.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Suggestion:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(intelligentDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                        .background(.quaternary)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
            .background(.ultraThinMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(!canCreate)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            titleFieldFocused = true
        }
        .sheet(isPresented: $showTypeSelection) {
            WorkspaceTypeSelectionSheet(selectedType: $detectedType)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleTitleChange() {
        // Generate smart suggestions for workspace types
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
        guard canCreate else { return }
        
        isCreating = true
        
        let finalDescription = description.isEmpty ? intelligentDescription : description
        onProjectCreated(title.trimmingCharacters(in: .whitespacesAndNewlines), finalDescription)
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct WorkspaceTypeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: WorkspaceManager.WorkspaceType
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(WorkspaceManager.WorkspaceType.allCases) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundStyle(type.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.headline)
                            
                            Text(typeDescription(for: type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedType = type
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func typeDescription(for type: WorkspaceManager.WorkspaceType) -> String {
        switch type {
        case .general:
            return "For general conversations and planning"
        case .code:
            return "Optimized for programming and technical work"
        case .creative:
            return "Perfect for writing and creative projects"
        case .research:
            return "Designed for analysis and investigation"
        }
    }
}

#Preview {
    NewProjectSheet { title, description in
        print("Created: \(title) - \(description)")
    }
}
