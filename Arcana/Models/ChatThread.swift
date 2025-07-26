//
// ChatThread.swift
// Arcana - Enhanced Thread Model with Intelligence
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
// DEPENDENCIES: UnifiedTypes.swift, ChatMessage.swift, WorkspaceManager.swift

import Foundation

class ChatThread: ObservableObject, Identifiable, Codable {
    
    // MARK: - Core Properties
    let id = UUID() // FIXED: Removed nonisolated - not needed for let constants
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
    
    // MARK: - Thread Quality Metrics
    @Published var qualityScore: Double = 0.0
    @Published var averageResponseTime: TimeInterval = 0.0
    @Published var userSatisfactionScore: Double = 0.0
    
    // MARK: - Temporal Intelligence
    @Published var createdAt: Date = Date()
    @Published var preferredTimeContext: String = ""
    @Published var optimalEngagementTimes: [Date] = []
    
    // MARK: - Computed Properties
    
    var shouldPromoteToWorkspace: Bool {
        return promotionEligibility > 0.75 &&
               conversationDepth >= 4 &&
               topicConsistency > 0.6 &&
               !isPromotedToWorkspace
    }
    
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(content.prefix(50)) + (content.count > 50 ? "..." : "")
        }
        
        return "New Conversation"
    }
    
    var lastMessagePreview: String {
        guard let lastMessage = messages.last else { return "No messages" }
        let content = lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(content.prefix(100)) + (content.count > 100 ? "..." : "")
    }
    
    var formattedLastModified: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
    
    // MARK: - Initializers
    
    init() {
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // MARK: - Codable Support
    
    enum CodingKeys: String, CodingKey {
        case id, title, messages, lastModified
        case detectedType, summary, tags
        case isPromotedToWorkspace, workspaceId, promotionEligibility
        case conversationDepth, topicConsistency
        case qualityScore, averageResponseTime, userSatisfactionScore
        case createdAt, preferredTimeContext, optimalEngagementTimes
    }
    
    nonisolated required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Core properties
        self.title = try container.decode(String.self, forKey: .title)
        self.messages = try container.decode([ChatMessage].self, forKey: .messages)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        
        // Intelligence properties
        self.detectedType = try container.decode(WorkspaceManager.WorkspaceType.self, forKey: .detectedType)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.tags = try container.decode([String].self, forKey: .tags)
        
        // Workspace integration
        self.isPromotedToWorkspace = try container.decode(Bool.self, forKey: .isPromotedToWorkspace)
        self.workspaceId = try container.decodeIfPresent(UUID.self, forKey: .workspaceId)
        self.promotionEligibility = try container.decode(Double.self, forKey: .promotionEligibility)
        self.conversationDepth = try container.decode(Int.self, forKey: .conversationDepth)
        self.topicConsistency = try container.decode(Double.self, forKey: .topicConsistency)
        
        // Quality metrics
        self.qualityScore = try container.decode(Double.self, forKey: .qualityScore)
        self.averageResponseTime = try container.decode(TimeInterval.self, forKey: .averageResponseTime)
        self.userSatisfactionScore = try container.decode(Double.self, forKey: .userSatisfactionScore)
        
        // Temporal intelligence
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.preferredTimeContext = try container.decode(String.self, forKey: .preferredTimeContext)
        self.optimalEngagementTimes = try container.decode([Date].self, forKey: .optimalEngagementTimes)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Core properties
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(lastModified, forKey: .lastModified)
        
        // Intelligence properties
        try container.encode(detectedType, forKey: .detectedType)
        try container.encode(summary, forKey: .summary)
        try container.encode(tags, forKey: .tags)
        
        // Workspace integration
        try container.encode(isPromotedToWorkspace, forKey: .isPromotedToWorkspace)
        try container.encode(workspaceId, forKey: .workspaceId)
        try container.encode(promotionEligibility, forKey: .promotionEligibility)
        try container.encode(conversationDepth, forKey: .conversationDepth)
        try container.encode(topicConsistency, forKey: .topicConsistency)
        
        // Quality metrics
        try container.encode(qualityScore, forKey: .qualityScore)
        try container.encode(averageResponseTime, forKey: .averageResponseTime)
        try container.encode(userSatisfactionScore, forKey: .userSatisfactionScore)
        
        // Temporal intelligence
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(preferredTimeContext, forKey: .preferredTimeContext)
        try container.encode(optimalEngagementTimes, forKey: .optimalEngagementTimes)
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastModified = Date()
        conversationDepth = messages.count
        updateWorkspaceEligibility()
        evaluateTopicConsistency()
        updateQualityMetrics()
    }
    
    func removeMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        messages.remove(at: index)
        lastModified = Date()
        conversationDepth = messages.count
        updateWorkspaceEligibility()
        evaluateTopicConsistency()
    }
    
    func clearMessages() {
        messages.removeAll()
        lastModified = Date()
        conversationDepth = 0
        promotionEligibility = 0.0
        topicConsistency = 0.0
        qualityScore = 0.0
    }
    
    // MARK: - Intelligence Methods
    
    private func updateWorkspaceEligibility() {
        // Calculate promotion eligibility based on conversation metrics
        let messageCount = messages.count
        let contentDepth = calculateContentDepth()
        let typeConsistency = calculateTypeConsistency()
        
        promotionEligibility = min(
            (Double(messageCount) / 10.0) * 0.4 +
            contentDepth * 0.3 +
            typeConsistency * 0.3,
            1.0
        )
    }
    
    private func evaluateTopicConsistency() {
        guard messages.count >= 2 else {
            topicConsistency = 0.0
            return
        }
        
        // Simple topic consistency calculation
        // In a full implementation, this would use semantic analysis
        let keywords = extractKeywords()
        let uniqueKeywords = Set(keywords)
        let totalKeywords = keywords.count
        
        if totalKeywords > 0 {
            topicConsistency = Double(uniqueKeywords.count) / Double(totalKeywords)
        } else {
            topicConsistency = 0.5
        }
    }
    
    private func updateQualityMetrics() {
        let assistantMessages = messages.filter { $0.role == .assistant }
        
        if !assistantMessages.isEmpty {
            let qualityScores = assistantMessages.compactMap { $0.qualityScore }
            qualityScore = qualityScores.isEmpty ? 0.0 : qualityScores.reduce(0, +) / Double(qualityScores.count)
            
            let responseTimes = assistantMessages.compactMap { $0.metadata?.responseTime }
            averageResponseTime = responseTimes.isEmpty ? 0.0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        }
    }
    
    private func calculateContentDepth() -> Double {
        let totalLength = messages.reduce(0) { sum, message in
            sum + message.content.count
        }
        
        // Normalize content depth (assuming 500 characters per substantial message)
        return min(Double(totalLength) / (Double(messages.count) * 500.0), 1.0)
    }
    
    private func calculateTypeConsistency() -> Double {
        guard messages.count > 1 else { return 1.0 }
        
        // Simple type consistency based on detected type stability
        // In full implementation, would analyze semantic consistency
        return 0.8 // Placeholder value
    }
    
    private func extractKeywords() -> [String] {
        let allText = messages.map { $0.content }.joined(separator: " ")
        let words = allText.components(separatedBy: .whitespacesAndNewlines)
        
        return words.filter { word in
            word.count > 3 && !word.localizedCaseInsensitiveContains("the") &&
            !word.localizedCaseInsensitiveContains("and") &&
            !word.localizedCaseInsensitiveContains("for")
        }
    }
    
    // MARK: - Workspace Detection
    
    func detectWorkspaceType() async -> WorkspaceManager.WorkspaceType {
        guard !messages.isEmpty else { return .general }
        
        let content = messages.map { $0.content }.joined(separator: " ")
        return await IntelligenceEngine.shared.detectWorkspaceType(from: content)
    }
    
    func updateDetectedType() {
        Task {
            let newType = await detectWorkspaceType()
            await MainActor.run {
                if self.detectedType != newType {
                    self.detectedType = newType
                    self.lastModified = Date()
                }
            }
        }
    }
    
    // MARK: - Export and Analysis
    
    func generateSummary() -> String {
        guard !messages.isEmpty else { return "Empty conversation" }
        
        if !summary.isEmpty {
            return summary
        }
        
        // Generate basic summary
        let userMessages = messages.filter { $0.role == .user }
        let assistantMessages = messages.filter { $0.role == .assistant }
        
        return "Conversation with \(userMessages.count) user messages and \(assistantMessages.count) assistant responses. Topic: \(detectedType.displayName)"
    }
    
    func exportData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "display_title": displayTitle,
            "message_count": messages.count,
            "detected_type": detectedType.rawValue,
            "quality_score": qualityScore,
            "promotion_eligibility": promotionEligibility,
            "topic_consistency": topicConsistency,
            "created_at": createdAt.timeIntervalSince1970,
            "last_modified": lastModified.timeIntervalSince1970,
            "summary": generateSummary(),
            "tags": tags
        ]
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

// MARK: - Sample Data for Development

extension ChatThread {
    static func createSampleThread() -> ChatThread {
        let thread = ChatThread()
        thread.title = "Sample Conversation"
        thread.detectedType = .code
        
        let messages = [
            ChatMessage(content: "I need help with implementing JWT authentication in React", role: .user, projectId: thread.id),
            ChatMessage(content: "I'd be happy to help you with JWT authentication in React! What specific aspect are you working on?", role: .assistant, projectId: thread.id),
            ChatMessage(content: "The token keeps expiring and I'm not sure how to handle refresh tokens properly", role: .user, projectId: thread.id),
            ChatMessage(content: "Perfect! Let's implement a robust JWT refresh token strategy. Here's what I recommend...", role: .assistant, projectId: thread.id)
        ]
        
        for message in messages {
            thread.addMessage(message)
        }
        
        thread.summary = "Discussion about JWT authentication and refresh token implementation"
        thread.tags = ["authentication", "JWT", "React", "security"]
        
        return thread
    }
}
