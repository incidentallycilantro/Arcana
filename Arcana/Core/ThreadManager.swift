// ThreadManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class ThreadManager: ObservableObject {
    static let shared = ThreadManager()

    @Published var threads: [ChatThread] = []
    @Published var selectedThread: ChatThread?
    @Published var showWorkspaceCreationDialog = false
    @Published var workspaceCreationContext: WorkspaceCreationContext?

    private let intelligenceEngine = IntelligenceEngine()
    private let persistenceController = ThreadPersistenceController()

    private init() {
        loadThreads()
    }

    // MARK: - Thread Management

    func createNewThread() {
        let newThread = ChatThread()
        threads.insert(newThread, at: 0)
        selectedThread = newThread
        saveThread(newThread)
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

    // MARK: - Thread Persistence

    func loadThreads() {
        threads = persistenceController.loadThreads()
        
        // Auto-select the most recent thread
        selectedThread = threads.first
    }

    private func saveThread(_ thread: ChatThread) {
        persistenceController.saveThread(thread)
    }

    func saveAllThreads() {
        for thread in threads {
            persistenceController.saveThread(thread)
        }
    }

    // MARK: - Thread Intelligence

    func getThreadsEligibleForPromotion() -> [ChatThread] {
        return threads.filter { $0.shouldPromoteToWorkspace }
    }

    func getThreadsByType(_ type: WorkspaceManager.WorkspaceType) -> [ChatThread] {
        return threads.filter { $0.detectedType == type }
    }

    func searchThreads(query: String) -> [ChatThread] {
        guard !query.isEmpty else { return threads }
        
        return threads.filter { thread in
            thread.title.localizedCaseInsensitiveContains(query) ||
            thread.contextualTags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            thread.messages.contains { $0.content.localizedCaseInsensitiveContains(query) }
        }
    }
}

// MARK: - Thread Persistence Controller

class ThreadPersistenceController {
    private let fileManager = FileManager.default
    
    private var threadsDirectory: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let arcanaURL = appSupportURL.appendingPathComponent("Arcana")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: arcanaURL, withIntermediateDirectories: true)
        
        return arcanaURL.appendingPathComponent("Threads")
    }
    
    init() {
        setupDirectories()
    }
    
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: threadsDirectory, withIntermediateDirectories: true)
            print("📁 Thread storage ready at: \(threadsDirectory.path)")
        } catch {
            print("❌ Failed to create threads directory: \(error)")
        }
    }
    
    func saveThread(_ thread: ChatThread) {
        let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(thread)
            try data.write(to: threadURL)
            print("💾 Saved thread: \(thread.title)")
        } catch {
            print("❌ Failed to save thread \(thread.title): \(error)")
        }
    }
    
    func loadThreads() -> [ChatThread] {
        var threads: [ChatThread] = []
        
        do {
            let threadURLs = try fileManager.contentsOfDirectory(
                at: threadsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" }
            
            for url in threadURLs {
                if let thread = loadThread(from: url) {
                    threads.append(thread)
                }
            }
            
            print("📂 Loaded \(threads.count) threads from disk")
            
        } catch {
            print("❌ Failed to load threads: \(error)")
        }
        
        return threads.sorted { $0.lastModified > $1.lastModified }
    }
    
    private func loadThread(from url: URL) -> ChatThread? {
        do {
            let data = try Data(contentsOf: url)
            let thread = try JSONDecoder().decode(ChatThread.self, from: data)
            return thread
        } catch {
            print("❌ Failed to load thread from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    func deleteThread(_ thread: ChatThread) {
        let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
        
        do {
            try fileManager.removeItem(at: threadURL)
            print("🗑️ Deleted thread: \(thread.title)")
        } catch {
            print("❌ Failed to delete thread \(thread.title): \(error)")
        }
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
