//
// WorkspaceManager.swift
// Arcana - Unified Workspace Management System
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
// DEPENDENCIES: UnifiedTypes.swift, Project.swift

import Foundation
import SwiftUI
import Combine

// MARK: - Main Workspace Manager

@MainActor
class WorkspaceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = WorkspaceManager()
    
    // MARK: - Published Properties
    @Published var workspaces: [Project] = []
    @Published var selectedWorkspace: Project?
    @Published var showNewWorkspaceSheet = false
    @Published var showStorageInfoSheet = false
    
    // MARK: - Workspace Intelligence
    @Published var intelligenceEngine = IntelligenceEngine.shared
    @Published var isAnalyzingWorkspace = false
    @Published var workspaceRecommendations: [WorkspaceRecommendation] = []
    
    // MARK: - Smart Suggestions (ADDED: Missing properties)
    @Published var smartSuggestions: [String] = []
    @Published var isGeneratingSuggestions = false
    
    // MARK: - Storage Information
    @Published var totalStorageUsed: Int64 = 0
    @Published var workspaceCount: Int = 0
    @Published var lastBackupDate: Date?
    
    // MARK: - Private Properties
    private let persistenceController = WorkspacePersistenceController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadWorkspaces()
        setupStorageMonitoring()
        
        // Monitor workspace changes for intelligent recommendations
        $workspaces
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateWorkspaceRecommendations()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Smart Suggestions (ADDED: Missing methods)
    
    func generateSmartSuggestions(for title: String) {
        guard !title.isEmpty else {
            smartSuggestions = []
            return
        }
        
        isGeneratingSuggestions = true
        
        Task {
            let suggestions = await generateIntelligentSuggestions(for: title)
            await MainActor.run {
                self.smartSuggestions = suggestions
                self.isGeneratingSuggestions = false
            }
        }
    }
    
    private func generateIntelligentSuggestions(for title: String) async -> [String] {
        var suggestions: [String] = []
        let titleLower = title.lowercased()
        
        // Code-related suggestions
        if titleLower.contains("code") || titleLower.contains("dev") || titleLower.contains("program") {
            suggestions.append(contentsOf: [
                "Swift iOS Development",
                "Python Data Analysis",
                "JavaScript Web App",
                "API Integration Project",
                "Code Review Session",
                "Algorithm Implementation"
            ])
        }
        
        // Creative suggestions
        if titleLower.contains("creat") || titleLower.contains("writ") || titleLower.contains("story") {
            suggestions.append(contentsOf: [
                "Creative Writing Project",
                "Blog Content Creation",
                "Marketing Campaign Ideas",
                "Story Development",
                "Content Strategy Planning",
                "Brand Voice Development"
            ])
        }
        
        // Research suggestions
        if titleLower.contains("research") || titleLower.contains("analysis") || titleLower.contains("study") {
            suggestions.append(contentsOf: [
                "Market Research Analysis",
                "Competitive Intelligence",
                "User Experience Research",
                "Data Analysis Project",
                "Industry Trend Study",
                "Customer Insights Research"
            ])
        }
        
        // General suggestions if no specific category matches
        if suggestions.isEmpty {
            suggestions.append(contentsOf: [
                "General Project Planning",
                "Problem Solving Session",
                "Learning & Development",
                "Strategy Discussion",
                "Innovation Workshop",
                "Team Collaboration"
            ])
        }
        
        // Filter suggestions based on title similarity and limit to 6
        return suggestions
            .filter { suggestion in
                let suggestionWords = suggestion.lowercased().components(separatedBy: .whitespaces)
                let titleWords = titleLower.components(separatedBy: .whitespaces)
                return suggestionWords.contains { titleWords.contains($0) } ||
                       titleWords.contains { suggestionWords.contains($0) }
            }
            .prefix(6)
            .map { $0 }
    }
    
    // MARK: - Workspace CRUD Operations
    
    func createWorkspace(title: String, description: String = "", type: WorkspaceType? = nil) {
        let workspace = Project(title: title, description: description)
        
        workspaces.insert(workspace, at: 0)
        selectedWorkspace = workspace
        saveWorkspace(workspace)
        
        updateStorageInfo()
    }
    
    func duplicateWorkspace(_ workspace: Project) {
        let duplicate = Project(
            title: "\(workspace.title) Copy",
            description: workspace.description
        )
        
        workspaces.insert(duplicate, at: workspaces.firstIndex(of: workspace)! + 1)
        saveWorkspace(duplicate)
        updateStorageInfo()
    }
    
    func deleteWorkspace(_ workspace: Project) {
        workspaces.removeAll { $0.id == workspace.id }
        
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = workspaces.first
        }
        
        persistenceController.deleteWorkspace(workspace.id)
        updateStorageInfo()
    }
    
    func updateWorkspace(_ workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
            saveWorkspace(workspace)
        }
    }
    
    // MARK: - Workspace Intelligence
    
    private func updateWorkspaceRecommendations() async {
        isAnalyzingWorkspace = true
        
        let recommendations = await intelligenceEngine.generateWorkspaceRecommendations(
            existingWorkspaces: workspaces
        )
        
        await MainActor.run {
            self.workspaceRecommendations = recommendations
            self.isAnalyzingWorkspace = false
        }
    }
    
    // MARK: - Storage Management
    
    private func setupStorageMonitoring() {
        updateStorageInfo()
        
        // Update storage info every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateStorageInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateStorageInfo() {
        workspaceCount = workspaces.count
        totalStorageUsed = calculateTotalStorageUsed()
        lastBackupDate = getLastBackupDate()
    }
    
    private func calculateTotalStorageUsed() -> Int64 {
        // Calculate storage used by all workspaces
        // This would normally read from file system
        return Int64(workspaces.count * 1024 * 1024) // Placeholder: 1MB per workspace
    }
    
    private func getLastBackupDate() -> Date? {
        // This would normally check actual backup files
        return UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }
    
    // MARK: - Persistence
    
    private func loadWorkspaces() {
        workspaces = persistenceController.loadWorkspaces()
        updateStorageInfo()
    }
    
    private func saveWorkspace(_ workspace: Project) {
        persistenceController.saveWorkspace(workspace)
    }
    
    func saveWorkspaceFromExternal(_ workspace: Project) {
        // Called from external components like ThreadManager
        saveWorkspace(workspace)
    }
    
    // MARK: - Workspace Types
    
    enum WorkspaceType: String, CaseIterable, Identifiable {
        case general = "general"
        case code = "code"
        case creative = "creative"
        case research = "research"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .general: return "General"
            case .code: return "Code & Development"
            case .creative: return "Creative Writing"
            case .research: return "Research & Analysis"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "folder"
            case .code: return "curlybraces"
            case .creative: return "paintbrush"
            case .research: return "magnifyingglass"
            }
        }
        
        var color: Color {
            switch self {
            case .general: return .blue
            case .code: return .green
            case .creative: return .purple
            case .research: return .orange
            }
        }
    }
}

// MARK: - Supporting Types

struct WorkspaceRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: WorkspaceManager.WorkspaceType
    let confidence: Double
}

// MARK: - Persistence Controller Stub

class WorkspacePersistenceController {
    func loadWorkspaces() -> [Project] {
        // Stub implementation - would load from file system
        return []
    }
    
    func saveWorkspace(_ workspace: Project) {
        // Stub implementation - would save to file system
    }
    
    func deleteWorkspace(_ id: UUID) {
        // Stub implementation - would delete from file system
    }
}
