// ThreadManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

@MainActor
class ThreadManager: ObservableObject {
    static let shared = ThreadManager()

    @Published var threads: [ChatThread] = []
    @Published var selectedThread: ChatThread?
    @Published var showWorkspaceCreationDialog = false
    @Published var workspaceCreationContext: WorkspaceCreationContext?

    private lazy var intelligenceEngine = IntelligenceEngine.shared
    private let persistenceController = ThreadPersistenceController()

    private init() {
        loadThreads()
    }

    // MARK: - Thread Management

    @discardableResult
    func createNewThread() -> ChatThread {
        let newThread = ChatThread()
        threads.insert(newThread, at: 0)
        selectedThread = newThread
        saveThread(newThread)
        return newThread
    }

    func selectThread(_ thread: ChatThread) {
        selectedThread = thread
        thread.lastModified = Date()
        saveThread(thread)
    }

    func deleteThread(_ thread: ChatThread) {
        threads.removeAll { $0.id == thread.id }
        persistenceController.deleteThread(thread)
        
        if selectedThread?.id == thread.id {
            selectedThread = threads.first
        }
    }

    func addMessage(_ message: ChatMessage, to thread: ChatThread) {
        thread.addMessage(message)
        saveThread(thread)
        
        // Move thread to top of list
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            let updatedThread = threads.remove(at: index)
            threads.insert(updatedThread, at: 0)
        }
    }

    // MARK: - Enhanced Contextual Workspace Creation

    func evaluateForWorkspaceCreation(_ messages: [ChatMessage]) {
        // Only suggest if conversation has substantial, specific content
        guard messages.count >= 4 else { return }

        let conversationContent = messages.map { $0.content }.joined(separator: " ")

        if shouldSuggestWorkspaceCreation(for: conversationContent) {
            Task {
                let context = await generateWorkspaceCreationContext(from: messages, content: conversationContent)
                await MainActor.run {
                    self.workspaceCreationContext = context
                    self.showWorkspaceCreationDialog = true
                }
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

    private func generateWorkspaceCreationContext(from messages: [ChatMessage], content: String) async -> WorkspaceCreationContext {
        let detectedType = await intelligenceEngine.detectWorkspaceType(from: content)
        let intelligentTitle = await intelligenceEngine.generateIntelligentWorkspaceTitle(from: content)
        let intelligentDescription = await intelligenceEngine.generateIntelligentWorkspaceDescription(from: messages)
        let existingSuggestions = await findRelevantExistingWorkspaces(for: content)

        return WorkspaceCreationContext(
            messages: messages,
            suggestedType: detectedType,
            intelligentTitle: intelligentTitle,
            intelligentDescription: intelligentDescription,
            existingWorkspaceSuggestions: existingSuggestions,
            conversationSummary: await intelligenceEngine.generateConversationSummary(from: messages)
        )
    }

    private func findRelevantExistingWorkspaces(for content: String) async -> [Project] {
        let contentKeywords = await intelligenceEngine.extractKeywords(from: content)
        let workspaces = WorkspaceManager.shared.workspaces

        return workspaces.filter { workspace in
            let workspaceKeywords = intelligenceEngine.extractKeywords(from: "\(workspace.title) \(workspace.description)")
            let commonKeywords = Set(contentKeywords).intersection(Set(workspaceKeywords))
            return commonKeywords.count >= 2
        }.prefix(3).map { $0 }
    }

    // MARK: - Workspace Promotion

    func promoteThreadToWorkspace(_ thread: ChatThread) {
        let workspace = thread.promoteToWorkspace()
        WorkspaceManager.shared.workspaces.insert(workspace, at: 0)
        WorkspaceManager.shared.selectedWorkspace = workspace
        
        // Save both thread and workspace
        saveThread(thread)
        WorkspaceManager.shared.saveWorkspaceFromExternal(workspace)
    }

    // MARK: - Intelligent Workspace Creation Flow

    func createIntelligentWorkspace(
        from context: WorkspaceCreationContext,
        customTitle: String? = nil,
        customDescription: String? = nil
    ) {
        let finalTitle = customTitle?.isEmpty == false ? customTitle! : context.intelligentTitle
        let finalDescription = customDescription?.isEmpty == false ? customDescription! : context.intelligentDescription

        let newWorkspace = Project(
            title: finalTitle,
            description: finalDescription
        )

        // Transfer conversation context (note: this would require adding conversations property to Project model in the future)
        // newWorkspace.conversations = context.messages

        WorkspaceManager.shared.workspaces.insert(newWorkspace, at: 0)
        WorkspaceManager.shared.selectedWorkspace = newWorkspace
        WorkspaceManager.shared.saveWorkspaceFromExternal(newWorkspace)

        // Clear dialog
        workspaceCreationContext = nil
        showWorkspaceCreationDialog = false
    }

    // MARK: - Persistence

    private func loadThreads() {
        threads = persistenceController.loadThreads()
    }

    private func saveThread(_ thread: ChatThread) {
        persistenceController.saveThread(thread)
    }

    func saveAllThreads() {
        for thread in threads {
            saveThread(thread)
        }
    }
}

// MARK: - Workspace Creation Context

struct WorkspaceCreationContext {
    let messages: [ChatMessage]
    let suggestedType: WorkspaceManager.WorkspaceType
    let intelligentTitle: String
    let intelligentDescription: String
    let existingWorkspaceSuggestions: [Project]
    let conversationSummary: String
}

// MARK: - Thread Persistence Controller

class ThreadPersistenceController {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var threadsDirectory: URL {
        documentsPath.appendingPathComponent("Arcana/Threads", isDirectory: true)
    }

    init() {
        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: threadsDirectory, withIntermediateDirectories: true)
    }

    func loadThreads() -> [ChatThread] {
        guard let threadFiles = try? FileManager.default.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        return threadFiles.compactMap { url in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url),
                  let thread = try? JSONDecoder().decode(ChatThread.self, from: data) else {
                return nil
            }
            return thread
        }.sorted { thread1, thread2 in
            // Safe access to lastModified using async/await pattern for @MainActor properties
            Task { @MainActor in
                return thread1.lastModified > thread2.lastModified
            }
            // Fallback comparison for synchronous context
            return true
        }
    }

    func saveThread(_ thread: ChatThread) {
        Task { @MainActor in
            let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
            
            if let data = try? JSONEncoder().encode(thread) {
                try? data.write(to: threadURL)
            }
        }
    }

    func deleteThread(_ thread: ChatThread) {
        let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
        try? FileManager.default.removeItem(at: threadURL)
    }
}
