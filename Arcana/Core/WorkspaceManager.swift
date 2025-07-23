// WorkspaceManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()
    
    @Published var workspaces: [Project] = Project.sampleProjects
    @Published var selectedWorkspace: Project?
    
    private init() {}
    
    // MARK: - Workspace Management
    
    func createWorkspace(title: String, description: String = "") {
        let newWorkspace = Project(title: title, description: description)
        
        // Add to the beginning of the array for immediate visibility
        workspaces.insert(newWorkspace, at: 0)
        selectedWorkspace = newWorkspace
        
        print("✅ Created workspace '\(title)' at position 0, total workspaces: \(workspaces.count)")
        
        // TODO: Phase 2 - Analyze title/description for intelligent model selection
        analyzeWorkspaceType(newWorkspace)
    }
    
    func deleteWorkspace(_ workspace: Project) {
        workspaces.removeAll { $0.id == workspace.id }
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = nil
        }
    }
    
    func duplicateWorkspace(_ workspace: Project) {
        var newWorkspace = workspace
        newWorkspace.title += " Copy"
        // Insert the duplicate right after the original
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces.insert(newWorkspace, at: index + 1)
        } else {
            workspaces.insert(newWorkspace, at: 0)
        }
    }
    
    func togglePin(for workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].isPinned.toggle()
            workspaces[index].updateModified()
            
            // Update selected workspace if it's the one being pinned
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = workspaces[index]
            }
        }
    }
    
    // MARK: - Intelligent Analysis (Phase 2)
    
    private func analyzeWorkspaceType(_ workspace: Project) {
        // TODO: Implement intelligent workspace type detection
        // This will analyze the title and description to:
        // 1. Suggest optimal model
        // 2. Set up workspace-specific defaults
        // 3. Enable relevant adaptive UI features
        
        let title = workspace.title.lowercased()
        let description = workspace.description.lowercased()
        
        print("🔍 Analyzing workspace: '\(workspace.title)'")
        
        // Simple keyword analysis for now
        if title.contains("code") || title.contains("programming") || title.contains("swift") ||
           title.contains("development") || description.contains("development") ||
           title.contains("review") || title.contains("debug") {
            print("🧠✨ Detected: CODE workspace - Optimizing for development tasks")
            // TODO: Set code-optimized model and preferences
        } else if title.contains("creative") || title.contains("writing") || title.contains("story") ||
                  title.contains("poem") || description.contains("story") || description.contains("creative") {
            print("🧠🎨 Detected: CREATIVE workspace - Optimizing for creative tasks")
            // TODO: Set creative-optimized model and preferences
        } else if title.contains("research") || title.contains("analysis") || title.contains("study") ||
                  title.contains("market") || description.contains("research") || description.contains("analysis") {
            print("🧠📊 Detected: RESEARCH workspace - Optimizing for analytical tasks")
            // TODO: Set research-optimized model and preferences
        } else {
            print("🧠💼 Detected: GENERAL workspace - Using balanced configuration")
        }
    }
    
    // MARK: - Filtered and Sorted Workspaces
    
    func filteredWorkspaces(searchText: String) -> [Project] {
        let filtered = searchText.isEmpty ? workspaces : workspaces.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
        
        print("🔍 Filtering \(workspaces.count) workspaces, filtered to \(filtered.count)")
        
        // Simple sort: pinned first, then maintain the order from the array (newest first)
        let sorted = filtered.sorted { workspace1, workspace2 in
            if workspace1.isPinned && !workspace2.isPinned {
                return true
            } else if !workspace1.isPinned && workspace2.isPinned {
                return false
            } else {
                // Maintain insertion order - find index in original array
                let index1 = workspaces.firstIndex(where: { $0.id == workspace1.id }) ?? workspaces.count
                let index2 = workspaces.firstIndex(where: { $0.id == workspace2.id }) ?? workspaces.count
                return index1 < index2
            }
        }
        
        print("📋 First workspace in sorted list: \(sorted.first?.title ?? "None")")
        return sorted
    }
}
