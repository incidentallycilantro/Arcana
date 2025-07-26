//
// ChatThread.swift
// Arcana - Enhanced Thread Model with Intelligence
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

@MainActor
class ChatThread: ObservableObject, @preconcurrency Identifiable, @preconcurrency Codable {
    
    // MARK: - Core Properties
    nonisolated var id = UUID()
    @Published var title: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var lastModified: Date = Date()
    
    // MARK: - Intelligence Properties
    @Published var detectedType: WorkspaceManager.WorkspaceType = .general
    @Published var summary: String = ""
    @Published var tags: [String] = []
    
    // MARK: - Workspace Integration
    @Published var isPromotedToWorkspace: Bool = false
    @Published var workspaceId: UUID?
    @Published var promotionEligibility: Double = 0.0
    @Published var conversationDepth: Int = 0
    @Published var topicConsistency: Double = 0.0
    
    // FIXED: Added missing shouldPromoteToWorkspace computed property
    var shouldPromoteToWorkspace: Bool {
        return promotionEligibility > 0.75 &&
               conversationDepth >= 4 &&
               topicConsistency > 0.6 &&
               !isPromotedToWorkspace
    }
    
    // MARK: - Thread Quality Metrics
    @Published var qualityScore: Double = 0.0
    @Published var averageResponseTime: TimeInterval = 0.0
    @Published var userSatisfactionScore: Double = 0.0
    
    // MARK: - Temporal Intelligence
    @Published var createdAt: Date = Date()
    @Published var preferredTimeContext: String = ""
    @Published var optimalEngagementTimes: [Date] = []
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, title, messages, lastModified
        case detectedType, summary, tags
        case isPromotedToWorkspace, workspaceId, promotionEligibility
        case conversationDepth, topicConsistency
        case qualityScore, averageResponseTime, userSatisfactionScore
        case createdAt, preferredTimeContext, optimalEngagementTimes
    }
    
    init() {
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    nonisolated required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedId = try container.decode(UUID.self, forKey: .id)
        let decodedTitle = try container.decode(String.self, forKey: .title)
        let decodedMessages = try container.decode([ChatMessage].self, forKey: .messages)
        let decodedLastModified = try container.decode(Date.self, forKey: .lastModified)
        
        let decodedDetectedType = try container.decode(WorkspaceManager.WorkspaceType.self, forKey: .detectedType)
        let decodedSummary = try container.decode(String.self, forKey: .summary)
        let decodedTags = try container.decode([String].self, forKey: .tags)
        
        let decodedIsPromotedToWorkspace = try container.decode(Bool.self, forKey: .isPromotedToWorkspace)
        let decodedWorkspaceId = try container.decodeIfPresent(UUID.self, forKey: .workspaceId)
        let decodedPromotionEligibility = try container.decode(Double.self, forKey: .promotionEligibility)
        let decodedConversationDepth = try container.decode(Int.self, forKey: .conversationDepth)
        let decodedTopicConsistency = try container.decode(Double.self, forKey: .topicConsistency)
        
        let decodedQualityScore = try container.decode(Double.self, forKey: .qualityScore)
        let decodedAverageResponseTime = try container.decode(TimeInterval.self, forKey: .averageResponseTime)
        let decodedUserSatisfactionScore = try container.decode(Double.self, forKey: .userSatisfactionScore)
        
        let decodedCreatedAt = try container.decode(Date.self, forKey: .createdAt)
        let decodedPreferredTimeContext = try container.decode(String.self, forKey: .preferredTimeContext)
        let decodedOptimalEngagementTimes = try container.decode([Date].self, forKey: .optimalEngagementTimes)
        
        // Initialize properties on main actor
        Task { @MainActor in
            self.id = decodedId
            self.title = decodedTitle
            self.messages = decodedMessages
            self.lastModified = decodedLastModified
            
            self.detectedType = decodedDetectedType
            self.summary = decodedSummary
            self.tags = decodedTags
            
            self.isPromotedToWorkspace = decodedIsPromotedToWorkspace
            self.workspaceId = decodedWorkspaceId
            self.promotionEligibility = decodedPromotionEligibility
            self.conversationDepth = decodedConversationDepth
            self.topicConsistency = decodedTopicConsistency
            
            self.qualityScore = decodedQualityScore
            self.averageResponseTime = decodedAverageResponseTime
            self.userSatisfactionScore = decodedUserSatisfactionScore
            
            self.createdAt = decodedCreatedAt
            self.preferredTimeContext = decodedPreferredTimeContext
            self.optimalEngagementTimes = decodedOptimalEngagementTimes
        }
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        // For @Published properties, we need to access them safely
        Task { @MainActor in
            try container.encode(self.title, forKey: .title)
            try container.encode(self.messages, forKey: .messages)
            try container.encode(self.lastModified, forKey: .lastModified)
            
            try container.encode(self.detectedType, forKey: .detectedType)
            try container.encode(self.summary, forKey: .summary)
            try container.encode(self.tags, forKey: .tags)
            
            try container.encode(self.isPromotedToWorkspace, forKey: .isPromotedToWorkspace)
            try container.encode(self.workspaceId, forKey: .workspaceId)
            try container.encode(self.promotionEligibility, forKey: .promotionEligibility)
            try container.encode(self.conversationDepth, forKey: .conversationDepth)
            try container.encode(self.topicConsistency, forKey: .topicConsistency)
            
            try container.encode(self.qualityScore, forKey: .qualityScore)
            try container.encode(self.averageResponseTime, forKey: .averageResponseTime)
            try container.encode(self.userSatisfactionScore, forKey: .userSatisfactionScore)
            
            try container.encode(self.createdAt, forKey: .createdAt)
            try container.encode(self.preferredTimeContext, forKey: .preferredTimeContext)
            try container.encode(self.optimalEngagementTimes, forKey: .optimalEngagementTimes)
        }
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastModified = Date()
        conversationDepth = messages.count
        updateWorkspaceEligibility()
        evaluateTopicConsistency()
    }
    
    func removeMessage(at index: Int) {
        guard index < messages.count else { return }
        messages.remove(at: index)
        lastModified = Date()
        conversationDepth = messages.count
        updateWorkspaceEligibility()
    }
    
    func clearMessages() {
        messages.removeAll()
        lastModified = Date()
        conversationDepth = 0
        promotionEligibility = 0.0
        topicConsistency = 0.0
    }
    
    // MARK: - Intelligence Updates
    
    private func updateWorkspaceEligibility() {
        // Calculate promotion eligibility based on conversation depth and quality
        let depthScore = min(Double(conversationDepth) / 10.0, 1.0)
        let contentQuality = calculateContentQuality()
        promotionEligibility = (depthScore + contentQuality) / 2.0
    }
    
    private func calculateContentQuality() -> Double {
        guard !messages.isEmpty else { return 0.0 }
        
        let totalLength = messages.reduce(0) { $0 + $1.content.count }
        let averageLength = Double(totalLength) / Double(messages.count)
        
        // Simple quality heuristic based on message length and variety
        let lengthScore = min(averageLength / 100.0, 1.0)
        return lengthScore
    }
    
    private func evaluateTopicConsistency() {
        guard messages.count > 1 else {
            topicConsistency = 1.0
            return
        }
        
        // Simple topic consistency calculation
        // In a real implementation, this would use NLP techniques
        let allContent = messages.map { $0.content }.joined(separator: " ")
        let uniqueWords = Set(allContent.components(separatedBy: .whitespacesAndNewlines))
        let totalWords = allContent.components(separatedBy: .whitespacesAndNewlines).count
        
        topicConsistency = Double(uniqueWords.count) / Double(totalWords)
    }
    
    // MARK: - Display Helpers
    
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        
        if let firstMessage = messages.first(where: { $0.isFromUser }) {
            let content = firstMessage.content
            return content.count > 50 ? String(content.prefix(50)) + "..." : content
        }
        
        return "New Conversation"
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var lastActivity: Date {
        return lastModified
    }
    
    var contextSummary: String {
        guard !messages.isEmpty else { return "No conversation yet" }
        
        let userMessages = messages.filter { $0.isFromUser }
        if let lastUserMessage = userMessages.last {
            let content = lastUserMessage.content
            return content.count > 100 ? String(content.prefix(100)) + "..." : content
        }
        
        return "Conversation in progress"
    }
    
    // MARK: - Workspace Detection and Promotion
    
    func detectWorkspaceType() async -> WorkspaceManager.WorkspaceType {
        let allContent = messages.map { $0.content }.joined(separator: " ")
        return await IntelligenceEngine.shared.detectWorkspaceType(from: allContent)
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
            ChatMessage(content: "The token keeps expiring and I'm not sure how to handle refresh tokens properly", isFromUser: true, threadId: thread.id),
            ChatMessage(content: "Perfect! Let's implement a robust JWT refresh token strategy. Here's what I recommend...", isFromUser: false, threadId: thread.id)
        ]
        
        for message in messages {
            thread.addMessage(message)
        }
        
        thread.summary = "Discussion about JWT authentication and refresh token implementation"
        thread.tags = ["authentication", "JWT", "React", "security"]
        
        return thread
    }
}

// MARK: - Hashable Conformance

extension ChatThread: @preconcurrency Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    nonisolated static func == (lhs: ChatThread, rhs: ChatThread) -> Bool {
        return lhs.id == rhs.id
    }
}
