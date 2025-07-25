//
// ChatMessage.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Enhanced with Revolutionary Quality Metadata
//

import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    var id = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var threadId: UUID?
    
    // MARK: - Revolutionary Metadata
    var metadata: MessageMetadata?
    
    // MARK: - Legacy Properties (Maintained for Compatibility)
    var isTyping: Bool = false
    var attachments: [MessageAttachment] = []
    
    init(
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        threadId: UUID? = nil,
        metadata: MessageMetadata? = nil
    ) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.threadId = threadId
        self.metadata = metadata
    }
    
    // MARK: - Quality Access Properties
    
    /// Quick access to overall quality score
    var qualityScore: Double? {
        return metadata?.qualityScore?.overallScore
    }
    
    /// Quick access to confidence level
    var confidence: Double? {
        return metadata?.confidence
    }
    
    /// Quick access to ensemble contributions
    var ensembleModels: [String]? {
        return metadata?.ensembleContributions
    }
    
    /// Check if message meets professional standards
    var meetsProfessionalStandards: Bool {
        return metadata?.qualityScore?.meetsProfessionalStandards ?? false
    }
    
    /// Get quality tier for UI display
    var qualityTier: QualityTier? {
        return metadata?.qualityScore?.qualityTier
    }
    
    /// Get display-ready quality information
    var displayQuality: DisplayQuality? {
        return metadata?.qualityScore?.displayQuality
    }
    
    // MARK: - Quality Analysis Methods
    
    /// Check if message has quality assessment
    var hasQualityAssessment: Bool {
        return metadata?.qualityScore != nil
    }
    
    /// Check if message has uncertainties
    var hasUncertainties: Bool {
        return metadata?.qualityScore?.uncertaintyFactors.isEmpty == false
    }
    
    /// Get uncertainty count
    var uncertaintyCount: Int {
        return metadata?.qualityScore?.uncertaintyFactors.count ?? 0
    }
    
    /// Get quality improvement suggestions
    var improvementSuggestions: [String] {
        return metadata?.qualityScore?.generateImprovementSuggestions() ?? []
    }
    
    // MARK: - Quality Comparison
    
    /// Compare quality with another message
    func compareQuality(with other: ChatMessage) -> QualityComparison? {
        guard let currentQuality = self.metadata?.qualityScore,
              let otherQuality = other.metadata?.qualityScore else {
            return nil
        }
        
        return currentQuality.compare(with: otherQuality)
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
}

// MARK: - Enhanced Message Metadata

struct MessageMetadata: Codable, Hashable {
    // MARK: - Legacy Fields (Maintained for Compatibility)
    var modelUsed: String?
    var responseTime: TimeInterval?
    var tokenCount: Int?
    
    // MARK: - Revolutionary Quality Metadata
    var qualityScore: ResponseQuality?           // Complete quality assessment
    var confidence: Double?                       // Calibrated confidence score
    var ensembleContributions: [String]?         // Models that contributed
    var ensembleStrategy: String?                // Strategy used for ensemble
    var temporalContext: TimeContext?            // Time-aware context
    
    // MARK: - Validation Metadata
    var validatedBy: String?                     // Validation engine used
    var validationTimestamp: Date?               // When validation occurred
    var lastQualityUpdate: Date?                 // Last quality assessment update
    
    // MARK: - Performance Metadata
    var inferenceTime: TimeInterval?             // Time to generate response
    var memoryUsage: Int?                        // Memory used during inference
    var cacheHitRate: Double?                    // Cache effectiveness
    
    // MARK: - Context Metadata
    var contextLength: Int?                      // Length of context used
    var promptTokens: Int?                       // Tokens in the prompt
    var responseTokens: Int?                     // Tokens in the response
    
    init() {
        // Initialize with current timestamp
        self.lastQualityUpdate = Date()
    }
    
    // MARK: - Metadata Analysis
    
    /// Get performance summary
    var performanceSummary: PerformanceSummary? {
        guard let responseTime = inferenceTime,
              let confidence = confidence else {
            return nil
        }
        
        return PerformanceSummary(
            responseTime: responseTime,
            confidence: confidence,
            memoryUsage: memoryUsage ?? 0,
            cacheHitRate: cacheHitRate ?? 0.0
        )
    }
    
    /// Check if metadata is complete
    var isComplete: Bool {
        return qualityScore != nil &&
               confidence != nil &&
               modelUsed != nil &&
               validationTimestamp != nil
    }
    
    /// Get metadata completeness percentage
    var completeness: Double {
        let totalFields = 12 // Total metadata fields
        var filledFields = 0
        
        if qualityScore != nil { filledFields += 1 }
        if confidence != nil { filledFields += 1 }
        if ensembleContributions != nil { filledFields += 1 }
        if temporalContext != nil { filledFields += 1 }
        if validatedBy != nil { filledFields += 1 }
        if inferenceTime != nil { filledFields += 1 }
        if memoryUsage != nil { filledFields += 1 }
        if cacheHitRate != nil { filledFields += 1 }
        if contextLength != nil { filledFields += 1 }
        if promptTokens != nil { filledFields += 1 }
        if responseTokens != nil { filledFields += 1 }
        if modelUsed != nil { filledFields += 1 }
        
        return Double(filledFields) / Double(totalFields)
    }
}

// MARK: - Performance Summary

struct PerformanceSummary: Codable, Hashable {
    let responseTime: TimeInterval
    let confidence: Double
    let memoryUsage: Int
    let cacheHitRate: Double
    
    var performanceGrade: PerformanceGrade {
        // Calculate overall performance grade
        let timeScore = responseTime < 2.0 ? 1.0 : (responseTime < 5.0 ? 0.7 : 0.4)
        let confidenceScore = confidence
        let cacheScore = cacheHitRate
        
        let averageScore = (timeScore + confidenceScore + cacheScore) / 3.0
        
        switch averageScore {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .fair
        default: return .poor
        }
    }
}

enum PerformanceGrade: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}

// MARK: - Message Attachments (Legacy Support)

struct MessageAttachment: Codable, Hashable, Identifiable {
    var id = UUID()
    let fileName: String
    let fileType: String
    let filePath: String
    let fileSize: Int
    let uploadTimestamp: Date
    
    init(
        fileName: String,
        fileType: String,
        filePath: String,
        fileSize: Int,
        uploadTimestamp: Date = Date()
    ) {
        self.fileName = fileName
        self.fileType = fileType
        self.filePath = filePath
        self.fileSize = fileSize
        self.uploadTimestamp = uploadTimestamp
    }
}

// MARK: - Extensions for Better Integration

extension ChatMessage {
    /// Create a user message with basic metadata
    static func userMessage(
        content: String,
        threadId: UUID? = nil
    ) -> ChatMessage {
        var message = ChatMessage(
            content: content,
            isFromUser: true,
            threadId: threadId
        )
        
        // Add basic metadata for user messages
        message.metadata = MessageMetadata()
        message.metadata?.contextLength = content.count
        message.metadata?.promptTokens = content.components(separatedBy: .whitespacesAndNewlines).count
        
        return message
    }
    
    /// Create an assistant message with enhanced metadata
    static func assistantMessage(
        content: String,
        model: String,
        confidence: Double,
        threadId: UUID? = nil,
        ensembleContributions: [String] = []
    ) -> ChatMessage {
        var message = ChatMessage(
            content: content,
            isFromUser: false,
            threadId: threadId
        )
        
        // Add comprehensive metadata for assistant messages
        var metadata = MessageMetadata()
        metadata.modelUsed = model
        metadata.confidence = confidence
        metadata.ensembleContributions = ensembleContributions
        metadata.responseTokens = content.components(separatedBy: .whitespacesAndNewlines).count
        metadata.temporalContext = TimeContext()
        
        message.metadata = metadata
        
        return message
    }
    
    /// Convert to analytics format
    var analyticsData: [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "content_length": content.count,
            "is_from_user": isFromUser,
            "timestamp": timestamp.timeIntervalSince1970,
            "has_quality_data": hasQualityAssessment
        ]
        
        if let metadata = metadata {
            data["model_used"] = metadata.modelUsed
            data["confidence"] = metadata.confidence
            data["ensemble_contributions"] = metadata.ensembleContributions
            data["response_time"] = metadata.inferenceTime
            data["memory_usage"] = metadata.memoryUsage
            data["completeness"] = metadata.completeness
        }
        
        if let quality = metadata?.qualityScore {
            data["overall_quality"] = quality.overallScore
            data["quality_tier"] = quality.qualityTier.rawValue
            data["meets_standards"] = quality.meetsProfessionalStandards
            data["uncertainty_count"] = quality.uncertaintyFactors.count
        }
        
        return data
    }
}

// MARK: - Quality-Aware Message Filtering

extension Array where Element == ChatMessage {
    /// Filter messages by quality tier
    func filterByQuality(_ tier: QualityTier) -> [ChatMessage] {
        return filter { $0.qualityTier == tier }
    }
    
    /// Filter messages by minimum quality score
    func filterByMinimumQuality(_ minimumScore: Double) -> [ChatMessage] {
        return filter { ($0.qualityScore ?? 0.0) >= minimumScore }
    }
    
    /// Get messages that meet professional standards
    var professionalQualityMessages: [ChatMessage] {
        return filter { $0.meetsProfessionalStandards }
    }
    
    /// Get messages with uncertainties
    var messagesWithUncertainties: [ChatMessage] {
        return filter { $0.hasUncertainties }
    }
    
    /// Calculate average quality score
    var averageQualityScore: Double {
        let qualityScores = compactMap { $0.qualityScore }
        guard !qualityScores.isEmpty else { return 0.0 }
        return qualityScores.reduce(0, +) / Double(qualityScores.count)
    }
    
    /// Get quality distribution
    var qualityDistribution: [QualityTier: Int] {
        let qualityTiers = compactMap { $0.qualityTier }
        var distribution: [QualityTier: Int] = [:]
        
        for tier in qualityTiers {
            distribution[tier, default: 0] += 1
        }
        
        return distribution
    }
}
