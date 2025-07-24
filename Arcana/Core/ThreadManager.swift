// ThreadManager.swift - Enhanced with Intelligent Workspace Suggestions
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class ThreadManager: ObservableObject {
    static let shared = ThreadManager()
    
    @Published var activeThread: ConversationThread?
    @Published var recentThreads: [ConversationThread] = []
    @Published var projectThreads: [UUID: [ConversationThread]] = [:]
    @Published var showWorkspaceCreationDialog = false
    @Published var workspaceCreationContext: WorkspaceCreationContext?
    
    private let persistenceController = ThreadPersistenceController()
    private let intelligenceEngine = IntelligenceEngine()
    
    private init() {
        loadThreads()
    }
    
    // MARK: - Enhanced Contextual Workspace Creation
    
    func evaluateForWorkspaceCreation(_ thread: ConversationThread) {
        guard thread.type == .instant,
              thread.messages.count >= 4,
              thread.projectId == nil else { return }
        
        let conversationContent = thread.messages.map { $0.content }.joined(separator: " ")
        
        // Only suggest if conversation has substantial, specific content
        if shouldSuggestWorkspaceCreation(for: conversationContent) {
            let context = generateWorkspaceCreationContext(from: thread, content: conversationContent)
            
            DispatchQueue.main.async {
                self.workspaceCreationContext = context
                self.showWorkspaceCreationDialog = true
            }
        }
    }
    
    private func shouldSuggestWorkspaceCreation(for content: String) -> Bool {
        // Must have substantial content
        guard content.count > 300 else { return false }
        
        // Must contain specific technical terms or project-related keywords
        let specificIndicators = [
            // Technical specificity
            "implement", "solution", "problem", "issue", "error", "bug", "feature",
            "optimization", "performance", "security", "authentication", "database",
            "API", "frontend", "backend", "mobile", "web", "deployment",
            
            // Project specificity
            "project", "application", "system", "platform", "workflow", "process",
            "strategy", "campaign", "research", "analysis", "study", "investigation",
            
            // Creative specificity
            "story", "character", "plot", "narrative", "article", "content",
            "design", "brand", "marketing", "campaign", "creative", "writing"
        ]
        
        let contentLower = content.lowercased()
        let matches = specificIndicators.filter { contentLower.contains($0) }.count
        
        // Require at least 3 specific indicators for substantial conversations
        return matches >= 3
    }
    
    private func generateWorkspaceCreationContext(from thread: ConversationThread, content: String) -> WorkspaceCreationContext {
        let detectedType = intelligenceEngine.detectWorkspaceType(from: content)
        let intelligentTitle = intelligenceEngine.generateIntelligentWorkspaceTitle(from: content)
        let intelligentDescription = intelligenceEngine.generateIntelligentWorkspaceDescription(from: content)
        let existingSuggestions = findRelevantExistingWorkspaces(for: content)
        
        return WorkspaceCreationContext(
            thread: thread,
            suggestedType: detectedType,
            intelligentTitle: intelligentTitle,
            intelligentDescription: intelligentDescription,
            existingWorkspaceSuggestions: existingSuggestions,
            conversationSummary: intelligenceEngine.generateConversationSummary(from: thread.messages)
        )
    }
    
    private func findRelevantExistingWorkspaces(for content: String) -> [Project] {
        let contentKeywords = intelligenceEngine.extractKeywords(from: content)
        let workspaces = WorkspaceManager.shared.workspaces
        
        return workspaces.filter { workspace in
            let workspaceKeywords = intelligenceEngine.extractKeywords(from: "\(workspace.title) \(workspace.description)")
            let commonKeywords = Set(contentKeywords).intersection(Set(workspaceKeywords))
            return commonKeywords.count >= 2 // At least 2 shared keywords
        }.prefix(3).map { $0 } // Max 3 suggestions
    }
    
    // MARK: - Intelligent Workspace Creation Flow
    
    func createIntelligentWorkspace(
        from context: WorkspaceCreationContext,
        customTitle: String? = nil,
        customDescription: String? = nil
    ) {
        let finalTitle = customTitle?.isEmpty == false ? customTitle! : context.intelligentTitle
        let finalDescription = customDescription?.isEmpty == false ? customDescription! : context.intelligentDescription
        
        // Create workspace through WorkspaceManager
        let project = WorkspaceManager.shared.createWorkspace(title: finalTitle, description: finalDescription)
        
        // Promote thread to project thread
        promoteThreadToProject(context.thread, project: project)
        
        // Add contextual first message from AI explaining the workspace
        let explanationMessage = generateWorkspaceExplanationMessage(
            workspaceName: finalTitle,
            type: context.suggestedType,
            conversationSummary: context.conversationSummary
        )
        
        addAssistantMessage(explanationMessage, to: context.thread)
        
        // Clear creation context
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }
    
    func assignToExistingWorkspace(
        from context: WorkspaceCreationContext,
        workspace: Project
    ) {
        // Promote thread to existing project
        promoteThreadToProject(context.thread, project: workspace)
        
        // Add contextual message explaining the assignment
        let assignmentMessage = "I've added this discussion to your '\(workspace.title)' workspace. This will help keep related conversations organized together."
        
        addAssistantMessage(assignmentMessage, to: context.thread)
        
        // Clear creation context
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }
    
    private func promoteThreadToProject(_ thread: ConversationThread, project: Project) {
        // Update thread
        thread.type = .project
        thread.projectId = project.id
        
        // Move from recent to project threads
        if let index = recentThreads.firstIndex(where: { $0.id == thread.id }) {
            recentThreads.remove(at: index)
        }
        
        projectThreads[project.id, default: []].insert(thread, at: 0)
        
        // Update workspace manager selection
        WorkspaceManager.shared.selectedWorkspace = project
        
        persistenceController.saveThread(thread)
        objectWillChange.send()
    }
    
    private func generateWorkspaceExplanationMessage(
        workspaceName: String,
        type: WorkspaceManager.WorkspaceType,
        conversationSummary: String
    ) -> String {
        let typeSpecificNote = switch type {
        case .code:
            "I'll be ready to help with code reviews, debugging, and technical discussions in this workspace."
        case .creative:
            "This workspace is optimized for creative collaboration, writing feedback, and idea development."
        case .research:
            "I'll help with analysis, fact-checking, and organizing research findings in this workspace."
        case .general:
            "I'll maintain context and help organize related discussions in this workspace."
        }
        
        return "I've created the '\(workspaceName)' workspace for our discussion about \(conversationSummary). \(typeSpecificNote) Future related conversations will be easy to find here."
    }
    
    func dismissWorkspaceCreation() {
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }
    
    // MARK: - Rest of ThreadManager (existing methods remain the same)
    
    func createInstantThread() {
        let thread = ConversationThread(
            title: "New Conversation",
            type: .instant,
            projectId: nil
        )
        
        recentThreads.insert(thread, at: 0)
        activeThread = thread
        persistenceController.saveThread(thread)
    }
    
    func getOrCreateInstantThread() -> ConversationThread {
        if let current = activeThread,
           current.type == .instant,
           current.messages.isEmpty || Calendar.current.isDateInToday(current.lastModified) {
            return current
        }
        
        let thread = ConversationThread(
            title: "New Conversation",
            type: .instant,
            projectId: nil
        )
        
        recentThreads.insert(thread, at: 0)
        activeThread = thread
        persistenceController.saveThread(thread)
        return thread
    }
    
    func addMessage(_ content: String, to thread: ConversationThread) {
        let message = ChatMessage(content: content, role: .user, projectId: thread.projectId ?? UUID())
        thread.messages.append(message)
        thread.lastModified = Date()
        
        if thread.title == "New Conversation" && thread.messages.count == 1 {
            thread.title = intelligenceEngine.generateThreadTitle(from: content)
        }
        
        persistenceController.saveThread(thread)
        objectWillChange.send()
    }
    
    func addAssistantMessage(_ content: String, to thread: ConversationThread) {
        let message = ChatMessage(content: content, role: .assistant, projectId: thread.projectId ?? UUID())
        thread.messages.append(message)
        thread.lastModified = Date()
        
        persistenceController.saveThread(thread)
        objectWillChange.send()
    }
    
    func createProjectThread(for project: Project) -> ConversationThread {
        let thread = ConversationThread(
            title: "New Discussion",
            type: .project,
            projectId: project.id
        )
        
        projectThreads[project.id, default: []].insert(thread, at: 0)
        persistenceController.saveThread(thread)
        return thread
    }
    
    func getThreadsForProject(_ projectId: UUID) -> [ConversationThread] {
        return projectThreads[projectId] ?? []
    }
    
    private func loadThreads() {
        let loadedThreads = persistenceController.loadThreads()
        
        recentThreads = loadedThreads.filter { $0.type == .instant }
            .sorted { $0.lastModified > $1.lastModified }
        
        let projectThreadsList = loadedThreads.filter { $0.type == .project }
        for thread in projectThreadsList {
            if let projectId = thread.projectId {
                projectThreads[projectId, default: []].append(thread)
            }
        }
        
        for projectId in projectThreads.keys {
            projectThreads[projectId]?.sort { $0.lastModified > $1.lastModified }
        }
    }
    
    func deleteThread(_ thread: ConversationThread) {
        if thread.type == .instant {
            recentThreads.removeAll { $0.id == thread.id }
        } else if let projectId = thread.projectId {
            projectThreads[projectId]?.removeAll { $0.id == thread.id }
        }
        
        if activeThread?.id == thread.id {
            activeThread = nil
        }
        
        persistenceController.deleteThread(thread)
        objectWillChange.send()
    }
}

// MARK: - Enhanced Data Models

struct WorkspaceCreationContext {
    let thread: ConversationThread
    let suggestedType: WorkspaceManager.WorkspaceType
    let intelligentTitle: String
    let intelligentDescription: String
    let existingWorkspaceSuggestions: [Project]
    let conversationSummary: String
}
