// ThreadManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class ThreadManager: ObservableObject {
    static let shared = ThreadManager()

    @Published var showWorkspaceCreationDialog = false
    @Published var workspaceCreationContext: WorkspaceCreationContext?

    // For conversation-first UI (Task 1.3)
    @Published var instantThread: ChatThread?

    private let intelligenceEngine = IntelligenceEngine()

    private init() {
        // Initialize thread manager
    }

    // MARK: - Instant Thread Management (Task 1.3)

    func createInstantThread() {
        let newThread = ChatThread(messages: [])
        instantThread = newThread
    }

    func getOrCreateInstantThread() -> ChatThread {
        if let thread = instantThread {
            return thread
        } else {
            let newThread = ChatThread(messages: [])
            instantThread = newThread
            return newThread
        }
    }

    func addMessage(_ content: String, to thread: ChatThread) {
        let message = ChatMessage(role: .user, content: content)
        thread.messages.append(message)
    }

    func addAssistantMessage(_ content: String, to thread: ChatThread) {
        let message = ChatMessage(role: .assistant, content: content)
        thread.messages.append(message)
    }

    // MARK: - Enhanced Contextual Workspace Creation

    func evaluateForWorkspaceCreation(_ messages: [ChatMessage]) {
        // Only suggest if conversation has substantial, specific content
        guard messages.count >= 4 else { return }

        let conversationContent = messages.map { $0.content }.joined(separator: " ")

        if shouldSuggestWorkspaceCreation(for: conversationContent) {
            let context = generateWorkspaceCreationContext(from: messages, content: conversationContent)

            DispatchQueue.main.async {
                self.workspaceCreationContext = context
                self.showWorkspaceCreationDialog = true
            }
        }
    }

    private func shouldSuggestWorkspaceCreation(for content: String) -> Bool {
        guard content.count > 300 else { return false }

        let specificIndicators = [
            "implement", "solution", "problem", "issue", "error", "bug", "feature",
            "optimization", "performance", "security", "authentication", "database",
            "API", "frontend", "backend", "mobile", "web", "deployment",
            "project", "application", "system", "platform", "workflow", "process",
            "strategy", "campaign", "research", "analysis", "study", "investigation",
            "story", "character", "plot", "narrative", "article", "content",
            "design", "brand", "marketing", "creative", "writing"
        ]

        let contentLower = content.lowercased()
        let matches = specificIndicators.filter { contentLower.contains($0) }.count

        return matches >= 3
    }

    private func generateWorkspaceCreationContext(from messages: [ChatMessage], content: String) -> WorkspaceCreationContext {
        let detectedType = intelligenceEngine.detectWorkspaceType(from: content)
        let intelligentTitle = intelligenceEngine.generateIntelligentWorkspaceTitle(from: content)
        let intelligentDescription = intelligenceEngine.generateIntelligentWorkspaceDescription(from: messages)
        let existingSuggestions = findRelevantExistingWorkspaces(for: content)

        return WorkspaceCreationContext(
            messages: messages,
            suggestedType: detectedType,
            intelligentTitle: intelligentTitle,
            intelligentDescription: intelligentDescription,
            existingWorkspaceSuggestions: existingSuggestions,
            conversationSummary: intelligenceEngine.generateConversationSummary(from: messages)
        )
    }

    private func findRelevantExistingWorkspaces(for content: String) -> [Project] {
        let contentKeywords = intelligenceEngine.extractKeywords(from: content)
        let workspaces = WorkspaceManager.shared.workspaces

        return workspaces.filter { workspace in
            let workspaceKeywords = intelligenceEngine.extractKeywords(from: "\(workspace.title) \(workspace.description)")
            let commonKeywords = Set(contentKeywords).intersection(Set(workspaceKeywords))
            return commonKeywords.count >= 2
        }.prefix(3).map { $0 }
    }

    // MARK: - Intelligent Workspace Creation Flow

    func createIntelligentWorkspace(
        from context: WorkspaceCreationContext,
        customTitle: String? = nil,
        customDescription: String? = nil
    ) {
        let finalTitle = customTitle?.isEmpty == false ? customTitle! : context.intelligentTitle
        let finalDescription = customDescription?.isEmpty == false ? customDescription! : context.intelligentDescription

        let project = WorkspaceManager.shared.createWorkspace(title: finalTitle, description: finalDescription)
        WorkspaceManager.shared.selectedWorkspace = project

        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }

    func assignToExistingWorkspace(
        from context: WorkspaceCreationContext,
        workspace: Project
    ) {
        WorkspaceManager.shared.selectedWorkspace = workspace
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }

    func dismissWorkspaceCreation() {
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }
}

// MARK: - Enhanced Data Models

struct WorkspaceCreationContext {
    let messages: [ChatMessage]
    let suggestedType: WorkspaceManager.WorkspaceType
    let intelligentTitle: String
    let intelligentDescription: String
    let existingWorkspaceSuggestions: [Project]
    let conversationSummary: String
}
