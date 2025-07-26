//
// ChatMessage.swift
// Arcana - Enhanced Chat Message Model with Revolutionary Quality Metadata
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Codable, Hashable {
    var id = UUID() // FIXED: Changed from let to var to resolve Codable warning
    var content: String
    var isFromUser: Bool
    var timestamp: Date = Date()
    var threadId: UUID?
    var metadata: MessageMetadata?
    
    // MARK: - Message Role
    
    enum Role: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "Assistant"
            case .system: return "System"
            }
        }
    }
    
    var role: Role {
        return isFromUser ? .user : .assistant
    }
    
    // MARK: - Initializers
    
    init(content: String, isFromUser: Bool, threadId: UUID? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.threadId = threadId
        
        // Initialize metadata for assistant messages
        if !isFromUser {
            self.metadata = MessageMetadata()
        }
    }
    
    // MARK: - Quality Assessment Properties
    
    /// Get overall quality score from metadata
    var qualityScore: Double? {
        return metadata?.qualityScore?.overallScore
    }
    
    /// Get quality tier from metadata
    var qualityTier: QualityTier {
        guard let score = qualityScore else { return .acceptable }
        return QualityTier.fromScore(score) // FIXED: Now using the correct static method
    }
    
    /// Check if message has quality assessment
    var hasQualityAssessment: Bool {
        return metadata?.qualityScore != nil
    }
    
    /// Check if message meets professional standards
    var meetsProfessionalStandards: Bool {
        guard let quality = metadata?.qualityScore else { return false }
        return quality.meetsProfessionalStandards
    }
    
    /// Get uncertainty factors count
    var uncertaintyFactorCount: Int {
        return metadata?.qualityScore?.uncertaintyFactors.count ?? 0
    }
    
    /// Get quality improvement suggestions
    var improvementSuggestions: [String] {
        return metadata?.qualityScore?.generateImprovementSuggestions() ?? [] // FIXED: Now using the correct method
    }
    
    // MARK: - Quality Comparison
    
    /// Compare quality with another message
    func compareQuality(with other: ChatMessage) -> QualityComparison? {
        guard let currentQuality = self.metadata?.qualityScore,
              let otherQuality = other.metadata?.qualityScore else {
            return nil
        }
        
        return currentQuality.compare(to: otherQuality) // FIXED: Changed 'with:' to 'to:'
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

// FIXED: UUID Codable warning - exclude id from decoding
extension ChatMessage {
    enum CodingKeys: String, CodingKey {
        case content, isFromUser, timestamp, threadId, metadata
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
    var confidence: Double?                       // Calibrated confidence score
    var ensembleContributions: [String]?         // Models that contributed
    var ensembleStrategy: String?                // Strategy used for ensemble
    var temporalContext: TimeContext?            // Time-based context information
    var validatedBy: String?                     // Validation engine used
    var validationTimestamp: Date?               // When validation occurred
    var lastQualityUpdate: Date?                 // Last quality assessment update
    
    // MARK: - Advanced Metadata
    var inferenceTime: TimeInterval?             // Time taken for inference
    var memoryUsage: Int?                        // Memory used during generation
    var completeness: Double?                    // Response completeness score
    var responseTokens: Int?                     // Number of tokens in response
    var ensembleConsensus: Double?               // Agreement between models
    var factCheckingResults: [String]?           // Fact-checking outcomes
    var uncertaintyFlags: [String]?              // Identified uncertainty markers
    var qualityVersion: String?                  // Quality assessment version
    
    init() {
        // Initialize with basic defaults
        self.confidence = 0.7
        self.completeness = 0.8
        self.qualityVersion = "1.0"
    }
}

// MARK: - Factory Methods

extension ChatMessage {
    /// Create user message
    static func userMessage(
        content: String,
        threadId: UUID? = nil
    ) -> ChatMessage {
        return ChatMessage(
            content: content,
            isFromUser: true,
            threadId: threadId
        )
    }
    
    /// Create assistant message with enhanced metadata
    static func assistantMessage(
        content: String,
        threadId: UUID? = nil,
        model: String = "Default",
        confidence: Double? = nil,
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
    
    /// Get quality distribution
    func qualityDistribution() -> [QualityTier: Int] {
        var distribution: [QualityTier: Int] = [:]
        
        for tier in QualityTier.allCases {
            distribution[tier] = 0
        }
        
        for message in self {
            let tier = message.qualityTier
            distribution[tier, default: 0] += 1
        }
        
        return distribution
    }
}

// MARK: - Sample Data

extension ChatMessage {
    static func sampleMessages(for threadId: UUID) -> [ChatMessage] {
        return [
            ChatMessage.userMessage(
                content: "Can you help me understand the key concepts of quantum computing?",
                threadId: threadId
            ),
            ChatMessage.assistantMessage(
                content: "Quantum computing is a revolutionary computing paradigm that leverages quantum mechanical phenomena like superposition and entanglement to process information. Here are the key concepts:\n\n1. **Qubits**: Unlike classical bits that can only be 0 or 1, qubits can exist in superposition of both states simultaneously.\n\n2. **Superposition**: This allows quantum computers to explore multiple solution paths simultaneously.\n\n3. **Entanglement**: Qubits can be correlated in ways that classical particles cannot, enabling powerful quantum algorithms.",
                threadId: threadId,
                model: "Enhanced Intelligence",
                confidence: 0.92,
                ensembleContributions: ["GPT-4", "Claude-3", "Gemini-Pro"]
            ),
            ChatMessage.userMessage(
                content: "What are some practical applications?",
                threadId: threadId
            ),
            ChatMessage.assistantMessage(
                content: "Quantum computing has several emerging practical applications:\n\n**Current Applications:**\n- Cryptography and security\n- Financial modeling and risk analysis\n- Drug discovery and molecular simulation\n- Optimization problems in logistics\n\n**Future Applications:**\n- Machine learning acceleration\n- Climate modeling\n- Materials science research\n- Artificial intelligence enhancement\n\nMost applications are still in research phases, but we're seeing real progress in specialized areas like quantum chemistry simulations.",
                threadId: threadId,
                model: "Enhanced Intelligence",
                confidence: 0.88,
                ensembleContributions: ["GPT-4", "Claude-3"]
            )
        ]
    }
}
