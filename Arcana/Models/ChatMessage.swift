//
// ChatMessage.swift
// Arcana - Unified Message System with Revolutionary Intelligence
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
// DEPENDENCIES: UnifiedTypes.swift, ResponseQuality.swift

import Foundation
import SwiftUI

// MARK: - Core Chat Message Structure

struct ChatMessage: Identifiable, Codable, Hashable {
    
    // MARK: - Core Properties
    let id = UUID()
    let content: String
    let role: MessageRole
    let timestamp: Date
    let projectId: UUID
    
    // MARK: - Revolutionary Intelligence Metadata
    var metadata: MessageMetadata?
    
    // MARK: - Convenience Properties for Legacy Compatibility
    var isFromUser: Bool {
        return role == .user
    }
    
    var threadId: UUID {
        return projectId // Legacy compatibility - threadId maps to projectId
    }
    
    // MARK: - Initializers
    
    init(
        content: String,
        role: MessageRole,
        projectId: UUID,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.content = content
        self.role = role
        self.projectId = projectId
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    // Legacy initializer for backwards compatibility
    init(
        content: String,
        isFromUser: Bool,
        threadId: UUID,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.content = content
        self.role = isFromUser ? .user : .assistant
        self.projectId = threadId
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    // MARK: - Quality Assessment Properties
    
    /// Get the quality score for this message
    var qualityScore: Double {
        return metadata?.qualityScore?.overallScore ?? 0
    }
    
    /// Get quality improvement suggestions
    var improvementSuggestions: [String] {
        return metadata?.qualityScore?.generateImprovementSuggestions() ?? []
    }
    
    /// Check if message meets professional standards
    var meetsProfessionalStandards: Bool {
        return metadata?.qualityScore?.meetsProfessionalStandards ?? false
    }
    
    /// Get the confidence level for this message
    var confidenceLevel: Double {
        return metadata?.qualityScore?.calibratedConfidence ?? 0.0
    }
    
    /// Get uncertainty factors affecting this message
    var uncertaintyFactors: [UncertaintyFactor] {
        return metadata?.qualityScore?.uncertaintyFactors ?? []
    }
    
    /// Get quality tier (poor, acceptable, good, excellent, exceptional)
    var qualityTier: QualityTier {
        return metadata?.qualityScore?.qualityTier ?? .poor
    }
    
    // MARK: - Quality Comparison
    
    /// Compare quality with another message
    func compareQuality(with other: ChatMessage) -> QualityComparison? {
        guard let currentQuality = self.metadata?.qualityScore,
              let otherQuality = other.metadata?.qualityScore else {
            return nil
        }
        
        return currentQuality.compare(to: otherQuality)
    }
    
    /// Check if this message has better quality than another
    func hasBetterQualityThan(_ other: ChatMessage) -> Bool {
        guard let currentQuality = self.metadata?.qualityScore,
              let otherQuality = other.metadata?.qualityScore else {
            return false
        }
        
        return currentQuality.isBetterThan(otherQuality)
    }
    
    // MARK: - Metadata Management
    
    /// Add or update quality metadata
    mutating func updateQuality(_ quality: ResponseQuality) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.qualityScore = quality
        metadata?.confidence = quality.calibratedConfidence
        metadata?.lastQualityUpdate = Date()
    }
    
    /// Add ensemble contribution information
    mutating func updateEnsembleInfo(
        models: [String],
        strategy: String,
        primaryModel: String
    ) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.ensembleContributions = models
        metadata?.ensembleStrategy = strategy
        metadata?.modelUsed = primaryModel
    }
    
    /// Add temporal context information
    mutating func updateTemporalContext(_ context: TimeContext) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.temporalContext = context
    }
    
    /// Mark message as validated
    mutating func markAsValidated(by validator: String) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.validatedBy = validator
        metadata?.validationTimestamp = Date()
    }
    
    /// Add response time information
    mutating func updateResponseTime(_ duration: TimeInterval) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.responseTime = duration
    }
    
    /// Add token count information
    mutating func updateTokenCount(_ tokens: Int) {
        if metadata == nil {
            metadata = MessageMetadata()
        }
        metadata?.tokenCount = tokens
        metadata?.responseTokens = tokens
    }
    
    // MARK: - Display Properties
    
    /// Get a short summary for the message
    var summary: String {
        let maxLength = 50
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
    
    /// Get formatted timestamp
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Get role emoji for display
    var roleEmoji: String {
        switch role {
        case .user: return "👤"
        case .assistant: return "🤖"
        case .system: return "⚙️"
        }
    }
    
    /// Get quality indicator color
    var qualityColor: Color {
        return qualityTier.color
    }
    
    // MARK: - Export and Analysis
    
    /// Export message data for external systems
    func exportData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "content": content,
            "role": role.rawValue,
            "timestamp": timestamp.timeIntervalSince1970,
            "project_id": projectId.uuidString
        ]
        
        if let meta = metadata {
            data["metadata"] = meta.exportData()
        }
        
        return data
    }
    
    /// Create a copy with updated metadata
    func withUpdatedMetadata(_ newMetadata: MessageMetadata) -> ChatMessage {
        var copy = self
        copy.metadata = newMetadata
        return copy
    }
    
    /// Create a copy with updated quality
    func withQuality(_ quality: ResponseQuality) -> ChatMessage {
        var copy = self
        copy.updateQuality(quality)
        return copy
    }
}

// MARK: - Codable Implementation

extension ChatMessage {
    enum CodingKeys: String, CodingKey {
        case content, role, timestamp, projectId, metadata
        // Note: 'id' is excluded - will be generated fresh on decode
    }
}

// MARK: - Enhanced Message Metadata

struct MessageMetadata: Codable, Hashable {
    
    // MARK: - Legacy Fields (Maintained for Compatibility)
    var modelUsed: String?
    var responseTime: TimeInterval?
    var tokenCount: Int?
    
    // MARK: - Revolutionary Quality Metadata
    var qualityScore: ResponseQuality?           // Complete quality assessment
    var confidence: Double?                      // Quick access to confidence
    var lastQualityUpdate: Date?                 // When quality was last assessed
    
    // MARK: - Ensemble Intelligence Metadata
    var ensembleContributions: [String]?         // Which models contributed
    var ensembleStrategy: String?                // Strategy used for ensemble
    var consensusScore: Double?                  // Agreement between models
    var primaryContributor: String?              // Main model that generated response
    
    // MARK: - Temporal Intelligence Metadata
    var temporalContext: TimeContext?            // When and under what conditions
    var circadianOptimality: Double?             // How optimal the timing was
    var seasonalContext: String?                 // Seasonal influence on response
    
    // MARK: - Advanced Validation Metadata
    var validatedBy: String?                     // Which validator checked this
    var validationTimestamp: Date?               // When validation occurred
    var factCheckResults: [String: Bool]?        // Fact-checking results
    var sourceReliability: Double?               // Reliability of sources used
    
    // MARK: - Performance Metadata
    var responseTokens: Int?                     // Tokens in the response
    var processingSteps: Int?                    // How many processing steps
    var cacheHitRate: Double?                    // How much was cached vs computed
    var memoryUsage: Double?                     // Memory used during generation
    
    // MARK: - User Interaction Metadata
    var userFeedback: Double?                    // User rating if provided
    var userFlags: [String]?                     // User-reported issues
    var conversationDepth: Int?                  // Position in conversation
    var topicRelevance: Double?                  // How relevant to topic
    
    // MARK: - Revolutionary Features Metadata
    var quantumMemorySignature: String?          // Quantum memory compatibility
    var predictiveAccuracy: Double?              // How accurate predictions were
    var adaptationScore: Double?                 // How well adapted to user
    var innovationIndex: Double?                 // How novel/creative the response
    
    // MARK: - Initializer
    
    init() {
        // Initialize with current temporal context
        self.temporalContext = TimeContext()
        self.lastQualityUpdate = Date()
    }
    
    // MARK: - Quality Management
    
    /// Check if metadata has comprehensive quality information
    var hasComprehensiveQuality: Bool {
        return qualityScore != nil &&
               confidence != nil &&
               lastQualityUpdate != nil
    }
    
    /// Get overall reliability score combining multiple factors
    var reliabilityScore: Double {
        guard let quality = qualityScore else { return 0.0 }
        
        var score = quality.calibratedConfidence
        
        // Factor in validation
        if validatedBy != nil {
            score *= 1.1
        }
        
        // Factor in ensemble consensus
        if let consensus = consensusScore {
            score = (score + consensus) / 2.0
        }
        
        // Factor in source reliability
        if let sourceRel = sourceReliability {
            score = (score + sourceRel) / 2.0
        }
        
        return min(score, 1.0)
    }
    
    /// Export metadata for external systems
    func exportData() -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Legacy fields
        if let model = modelUsed { data["model_used"] = model }
        if let time = responseTime { data["response_time"] = time }
        if let tokens = tokenCount { data["token_count"] = tokens }
        
        // Quality information
        if let quality = qualityScore {
            data["quality"] = quality.exportData()
        }
        if let conf = confidence { data["confidence"] = conf }
        if let update = lastQualityUpdate { data["last_quality_update"] = update.timeIntervalSince1970 }
        
        // Ensemble information
        if let contributions = ensembleContributions { data["ensemble_contributions"] = contributions }
        if let strategy = ensembleStrategy { data["ensemble_strategy"] = strategy }
        if let consensus = consensusScore { data["consensus_score"] = consensus }
        if let primary = primaryContributor { data["primary_contributor"] = primary }
        
        // Temporal information
        if let temporal = temporalContext {
            data["temporal_context"] = [
                "time_of_day": temporal.timeOfDay.rawValue,
                "circadian_phase": temporal.circadianPhase.rawValue,
                "season": temporal.season.rawValue,
                "energy_level": temporal.energyLevel,
                "cognitive_optimality": temporal.cognitiveOptimality
            ]
        }
        if let optimality = circadianOptimality { data["circadian_optimality"] = optimality }
        if let seasonal = seasonalContext { data["seasonal_context"] = seasonal }
        
        // Validation information
        if let validator = validatedBy { data["validated_by"] = validator }
        if let validation = validationTimestamp { data["validation_timestamp"] = validation.timeIntervalSince1970 }
        if let factCheck = factCheckResults { data["fact_check_results"] = factCheck }
        if let reliability = sourceReliability { data["source_reliability"] = reliability }
        
        // Performance information
        if let respTokens = responseTokens { data["response_tokens"] = respTokens }
        if let steps = processingSteps { data["processing_steps"] = steps }
        if let cache = cacheHitRate { data["cache_hit_rate"] = cache }
        if let memory = memoryUsage { data["memory_usage"] = memory }
        
        // User interaction
        if let feedback = userFeedback { data["user_feedback"] = feedback }
        if let flags = userFlags { data["user_flags"] = flags }
        if let depth = conversationDepth { data["conversation_depth"] = depth }
        if let relevance = topicRelevance { data["topic_relevance"] = relevance }
        
        // Revolutionary features
        if let quantum = quantumMemorySignature { data["quantum_memory_signature"] = quantum }
        if let predictive = predictiveAccuracy { data["predictive_accuracy"] = predictive }
        if let adaptation = adaptationScore { data["adaptation_score"] = adaptation }
        if let innovation = innovationIndex { data["innovation_index"] = innovation }
        
        data["reliability_score"] = reliabilityScore
        
        return data
    }
}

// MARK: - Message Collection Utilities

extension Array where Element == ChatMessage {
    
    /// Get all messages from a specific role
    func messages(from role: MessageRole) -> [ChatMessage] {
        return self.filter { $0.role == role }
    }
    
    /// Get user messages
    var userMessages: [ChatMessage] {
        return messages(from: .user)
    }
    
    /// Get assistant messages
    var assistantMessages: [ChatMessage] {
        return messages(from: .assistant)
    }
    
    /// Calculate average quality score
    var averageQuality: Double {
        let qualityScores = self.compactMap { $0.metadata?.qualityScore?.overallScore }
        guard !qualityScores.isEmpty else { return 0.0 }
        return qualityScores.reduce(0, +) / Double(qualityScores.count)
    }
    
    /// Get messages that meet professional standards
    var professionalQualityMessages: [ChatMessage] {
        return self.filter { $0.meetsProfessionalStandards }
    }
    
    /// Find the highest quality message
    var bestQualityMessage: ChatMessage? {
        return self.max { a, b in
            a.qualityScore < b.qualityScore
        }
    }
    
    /// Get conversation summary
    var conversationSummary: String {
        let userCount = userMessages.count
        let assistantCount = assistantMessages.count
        let avgQuality = String(format: "%.1f%%", averageQuality * 100)
        
        return "Conversation: \(userCount) user messages, \(assistantCount) assistant responses, \(avgQuality) avg quality"
    }
}

// MARK: - Static Factory Methods

extension ChatMessage {
    
    /// Create a high-quality assistant message
    static func assistantMessage(
        content: String,
        projectId: UUID,
        quality: ResponseQuality? = nil,
        models: [String] = ["Enhanced Intelligence"]
    ) -> ChatMessage {
        var message = ChatMessage(
            content: content,
            role: .assistant,
            projectId: projectId
        )
        
        if let qual = quality {
            message.updateQuality(qual)
        } else {
            message.updateQuality(ResponseQuality.excellentQuality(modelContributions: models))
        }
        
        message.updateEnsembleInfo(
            models: models,
            strategy: "Revolutionary Intelligence",
            primaryModel: models.first ?? "Enhanced Intelligence"
        )
        
        return message
    }
    
    /// Create a user message
    static func userMessage(
        content: String,
        projectId: UUID
    ) -> ChatMessage {
        return ChatMessage(
            content: content,
            role: .user,
            projectId: projectId
        )
    }
    
    /// Create a system message
    static func systemMessage(
        content: String,
        projectId: UUID
    ) -> ChatMessage {
        return ChatMessage(
            content: content,
            role: .system,
            projectId: projectId
        )
    }
}
