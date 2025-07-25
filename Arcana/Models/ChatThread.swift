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
        // Update conversation depth
        conversationDepth = messages.count
        
        // Calculate topic consistency
        topicConsistency = calculateTopicConsistency()
        
        // Calculate user engagement
        userEngagement = calculateUserEngagement()
        
        // Calculate promotion eligibility
        promotionEligibility = calculatePromotionEligibility()
        
        // Update title if needed
        if messages.count >= 2 && title == "New Conversation" {
            updateIntelligentTitle()
        }
        
        // Update contextual tags
        updateContextualTags()
        
        // Detect workspace type
        detectedType = detectWorkspaceType()
    }
    
    private func calculateTopicConsistency() -> Double {
        guard messages.count > 2 else { return 0.0 }
        
        let userMessages = messages.filter { $0.role == .user }
        guard userMessages.count > 1 else { return 0.0 }
        
        // Simple keyword overlap analysis
        let allKeywords = userMessages.flatMap { extractKeywords(from: $0.content) }
        let uniqueKeywords = Set(allKeywords)
        
        // More repeated keywords = higher consistency
        let consistency = Double(allKeywords.count - uniqueKeywords.count) / Double(max(allKeywords.count, 1))
        return min(1.0, consistency * 2.0) // Scale to 0-1
    }
    
    private func calculateUserEngagement() -> Double {
        guard messages.count > 0 else { return 0.0 }
        
        let userMessages = messages.filter { $0.role == .user }
        let avgMessageLength = userMessages.reduce(0) { $0 + $1.content.count } / max(userMessages.count, 1)
        
        // Longer messages and more turns = higher engagement
        let lengthScore = min(1.0, Double(avgMessageLength) / 200.0) // Normalize to 0-1
        let turnScore = min(1.0, Double(messages.count) / 10.0) // Normalize to 0-1
        
        return (lengthScore + turnScore) / 2.0
    }
    
    private func calculatePromotionEligibility() -> Double {
        let depthScore = min(1.0, Double(conversationDepth) / 6.0)
        let consistencyScore = topicConsistency
        let engagementScore = userEngagement
        
        // Weighted average with emphasis on consistency and engagement
        return (depthScore * 0.2 + consistencyScore * 0.4 + engagementScore * 0.4)
    }
    
    private func updateIntelligentTitle() {
        let conversationContent = messages.map { $0.content }.joined(separator: " ")
        let keywords = extractKeywords(from: conversationContent)
        
        if let primaryKeyword = keywords.first {
            switch detectedType {
            case .code:
                title = "\(primaryKeyword) Development"
            case .creative:
                title = "\(primaryKeyword) Creative Work"
            case .research:
                title = "\(primaryKeyword) Research"
            case .general:
                title = "\(primaryKeyword) Discussion"
            }
        } else {
            title = "\(detectedType.displayName) Conversation"
        }
    }
    
    private func updateContextualTags() {
        let allContent = messages.map { $0.content }.joined(separator: " ")
        let keywords = extractKeywords(from: allContent)
        contextualTags = Array(keywords.prefix(5))
    }
    
    private func detectWorkspaceType() -> WorkspaceManager.WorkspaceType {
        let allContent = messages.map { $0.content }.joined(separator: " ")
        return IntelligenceEngine.shared.detectWorkspaceType(from: allContent)
    }
    
    private func extractKeywords(from content: String) -> [String] {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                return cleaned.count > 3 && !isStopWord(cleaned) ? cleaned.capitalized : nil
            }
        
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return wordCounts.prefix(5).map { $0.key }
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "and", "for", "are", "but", "not", "you", "all", "can", "had",
            "her", "was", "one", "our", "out", "day", "get", "has", "him", "his",
            "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy",
            "did", "what", "with", "have", "this", "will", "been", "from", "they",
            "she", "when", "where", "why", "some", "that", "there", "their", "would"
        ]
        return stopWords.contains(word.lowercased())
    }
    
    // MARK: - Workspace Promotion
    
    func promoteToWorkspace() -> Project {
        let workspace = Project(title: title, description: generateWorkspaceDescription())
        workspaceId = workspace.id
        isPromotedToWorkspace = true
        return workspace
    }
    
    private func generateWorkspaceDescription() -> String {
        switch detectedType {
        case .code:
            return "Development workspace for technical discussions and coding solutions."
        case .creative:
            return "Creative workspace for writing, brainstorming, and artistic exploration."
        case .research:
            return "Research workspace for analysis, investigation, and knowledge gathering."
        case .general:
            return "General workspace for discussions and collaborative thinking."
        }
    }
    
    // MARK: - Helper Properties
    
    var shouldPromoteToWorkspace: Bool {
        return !isPromotedToWorkspace && promotionEligibility > 0.6 && conversationDepth >= 4
    }
    
    var displayTitle: String {
        return title == "New Conversation" ? "Quick Chat" : title
    }
    
    var lastActivity: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
    
    var messageCount: String {
        return "\(messages.count) message\(messages.count == 1 ? "" : "s")"
    }
}

// MARK: - Sample Data for Development
extension ChatThread {
    static var sampleThread: ChatThread {
        let thread = ChatThread()
        thread.title = "React Authentication"
        thread.detectedType = .code
        thread.conversationDepth = 6
        thread.topicConsistency = 0.8
        thread.userEngagement = 0.7
        thread.promotionEligibility = 0.75
        
        let messages = [
            ChatMessage(content: "I'm having trouble with JWT authentication in my React app", role: .user, projectId: UUID()),
            ChatMessage(content: "I can help you with JWT authentication! What specific issue are you encountering?", role: .assistant, projectId: UUID()),
            ChatMessage(content: "The token keeps expiring and I'm not sure how to handle the refresh properly", role: .user, projectId: UUID())
        ]
        
        messages.forEach { thread.addMessage($0) }
        return thread
    }
}
