//
// ChatMessage.swift
// Arcana - Enhanced message model with quality metadata
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var isFromUser: Bool
    let timestamp: Date
    var threadId: UUID?
    
    // MARK: - Revolutionary Quality Metadata
    var metadata: MessageMetadata?
    
    init(
        content: String,
        isFromUser: Bool,
        threadId: UUID? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.threadId = threadId
        self.timestamp = timestamp
    }
    
    // MARK: - Quality Assessment Properties
    
    /// Get the quality assessment if available
    var qualityScore: Double? {
        return metadata?.qualityScore?.overallScore
    }
    
    /// Get the quality tier for this message
    var qualityTier: QualityTier {
        guard let quality = metadata?.qualityScore else { return .unknown }
        return quality.qualityTier
    }
    
    /// Check if message has quality assessment
    var hasQualityAssessment: Bool {
        return metadata?.qualityScore != nil
    }
    
    /// Get confidence score if available
    var confidenceScore: Double? {
        return metadata?.confidence
    }
    
    /// Check if message meets professional standards
    var meetsProfessionalStandards: Bool {
        return metadata?.qualityScore?.meetsProfessionalStandards ?? false
    }
    
    /// Get uncertainty factors count
    var uncertaintyFactorCount: Int {
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
            cacheHitRate: cacheHitRate ?? 0
        )
    }
    
    /// Get ensemble summary
    var ensembleSummary: String? {
        guard let contributions = ensembleContributions,
              let strategy = ensembleStrategy else {
            return nil
        }
        
        return "\(contributions.count) models using \(strategy)"
    }
    
    /// Get validation status
    var isValidated: Bool {
        return validatedBy != nil && validationTimestamp != nil
    }
    
    /// Get completeness score
    var completeness: Double {
        var score = 0.0
        let totalFields = 12.0
        
        if modelUsed != nil { score += 1 }
        if confidence != nil { score += 1 }
        if qualityScore != nil { score += 1 }
        if ensembleContributions != nil { score += 1 }
        if temporalContext != nil { score += 1 }
        if validatedBy != nil { score += 1 }
        if inferenceTime != nil { score += 1 }
        if memoryUsage != nil { score += 1 }
        if cacheHitRate != nil { score += 1 }
        if contextLength != nil { score += 1 }
        if promptTokens != nil { score += 1 }
        if responseTokens != nil { score += 1 }
        
        return score / totalFields
    }
}

// MARK: - Performance Analysis Types

struct PerformanceSummary: Codable, Hashable {
    let responseTime: TimeInterval
    let confidence: Double
    let memoryUsage: Int
    let cacheHitRate: Double
    
    var performanceGrade: PerformanceGrade {
        let timeScore = responseTime < 1.0 ? 1.0 : (responseTime < 5.0 ? 0.7 : 0.4)
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
        metadata.temporalContext = TimeContext(
            hour: Calendar.current.component(.hour, from: Date()),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            season: .spring, // Default to spring for now
            energyLevel: 0.8
        )
        
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
        return filter { ($0.qualityScore ?? 0) >= minimumScore }
    }
    
    /// Get messages that meet professional standards
    func professionalQualityMessages() -> [ChatMessage] {
        return filter { $0.meetsProfessionalStandards }
    }
    
    /// Sort by quality score (descending)
    func sortedByQuality() -> [ChatMessage] {
        return sorted { ($0.qualityScore ?? 0) > ($1.qualityScore ?? 0) }
    }
    
    /// Get quality statistics for the message array
    var qualityStatistics: MessageQualityStatistics {
        let messagesWithQuality = self.filter { $0.hasQualityAssessment }
        let totalMessages = messagesWithQuality.count
        
        guard totalMessages > 0 else {
            return MessageQualityStatistics(
                totalMessages: self.count,
                messagesWithQuality: 0,
                averageQuality: 0,
                professionalStandardsRate: 0,
                qualityDistribution: [:]
            )
        }
        
        let totalQuality = messagesWithQuality.compactMap { $0.qualityScore }.reduce(0, +)
        let averageQuality = totalQuality / Double(totalMessages)
        
        let professionalMessages = messagesWithQuality.filter { $0.meetsProfessionalStandards }
        let professionalRate = Double(professionalMessages.count) / Double(totalMessages)
        
        var distribution: [QualityTier: Int] = [:]
        for message in messagesWithQuality {
            distribution[message.qualityTier, default: 0] += 1
        }
        
        return MessageQualityStatistics(
            totalMessages: self.count,
            messagesWithQuality: totalMessages,
            averageQuality: averageQuality,
            professionalStandardsRate: professionalRate,
            qualityDistribution: distribution
        )
    }
}

// MARK: - Quality Statistics

struct MessageQualityStatistics {
    let totalMessages: Int
    let messagesWithQuality: Int
    let averageQuality: Double
    let professionalStandardsRate: Double
    let qualityDistribution: [QualityTier: Int]
    
    var qualityAssessmentRate: Double {
        return totalMessages > 0 ? Double(messagesWithQuality) / Double(totalMessages) : 0
    }
    
    var topTierRate: Double {
        let topTierCount = qualityDistribution[.exceptional, default: 0] + qualityDistribution[.high, default: 0]
        return messagesWithQuality > 0 ? Double(topTierCount) / Double(messagesWithQuality) : 0
    }
}
