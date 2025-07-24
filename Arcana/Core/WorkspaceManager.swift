// WorkspaceManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()
    
    @Published var workspaces: [Project] = []
    @Published var selectedWorkspace: Project?
    @Published var showNewWorkspaceSheet = false
    @Published var smartSuggestions: [String] = []
    @Published var isLoadingWorkspaces = false
    
    // Invisible intelligence state
    private var userPatterns: WorkspacePatterns = WorkspacePatterns()
    private let persistenceController = WorkspacePersistenceController()
    
    enum WorkspaceType {
        case code
        case creative
        case research
        case general
        
        var displayName: String {
            switch self {
            case .code: return "Code"
            case .creative: return "Creative"
            case .research: return "Research"
            case .general: return "General"
            }
        }
        
        var emoji: String {
            switch self {
            case .code: return "💻"
            case .creative: return "🎨"
            case .research: return "📊"
            case .general: return "💼"
            }
        }
        
        var intelligentPrompts: [String] {
            switch self {
            case .code:
                return [
                    "I notice this looks like a coding workspace. I can help with code review, debugging, and documentation.",
                    "This seems like a development project. I'm ready to assist with programming challenges and best practices.",
                    "I can see this is code-related. I'll optimize my responses for technical discussions and problem-solving."
                ]
            case .creative:
                return [
                    "This looks like a creative project! I can help with writing, brainstorming, and creative development.",
                    "I notice you're working on something creative. I'll focus on helping with tone, style, and creative flow.",
                    "This seems like creative work. I'm here to help with writing, editing, and creative ideation."
                ]
            case .research:
                return [
                    "This appears to be research-focused. I can help with analysis, fact-checking, and organizing findings.",
                    "I notice this is research work. I'm ready to assist with data analysis and evidence evaluation.",
                    "This seems like a research project. I'll focus on helping with methodology and critical analysis."
                ]
            case .general:
                return [
                    "I'm ready to help with whatever you're working on. Just start a conversation and I'll adapt to your needs.",
                    "This workspace is ready for any type of discussion. I'll adjust my responses based on what you need.",
                    "I'll adapt to whatever you're working on here. Feel free to start with any question or topic."
                ]
            }
        }
    }
    
    private init() {
        loadWorkspaces()
        analyzeUserPatterns()
    }
    
    // MARK: - Enhanced Workspace Creation with AI Suggestions
    
    func generateSmartSuggestions(for input: String) {
        guard input.count > 3 else {
            smartSuggestions = []
            return
        }
        
        let detectedType = detectWorkspaceType(title: input, description: "")
        let suggestions = generateIntelligentSuggestions(for: input, type: detectedType)
        
        DispatchQueue.main.async {
            self.smartSuggestions = suggestions
        }
    }
    
    private func generateIntelligentSuggestions(for input: String, type: WorkspaceType) -> [String] {
        var suggestions: [String] = []
        
        // Base suggestion with enhanced name
        let enhancedName = enhanceWorkspaceName(input, type: type)
        if enhancedName != input {
            suggestions.append(enhancedName)
        }
        
        // Type-specific intelligent suggestions
        switch type {
        case .code:
            suggestions.append(contentsOf: [
                "\(input) - Development",
                "\(input) Code Review",
                "\(input) Project Analysis"
            ])
        case .creative:
            suggestions.append(contentsOf: [
                "\(input) - Creative Writing",
                "\(input) Story Development",
                "\(input) Content Creation"
            ])
        case .research:
            suggestions.append(contentsOf: [
                "\(input) Research Project",
                "\(input) - Analysis",
                "\(input) Investigation"
            ])
        case .general:
            suggestions.append(contentsOf: [
                "\(input) Planning",
                "\(input) Discussion",
                "\(input) Workspace"
            ])
        }
        
        // Add suggestions based on user patterns
        if userPatterns.hasPattern(for: type) {
            let patternSuggestions = userPatterns.getSuggestions(for: input, type: type)
            suggestions.append(contentsOf: patternSuggestions)
        }
        
        return Array(Set(suggestions)).prefix(4).map { String($0) }
    }
    
    private func enhanceWorkspaceName(_ name: String, type: WorkspaceType) -> String {
        let lowercased = name.lowercased()
        
        switch type {
        case .code:
            if !lowercased.contains("project") && !lowercased.contains("dev") && !lowercased.contains("code") {
                return "\(name) Project"
            }
        case .creative:
            if !lowercased.contains("writing") && !lowercased.contains("creative") && !lowercased.contains("story") {
                return "\(name) Writing"
            }
        case .research:
            if !lowercased.contains("research") && !lowercased.contains("study") && !lowercased.contains("analysis") {
                return "\(name) Research"
            }
        case .general:
            break
        }
        
        return name
    }
    
    @discardableResult
    func createWorkspace(title: String, description: String) -> Project {
        var newWorkspace = Project(title: title, description: description)
        
        // Invisible intelligence: detect type and learn patterns
        let detectedType = detectWorkspaceType(title: title, description: description)
        userPatterns.recordWorkspaceCreation(title: title, type: detectedType)
        
        // Auto-generate description if empty
        let finalDescription = description.isEmpty ? generateIntelligentDescription(title, type: detectedType) : description
        newWorkspace.description = finalDescription
        
        // Insert with intelligent positioning
        let insertPosition = getIntelligentInsertPosition(for: newWorkspace)
        workspaces.insert(newWorkspace, at: insertPosition)
        
        // Auto-save invisibly
        persistenceController.saveWorkspace(newWorkspace)
        
        // Force UI update and selection
        DispatchQueue.main.async {
            self.selectedWorkspace = newWorkspace
            print("🧠✨ Created \(detectedType.displayName.uppercased()) workspace - \(detectedType.emoji) '\(title)'")
        }
        
        return newWorkspace
    }
    
    private func generateIntelligentDescription(_ title: String, type: WorkspaceType) -> String {
        switch type {
        case .code:
            return "Development workspace for coding, debugging, and technical discussions"
        case .creative:
            return "Creative workspace for writing, brainstorming, and artistic exploration"
        case .research:
            return "Research workspace for analysis, investigation, and fact-finding"
        case .general:
            return "General workspace for discussions and collaborative thinking"
        }
    }
    
    private func getIntelligentInsertPosition(for workspace: Project) -> Int {
        // Pinned workspaces always stay at top
        let pinnedCount = workspaces.prefix(while: { $0.isPinned }).count
        
        // Insert new workspaces right after pinned ones
        return pinnedCount
    }
    
    // MARK: - Enhanced Workspace Management
    
    func togglePin(for workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].isPinned.toggle()
            workspaces[index].updateModified()
            
            // Intelligent reorganization
            organizeWorkspacesIntelligently()
            
            // Save changes invisibly
            persistenceController.saveWorkspace(workspaces[index])
            
            // Update selection if needed
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = workspaces[workspaces.firstIndex(where: { $0.id == workspace.id })!]
            }
        }
    }
    
    func duplicateWorkspace(_ workspace: Project) {
        var newWorkspace = workspace
        newWorkspace.title = generateSmartDuplicateName(workspace.title)
        newWorkspace.updateModified()
        
        let insertPosition = getIntelligentInsertPosition(for: newWorkspace)
        workspaces.insert(newWorkspace, at: insertPosition)
        
        // Save new workspace
        persistenceController.saveWorkspace(newWorkspace)
        
        // Learn from duplication pattern
        let type = getWorkspaceType(for: workspace)
        userPatterns.recordWorkspaceDuplication(originalTitle: workspace.title, type: type)
    }
    
    private func generateSmartDuplicateName(_ originalTitle: String) -> String {
        let baseName = originalTitle.replacingOccurrences(of: " Copy", with: "")
        let existingCopies = workspaces.filter { $0.title.hasPrefix(baseName) && $0.title.contains("Copy") }
        
        if existingCopies.isEmpty {
            return "\(baseName) Copy"
        } else {
            let copyNumber = existingCopies.count + 1
            return "\(baseName) Copy \(copyNumber)"
        }
    }
    
    func deleteWorkspace(_ workspace: Project) {
        // Learn from deletion (maybe this type/pattern isn't useful)
        let type = getWorkspaceType(for: workspace)
        userPatterns.recordWorkspaceDeletion(title: workspace.title, type: type)
        
        // Remove from persistence
        persistenceController.deleteWorkspace(workspace)
        
        // Remove from array
        workspaces.removeAll { $0.id == workspace.id }
        
        // Smart selection of next workspace
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = getIntelligentNextSelection()
        }
    }
    
    private func getIntelligentNextSelection() -> Project? {
        // Prefer pinned workspaces
        if let pinnedWorkspace = workspaces.first(where: { $0.isPinned }) {
            return pinnedWorkspace
        }
        
        // Otherwise, most recently modified
        return workspaces.max(by: { $0.lastModified < $1.lastModified })
    }
    
    // MARK: - Invisible Organization
    
    private func organizeWorkspacesIntelligently() {
        workspaces.sort { lhs, rhs in
            // Pinned items always first
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            
            // Then by frequency of use (if we have that data)
            let lhsScore = userPatterns.getUsageScore(for: lhs.title)
            let rhsScore = userPatterns.getUsageScore(for: rhs.title)
            
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            
            // Finally by modification date
            return lhs.lastModified > rhs.lastModified
        }
    }
    
    // MARK: - Persistent Data Management
    
    private func loadWorkspaces() {
        isLoadingWorkspaces = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedWorkspaces = self.persistenceController.loadWorkspaces()
            
            DispatchQueue.main.async {
                if loadedWorkspaces.isEmpty {
                    // First time setup - create sample workspaces
                    self.createFirstTimeWorkspaces()
                } else {
                    self.workspaces = loadedWorkspaces
                    self.organizeWorkspacesIntelligently()
                    
                    // Auto-select the most appropriate workspace
                    if let intelligentSelection = self.getIntelligentNextSelection() {
                        self.selectedWorkspace = intelligentSelection
                    }
                }
                
                self.isLoadingWorkspaces = false
                print("📂 Loaded \(self.workspaces.count) workspaces")
            }
        }
    }
    
    private func createFirstTimeWorkspaces() {
        let sampleWorkspaces = [
            ("Personal Assistant", "General purpose conversations and daily tasks", WorkspaceType.general),
            ("Code Review", "Software development and code analysis", WorkspaceType.code),
            ("Creative Writing", "Stories, poems, and creative content", WorkspaceType.creative)
        ]
        
        for (title, description, type) in sampleWorkspaces {
            let workspace = Project(title: title, description: description)
            workspaces.append(workspace)
            persistenceController.saveWorkspace(workspace)
            
            // Record pattern for future learning
            userPatterns.recordWorkspaceCreation(title: title, type: type)
        }
        
        // Select the first workspace
        selectedWorkspace = workspaces.first
    }
    
    private func analyzeUserPatterns() {
        // This would analyze historical usage, but for now we start fresh
        userPatterns.initialize()
    }
    
    // MARK: - Public Interface
    
    func getWorkspaceType(for workspace: Project) -> WorkspaceType {
        return detectWorkspaceType(title: workspace.title, description: workspace.description)
    }
    
    func getIntelligentPrompt(for workspace: Project) -> String {
        let type = getWorkspaceType(for: workspace)
        return type.intelligentPrompts.randomElement() ?? "I'm ready to help with whatever you're working on."
    }
    
    // MARK: - Type Detection (Enhanced)
    
    private func detectWorkspaceType(title: String, description: String) -> WorkspaceType {
        let combinedText = "\(title) \(description)".lowercased()
        
        // Enhanced keyword detection with scoring
        let codeKeywords = ["code", "programming", "development", "swift", "python", "javascript", "api", "debug", "software", "algorithm", "framework", "repository", "github", "coding", "technical", "architecture", "database", "backend", "frontend", "mobile", "web", "ios", "android", "react", "node", "java", "c++", "html", "css", "sql", "devops", "engineering", "app", "system", "server", "client", "ui", "ux", "design", "prototype"]
        
        let creativeKeywords = ["creative", "writing", "story", "novel", "poem", "poetry", "art", "design", "music", "screenplay", "character", "plot", "narrative", "fiction", "blog", "content", "marketing", "copy", "brand", "artistic", "illustration", "graphics", "video", "animation", "photography", "creative", "brainstorm", "idea", "concept", "vision", "imagination", "inspiration"]
        
        let researchKeywords = ["research", "analysis", "study", "report", "data", "market", "survey", "academic", "paper", "thesis", "investigation", "findings", "statistics", "trends", "insights", "analytics", "business", "strategy", "competitive", "industry", "economics", "finance", "science", "methodology", "hypothesis", "experiment", "evidence", "documentation", "review", "evaluation"]
        
        // Advanced scoring with word importance weighting
        let codeScore = calculateTypeScore(combinedText, keywords: codeKeywords)
        let creativeScore = calculateTypeScore(combinedText, keywords: creativeKeywords)
        let researchScore = calculateTypeScore(combinedText, keywords: researchKeywords)
        
        let maxScore = max(codeScore, creativeScore, researchScore)
        
        if maxScore < 1 {
            return .general
        } else if codeScore == maxScore {
            return .code
        } else if creativeScore == maxScore {
            return .creative
        } else {
            return .research
        }
    }
    
    private func calculateTypeScore(_ text: String, keywords: [String]) -> Double {
        var score = 0.0
        
        for keyword in keywords {
            if text.contains(keyword) {
                // Weight keywords by length (longer = more specific)
                let weight = Double(keyword.count) / 5.0
                score += weight
                
                // Bonus for exact word matches
                if text.components(separatedBy: .whitespacesAndNewlines).contains(keyword) {
                    score += weight * 0.5
                }
            }
        }
        
        return score
    }
}

// MARK: - User Pattern Learning System

private class WorkspacePatterns {
    private var creationPatterns: [WorkspaceManager.WorkspaceType: [String]] = [:]
    private var usageScores: [String: Double] = [:]
    private var typeFrequency: [WorkspaceManager.WorkspaceType: Int] = [:]
    
    func initialize() {
        // Initialize with empty patterns - will learn over time
        creationPatterns = [
            .code: [],
            .creative: [],
            .research: [],
            .general: []
        ]
        
        typeFrequency = [
            .code: 0,
            .creative: 0,
            .research: 0,
            .general: 0
        ]
    }
    
    func recordWorkspaceCreation(title: String, type: WorkspaceManager.WorkspaceType) {
        // Learn from naming patterns
        creationPatterns[type, default: []].append(title)
        typeFrequency[type, default: 0] += 1
        
        // Track usage
        usageScores[title] = 1.0
    }
    
    func recordWorkspaceDuplication(originalTitle: String, type: WorkspaceManager.WorkspaceType) {
        // Boost score for duplicated workspaces (they must be useful)
        usageScores[originalTitle, default: 0] += 2.0
        typeFrequency[type, default: 0] += 1
    }
    
    func recordWorkspaceDeletion(title: String, type: WorkspaceManager.WorkspaceType) {
        // Reduce score for deleted workspaces
        usageScores[title, default: 0] *= 0.5
    }
    
    func hasPattern(for type: WorkspaceManager.WorkspaceType) -> Bool {
        return (creationPatterns[type]?.count ?? 0) > 2
    }
    
    func getSuggestions(for input: String, type: WorkspaceManager.WorkspaceType) -> [String] {
        guard let patterns = creationPatterns[type], patterns.count > 1 else { return [] }
        
        // Find similar patterns
        return patterns.compactMap { pattern in
            if pattern.localizedCaseInsensitiveContains(input) && pattern != input {
                return pattern
            }
            return nil
        }.prefix(2).map { String($0) }
    }
    
    func getUsageScore(for title: String) -> Double {
        return usageScores[title, default: 0]
    }
}
