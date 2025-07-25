// ChatThread.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class ChatThread: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var messages: [ChatMessage]
    @Published var title: String
    @Published var summary: String
    @Published var createdAt: Date
    @Published var lastModified: Date
    @Published var workspaceId: UUID?
    @Published var isPromotedToWorkspace: Bool
    @Published var detectedType: WorkspaceManager.WorkspaceType
    @Published var contextualTags: [String]
    
    // Enhanced properties for invisible intelligence
    @Published var conversationDepth: Int
    @Published var topicConsistency: Double
    @Published var userEngagement: Double
    @Published var promotionEligibility: Double
    
    init(messages: [ChatMessage] = []) {
        self.id = UUID()
        self.messages = messages
        self.title = "New Conversation"
        self.summary = ""
        self.createdAt = Date()
        self.lastModified = Date()
        self.workspaceId = nil
        self.isPromotedToWorkspace = false
        self.detectedType = .general
        self.contextualTags = []
        self.conversationDepth = 0
        self.topicConsistency = 0.0
        self.userEngagement = 0.0
        self.promotionEligibility = 0.0
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, messages, title, summary, createdAt, lastModified
        case workspaceId, isPromotedToWorkspace, detectedType, contextualTags
        case conversationDepth, topicConsistency, userEngagement, promotionEligibility
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        workspaceId = try container.decodeIfPresent(UUID.self, forKey: .workspaceId)
        isPromotedToWorkspace = try container.decode(Bool.self, forKey: .isPromotedToWorkspace)
        // FIXED: WorkspaceType now conforms to Codable
        detectedType = try container.decode(WorkspaceManager.WorkspaceType.self, forKey: .detectedType)
        contextualTags = try container.decode([String].self, forKey: .contextualTags)
        conversationDepth = try container.decode(Int.self, forKey: .conversationDepth)
        topicConsistency = try container.decode(Double.self, forKey: .topicConsistency)
        userEngagement = try container.decode(Double.self, forKey: .userEngagement)
        promotionEligibility = try container.decode(Double.self, forKey: .promotionEligibility)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encodeIfPresent(workspaceId, forKey: .workspaceId)
        try container.encode(isPromotedToWorkspace, forKey: .isPromotedToWorkspace)
        // FIXED: WorkspaceType now conforms to Codable
        try container.encode(detectedType, forKey: .detectedType)
        try container.encode(contextualTags, forKey: .contextualTags)
        try container.encode(conversationDepth, forKey: .conversationDepth)
        try container.encode(topicConsistency, forKey: .topicConsistency)
        try container.encode(userEngagement, forKey: .userEngagement)
        try container.encode(promotionEligibility, forKey: .promotionEligibility)
    }
    
    // MARK: - Thread Intelligence Methods
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updateThreadIntelligence()
        lastModified = Date()
    }
    
    func updateThreadIntelligence() {
        conversationDepth = messages.count
        
        // Calculate topic consistency by analyzing content similarity
        if messages.count >= 2 {
            let content = messages.map { $0.content }.joined(separator: " ")
            let words = Set(content.lowercased().components(separatedBy: .whitespacesAndNewlines))
            topicConsistency = min(1.0, Double(words.count) / Double(content.count / 10))
        }
        
        // Calculate user engagement based on message frequency and length
        // FIXED: Use isFromUser instead of role
        let userMessages = messages.filter { $0.isFromUser }
        if !userMessages.isEmpty {
            let avgLength = userMessages.map { $0.content.count }.reduce(0, +) / userMessages.count
            userEngagement = min(1.0, Double(avgLength) / 100.0)
        }
        
        // Update promotion eligibility
        updatePromotionEligibility()
        
        // Update contextual tags
        updateContextualTags()
        
        // Update title if still default
        if title == "New Conversation" && messages.count >= 2 {
            updateIntelligentTitle()
        }
    }
    
    private func updatePromotionEligibility() {
        let depthScore = min(1.0, Double(conversationDepth) / 10.0)
        let consistencyScore = topicConsistency
        let engagementScore = userEngagement
        let lengthScore = messages.map { $0.content.count }.reduce(0, +) > 500 ? 1.0 : 0.5
        
        promotionEligibility = (depthScore + consistencyScore + engagementScore + lengthScore) / 4.0
    }
    
    private func updateContextualTags() {
        let allContent = messages.map { $0.content }.joined(separator: " ").lowercased()
        
        let codeKeywords = ["code", "function", "variable", "class", "import", "export", "debug", "error", "bug", "syntax"]
        let creativeKeywords = ["story", "write", "creative", "character", "plot", "narrative", "draft", "edit"]
        let researchKeywords = ["research", "analysis", "study", "data", "statistics", "survey", "report", "findings"]
        let businessKeywords = ["business", "strategy", "market", "revenue", "profit", "customer", "sales", "marketing"]
        
        contextualTags.removeAll()
        
        if codeKeywords.contains(where: { allContent.contains($0) }) {
            contextualTags.append("Development")
        }
        if creativeKeywords.contains(where: { allContent.contains($0) }) {
            contextualTags.append("Creative")
        }
        if researchKeywords.contains(where: { allContent.contains($0) }) {
            contextualTags.append("Research")
        }
        if businessKeywords.contains(where: { allContent.contains($0) }) {
            contextualTags.append("Business")
        }
    }
    
    private func updateIntelligentTitle() {
        // FIXED: Use isFromUser instead of role
        let userMessages = messages.filter { $0.isFromUser }
        guard let firstUserMessage = userMessages.first else { return }
        
        let content = firstUserMessage.content
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        
        if words.count > 6 {
            title = words.prefix(6).joined(separator: " ") + "..."
        } else {
            title = content.count > 50 ? String(content.prefix(50)) + "..." : content
        }
    }
    
    // MARK: - Workspace Detection and Promotion
    
    // FIXED: Made async and MainActor to handle actor isolation
    @MainActor
    func detectWorkspaceType() async -> WorkspaceManager.WorkspaceType {
        let allContent = messages.map { $0.content }.joined(separator: " ")
        return IntelligenceEngine.shared.detectWorkspaceType(from: allContent)
    }
    
    func promoteToWorkspace() -> Project {
        let workspace = Project(
            title: title,
            description: generateWorkspaceDescription()
        )
        
        // Transfer all conversation history (note: this would require adding conversations property to Project model in the future)
        // workspace.conversations = messages
        
        // Mark this thread as promoted
        isPromotedToWorkspace = true
        workspaceId = workspace.id
        
        return workspace
    }
    
    private func generateWorkspaceDescription() -> String {
        if !summary.isEmpty {
            return summary
        }
        
        let allContent = messages.map { $0.content }.joined(separator: " ")
        if allContent.count > 200 {
            return String(allContent.prefix(200)) + "..."
        }
        return allContent
    }
    
    // MARK: - Quality Assessment
    
    var hasHighQualityContent: Bool {
        return promotionEligibility > 0.7 && conversationDepth >= 4
    }
    
    var isWorkspaceWorthy: Bool {
        return hasHighQualityContent && topicConsistency > 0.6
    }
    
    // MARK: - Sample Data (for preview/testing)
    
    static var sampleThread: ChatThread {
        let thread = ChatThread()
        thread.title = "JWT Authentication Help"
        
        // FIXED: Use correct ChatMessage initializer with isFromUser
        let messages = [
            ChatMessage(content: "I'm having trouble with JWT authentication in my React app", isFromUser: true, threadId: thread.id),
            ChatMessage(content: "I can help you with JWT authentication! What specific issue are you encountering?", isFromUser: false, threadId: thread.id),
            ChatMessage(content: "The token keeps expiring and I'm not sure how to handle the refresh properly", isFromUser: true, threadId: thread.id)
        ]
        
        for message in messages {
            thread.addMessage(message)
        }
        
        return thread
    }
}

// MARK: - Thread Extensions for UI

extension ChatThread {
    var displayTitle: String {
        return title.isEmpty ? "New Conversation" : title
    }
    
    var lastMessagePreview: String {
        guard let lastMessage = messages.last else { return "No messages" }
        let preview = lastMessage.content.count > 60 ? String(lastMessage.content.prefix(60)) + "..." : lastMessage.content
        return preview
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var hasMessages: Bool {
        return !messages.isEmpty
    }
    
    var promotionBadgeText: String? {
        if isPromotedToWorkspace {
            return "Workspace"
        } else if isWorkspaceWorthy {
            return "Ready"
        }
        return nil
    }
    
    var qualityIndicatorColor: String {
        switch promotionEligibility {
        case 0.8...1.0: return "green"
        case 0.6..<0.8: return "blue"
        case 0.4..<0.6: return "yellow"
        default: return "gray"
        }
    }
}
