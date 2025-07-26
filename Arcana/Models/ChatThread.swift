//
// ChatThread.swift
// Arcana - Enhanced Thread Model with Intelligence
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

@MainActor
class ChatThread: ObservableObject, Identifiable, Codable {
    
    // MARK: - Core Properties
    var id = UUID()
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        
        detectedType = try container.decode(WorkspaceManager.WorkspaceType.self, forKey: .detectedType)
        summary = try container.decode(String.self, forKey: .summary)
        tags = try container.decode([String].self, forKey: .tags)
        
        isPromotedToWorkspace = try container.decode(Bool.self, forKey: .isPromotedToWorkspace)
        workspaceId = try container.decodeIfPresent(UUID.self, forKey: .workspaceId)
        promotionEligibility = try container.decode(Double.self, forKey: .promotionEligibility)
        conversationDepth = try container.decode(Int.self, forKey: .conversationDepth)
        topicConsistency = try container.decode(Double.self, forKey: .topicConsistency)
        
        qualityScore = try container.decode(Double.self, forKey: .qualityScore)
        averageResponseTime = try container.decode(TimeInterval.self, forKey: .averageResponseTime)
        userSatisfactionScore = try container.decode(Double.self, forKey: .userSatisfactionScore)
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        preferredTimeContext = try container.decode(String.self, forKey: .preferredTimeContext)
        optimalEngagementTimes = try container.decode([Date].self, forKey: .optimalEngagementTimes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(lastModified, forKey: .lastModified)
        
        try container.encode(detectedType, forKey: .detectedType)
        try container.encode(summary, forKey: .summary)
        try container.encode(tags, forKey: .tags)
        
        try container.encode(isPromotedToWorkspace, forKey: .isPromotedToWorkspace)
        try container.encode(workspaceId, forKey: .workspaceId)
        try container.encode(promotionEligibility, forKey: .promotionEligibility)
        try container.encode(conversationDepth, forKey: .conversationDepth)
        try container.encode(topicConsistency, forKey: .topicConsistency)
        
        try container.encode(qualityScore, forKey: .qualityScore)
        try container.encode(averageResponseTime, forKey: .averageResponseTime)
        try container.encode(userSatisfactionScore, forKey: .userSatisfactionScore)
        
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(preferredTimeContext, forKey: .preferredTimeContext)
        try container.encode(optimalEngagementTimes, forKey: .optimalEngagementTimes)
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastModified = Date()
        updateConversationMetrics()
        analyzeForWorkspacePromotion()
    }
    
    func removeMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        messages.remove(at: index)
        lastModified = Date()
        updateConversationMetrics()
    }
    
    func updateMessage(at index: Int, with newContent: String) {
        guard index >= 0 && index < messages.count else { return }
        messages[index].content = newContent
        lastModified = Date()
        updateConversationMetrics()
    }
    
    // MARK: - Intelligence Analysis
    
    private func updateConversationMetrics() {
        conversationDepth = messages.count
        calculateTopicConsistency()
        calculatePromotionEligibility()
        updateQualityScore()
    }
    
    private func calculateTopicConsistency() {
        guard messages.count > 1 else {
            topicConsistency = 0.0
            return
        }
        
        // Simple topic consistency calculation
        // In a real implementation, this would use semantic analysis
        let allContent = messages.map { $0.content.lowercased() }
        let words = allContent.flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
        let wordCounts = Dictionary(grouping: words, by: { $0 }).mapValues { $0.count }
        
        let totalWords = words.count
        let repeatedWords = wordCounts.values.filter { $0 > 1 }.reduce(0, +)
        
        topicConsistency = totalWords > 0 ? Double(repeatedWords) / Double(totalWords) : 0.0
    }
    
    private func calculatePromotionEligibility() {
        var score = 0.0
        
        // Length factor
        if conversationDepth >= 4 { score += 0.3 }
        if conversationDepth >= 8 { score += 0.2 }
        
        // Topic consistency factor
        score += topicConsistency * 0.3
        
        // Quality factor
        score += qualityScore * 0.2
        
        promotionEligibility = min(1.0, score)
    }
    
    private func updateQualityScore() {
        // Calculate quality based on message length, user engagement, etc.
        let avgMessageLength = messages.isEmpty ? 0 : messages.map { $0.content.count }.reduce(0, +) / messages.count
        let engagementScore = Double(conversationDepth) / 10.0
        
        qualityScore = min(1.0, (Double(avgMessageLength) / 100.0 + engagementScore) / 2.0)
    }
    
    private func analyzeForWorkspacePromotion() {
        // This would trigger intelligent analysis for workspace promotion
        if shouldPromoteToWorkspace && !isPromotedToWorkspace {
            // Could trigger UI notifications or suggestions
            print("🎯 Thread \(title) is ready for workspace promotion")
        }
    }
    
    // MARK: - Content Generation
    
    var intelligentTitle: String {
        if !title.isEmpty { return title }
        
        guard let firstMessage = messages.first(where: { $0.isFromUser }) else {
            return "New Conversation"
        }
        
        let content = firstMessage.content
        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content.isEmpty ? "New Conversation" : content
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
        let preview = lastMessage.content.count > 60 ?
            String(lastMessage.content.prefix(60)) + "..." :
            lastMessage.content
        return preview.isEmpty ? "No content" : preview
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
    
    var statusDescription: String {
        if shouldPromoteToWorkspace {
            return "Ready for workspace"
        } else if conversationDepth >= 3 {
            return "Developing conversation"
        } else {
            return "New conversation"
        }
    }
}

// MARK: - Hashable Conformance

extension ChatThread: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatThread, rhs: ChatThread) -> Bool {
        return lhs.id == rhs.id
    }
}
