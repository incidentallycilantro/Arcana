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
    }
    
    private init() {
        loadSampleWorkspaces()
    }
    
    private func loadSampleWorkspaces() {
        workspaces = [
            Project(title: "Personal Assistant", description: "General purpose conversations and tasks"),
            Project(title: "Code Review", description: "Software development and code analysis"),
            Project(title: "Creative Writing", description: "Stories, poems, and creative content")
        ]
    }
    
    @discardableResult
    func createWorkspace(title: String, description: String) -> Project {
        let newWorkspace = Project(title: title, description: description)
        
        // Detect workspace type for intelligent features
        let detectedType = detectWorkspaceType(title: title, description: description)
        print("🧠✨ Detected: \(detectedType.displayName.uppercased()) workspace - \(detectedType.emoji)")
        
        // Insert at the beginning of the array (top of list)
        workspaces.insert(newWorkspace, at: 0)
        
        // Force UI update and selection
        DispatchQueue.main.async {
            self.selectedWorkspace = newWorkspace
            print("📍 New workspace '\(title)' created and selected at position 0")
            print("📋 Total workspaces: \(self.workspaces.count)")
            print("📋 Workspace order: \(self.workspaces.map(\.title))")
        }
        
        return newWorkspace
    }
    
    func togglePin(for workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].isPinned.toggle()
            workspaces[index].updateModified()
            
            // Resort: pinned items first, then by modification date
            workspaces.sort { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned
                }
                return lhs.lastModified > rhs.lastModified
            }
            
            // Update selection if needed
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = workspaces[workspaces.firstIndex(where: { $0.id == workspace.id })!]
            }
        }
    }
    
    func duplicateWorkspace(_ workspace: Project) {
        var newWorkspace = workspace
        newWorkspace.title += " Copy"
        newWorkspace.updateModified()
        workspaces.insert(newWorkspace, at: 0)
    }
    
    func deleteWorkspace(_ workspace: Project) {
        workspaces.removeAll { $0.id == workspace.id }
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = workspaces.first
        }
    }
    
    func getWorkspaceType(for workspace: Project) -> WorkspaceType {
        return detectWorkspaceType(title: workspace.title, description: workspace.description)
    }
    
    private func detectWorkspaceType(title: String, description: String) -> WorkspaceType {
        let combinedText = "\(title) \(description)".lowercased()
        
        // Code-related keywords
        let codeKeywords = ["code", "programming", "development", "swift", "python", "javascript", "api", "debug", "software", "algorithm", "framework", "repository", "github", "coding", "technical", "architecture", "database", "backend", "frontend", "mobile", "web", "ios", "android", "react", "node", "java", "c++", "html", "css", "sql", "devops", "engineering"]
        
        // Creative keywords
        let creativeKeywords = ["creative", "writing", "story", "novel", "poem", "poetry", "art", "design", "music", "screenplay", "character", "plot", "narrative", "fiction", "blog", "content", "marketing", "copy", "brand", "creative", "artistic", "illustration", "graphics", "video", "animation", "photography"]
        
        // Research keywords
        let researchKeywords = ["research", "analysis", "study", "report", "data", "market", "survey", "academic", "paper", "thesis", "investigation", "findings", "statistics", "trends", "insights", "analytics", "business", "strategy", "competitive", "industry", "market", "economics", "finance", "science", "methodology", "hypothesis"]
        
        // Count keyword matches
        let codeMatches = codeKeywords.filter { combinedText.contains($0) }.count
        let creativeMatches = creativeKeywords.filter { combinedText.contains($0) }.count
        let researchMatches = researchKeywords.filter { combinedText.contains($0) }.count
        
        // Determine the highest scoring category
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
}
