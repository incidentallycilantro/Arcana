//
// ResponseQuality.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Quality Assessment System
//

import Foundation

// MARK: - Response Quality Model

struct ResponseQuality: Codable, Hashable {
    // MARK: - Core Quality Metrics
    let overallScore: Double              // 0.0 to 1.0
    let contentQuality: Double            // Content structure and readability
    let factualAccuracy: Double           // Factual correctness assessment
    let relevance: Double                 // Relevance to the prompt
    let coherence: Double                 // Logical flow and consistency
    let completeness: Double              // How complete the response is
    let clarity: Double                   // How clear and understandable
    
    // MARK: - Confidence Metrics
    let rawConfidence: Double             // Model's raw confidence
    let calibratedConfidence: Double      // Calibrated confidence score
    let consensusScore: Double?           // Agreement between models (if ensemble)
    
    // MARK: - Uncertainty Analysis
    let uncertaintyFactors: [UncertaintyFactor]
    let uncertaintyScore: Double          // Overall uncertainty (0.0 = certain, 1.0 = very uncertain)
    
    // MARK: - Metadata
    let assessmentTimestamp: Date
    let validationLevel: ValidationLevel
    let modelContributions: [String]      // Models that contributed to this assessment
    let processingTime: TimeInterval
    
    init(
        overallScore: Double,
        contentQuality: Double,
        factualAccuracy: Double,
        relevance: Double,
        coherence: Double,
        completeness: Double,
        clarity: Double,
        rawConfidence: Double,
        calibratedConfidence: Double,
        consensusScore: Double? = nil,
        uncertaintyFactors: [UncertaintyFactor] = [],
        uncertaintyScore: Double = 0.0,
        assessmentTimestamp: Date = Date(),
        validationLevel: ValidationLevel = .standard,
        modelContributions: [String] = [],
        processingTime: TimeInterval = 0.0
    ) {
        // Clamp all scores between 0.0 and 1.0
        self.overallScore = min(max(overallScore, 0.0), 1.0)
        self.contentQuality = min(max(contentQuality, 0.0), 1.0)
        self.factualAccuracy = min(max(factualAccuracy, 0.0), 1.0)
        self.relevance = min(max(relevance, 0.0), 1.0)
        self.coherence = min(max(coherence, 0.0), 1.0)
        self.completeness = min(max(completeness, 0.0), 1.0)
        self.clarity = min(max(clarity, 0.0), 1.0)
        self.rawConfidence = min(max(rawConfidence, 0.0), 1.0)
        self.calibratedConfidence = min(max(calibratedConfidence, 0.0), 1.0)
        self.consensusScore = consensusScore.map { min(max($0, 0.0), 1.0) }
        self.uncertaintyFactors = uncertaintyFactors
        self.uncertaintyScore = min(max(uncertaintyScore, 0.0), 1.0)
        self.assessmentTimestamp = assessmentTimestamp
        self.validationLevel = validationLevel
        self.modelContributions = modelContributions
        self.processingTime = processingTime
    }
    
    // MARK: - Quality Assessment Methods
    
    /// Check if response meets professional standards
    var meetsProfessionalStandards: Bool {
        return overallScore >= 0.8 &&
               factualAccuracy >= 0.8 &&
               uncertaintyScore <= 0.3 &&
               !hasCriticalUncertainties
    }
    
    /// Check if response has critical uncertainties
    var hasCriticalUncertainties: Bool {
        return uncertaintyFactors.contains { $0.isCritical }
    }
    
    /// Get quality tier for UI display
    var qualityTier: QualityTier {
        switch overallScore {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.7..<0.8:
            return .fair
        case 0.6..<0.7:
            return .acceptable
        default:
            return .poor
        }
    }
    
    /// Get display-ready quality information
    var displayQuality: DisplayQuality {
        return DisplayQuality(
            tier: qualityTier,
            score: overallScore,
            confidence: calibratedConfidence,
            uncertaintyCount: uncertaintyFactors.count,
            criticalIssues: uncertaintyFactors.filter { $0.isCritical }.count
        )
    }
    
    /// Generate improvement suggestions based on quality metrics
    func generateImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if contentQuality < 0.7 {
            suggestions.append("Improve content structure and readability")
        }
        
        if factualAccuracy < 0.8 {
            suggestions.append("Verify factual claims and add sources")
        }
        
        if relevance < 0.7 {
            suggestions.append("Better address the original question")
        }
        
        if coherence < 0.7 {
            suggestions.append("Improve logical flow between ideas")
        }
        
        if completeness < 0.7 {
            suggestions.append("Provide more comprehensive coverage")
        }
        
        if clarity < 0.7 {
            suggestions.append("Use clearer language and explanations")
        }
        
        if hasCriticalUncertainties {
            suggestions.append("Address critical uncertainty factors")
        }
        
        return suggestions
    }
    
    /// Compare quality with another ResponseQuality
    func compare(with other: ResponseQuality) -> QualityComparison {
        let scoreDifference = self.overallScore - other.overallScore
        
        switch scoreDifference {
        case 0.3...:
            return .significantlyBetter
        case 0.2..<0.3:
            return .moderatelyBetter
        case 0.1..<0.2:
            return .slightlyBetter
        case -0.1..<0.1:
            return .equivalent
        case -0.2..<(-0.1):
            return .slightlyWorse
        case -0.3..<(-0.2):
            return .moderatelyWorse
        default:
            return .significantlyWorse
        }
    }
    
    /// Check if this quality is better than another
    func isBetterThan(_ other: ResponseQuality) -> Bool {
        // Weighted comparison considering multiple factors
        let thisWeightedScore = (overallScore * 0.4) +
                               (factualAccuracy * 0.3) +
                               (calibratedConfidence * 0.2) +
                               ((1.0 - uncertaintyScore) * 0.1)
        
        let otherWeightedScore = (other.overallScore * 0.4) +
                                (other.factualAccuracy * 0.3) +
                                (other.calibratedConfidence * 0.2) +
                                ((1.0 - other.uncertaintyScore) * 0.1)
        
        return thisWeightedScore > otherWeightedScore
    }
    
    /// Get detailed quality breakdown
    var detailedBreakdown: [String: Double] {
        return [
            "Overall Score": overallScore,
            "Content Quality": contentQuality,
            "Factual Accuracy": factualAccuracy,
            "Relevance": relevance,
            "Coherence": coherence,
            "Completeness": completeness,
            "Clarity": clarity,
            "Calibrated Confidence": calibratedConfidence,
            "Uncertainty Score": uncertaintyScore
        ]
    }
    
    /// Get quality summary for logging
    var qualitySummary: String {
        let uncertaintyText = uncertaintyFactors.isEmpty ? "No uncertainties" : "\(uncertaintyFactors.count) uncertainties"
        let consensusText = consensusScore.map { "Consensus: \(String(format: "%.1f", $0 * 100))%" } ?? ""
        
        return "Quality: \(String(format: "%.1f", overallScore * 100))% | " +
               "Confidence: \(String(format: "%.1f", calibratedConfidence * 100))% | " +
               "\(uncertaintyText) | \(consensusText)"
    }
}

// MARK: - Quality Tier Enumeration

enum QualityTier: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .excellent:
            return "🌟"
        case .good:
            return "✅"
        case .fair:
            return "⚠️"
        case .acceptable:
            return "🔶"
        case .poor:
            return "❌"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .acceptable:
            return "yellow"
        case .poor:
            return "red"
        }
    }
    
    var minimumScore: Double {
        switch self {
        case .excellent:
            return 0.9
        case .good:
            return 0.8
        case .fair:
            return 0.7
        case .acceptable:
            return 0.6
        case .poor:
            return 0.0
        }
    }
}

// MARK: - Display Quality for UI

struct DisplayQuality: Codable, Hashable {
    let tier: QualityTier
    let score: Double
    let confidence: Double
    let uncertaintyCount: Int
    let criticalIssues: Int
    
    var displayText: String {
        let scoreText = String(format: "%.0f%%", score * 100)
        let confidenceText = String(format: "%.0f%%", confidence * 100)
        
        if criticalIssues > 0 {
            return "\(tier.emoji) \(scoreText) (⚠️ \(criticalIssues) critical)"
        } else if uncertaintyCount > 0 {
            return "\(tier.emoji) \(scoreText) (\(uncertaintyCount) uncertainties)"
        } else {
            return "\(tier.emoji) \(scoreText) (Confidence: \(confidenceText))"
        }
    }
    
    var shortDisplayText: String {
        return "\(tier.emoji) \(String(format: "%.0f%%", score * 100))"
    }
    
    var isHighQuality: Bool {
        return tier == .excellent || tier == .good
    }
    
    var needsAttention: Bool {
        return criticalIssues > 0 || tier == .poor
    }
}

// MARK: - Factory Methods

extension ResponseQuality {
    /// Create a basic quality assessment with minimal metrics
    static func basic(
        overallScore: Double,
        confidence: Double
    ) -> ResponseQuality {
        return ResponseQuality(
            overallScore: overallScore,
            contentQuality: overallScore,
            factualAccuracy: overallScore,
            relevance: overallScore,
            coherence: overallScore,
            completeness: overallScore,
            clarity: overallScore,
            rawConfidence: confidence,
            calibratedConfidence: confidence,
            validationLevel: .basic
        )
    }
    
    /// Create a placeholder quality assessment
    static func placeholder() -> ResponseQuality {
        return ResponseQuality(
            overallScore: 0.7,
            contentQuality: 0.7,
            factualAccuracy: 0.7,
            relevance: 0.7,
            coherence: 0.7,
            completeness: 0.7,
            clarity: 0.7,
            rawConfidence: 0.7,
            calibratedConfidence: 0.7,
            validationLevel: .basic,
            modelContributions: ["Placeholder"]
        )
    }
    
    /// Create a high-quality assessment
    static func excellent(
        confidence: Double = 0.95,
        models: [String] = []
    ) -> ResponseQuality {
        return ResponseQuality(
            overallScore: 0.95,
            contentQuality: 0.95,
            factualAccuracy: 0.95,
            relevance: 0.95,
            coherence: 0.95,
            completeness: 0.95,
            clarity: 0.95,
            rawConfidence: confidence,
            calibratedConfidence: confidence,
            validationLevel: .comprehensive,
            modelContributions: models
        )
    }
}

// MARK: - Quality Analytics

extension ResponseQuality {
    /// Convert to analytics data
    var analyticsData: [String: Any] {
        var data: [String: Any] = [
            "overall_score": overallScore,
            "content_quality": contentQuality,
            "factual_accuracy": factualAccuracy,
            "relevance": relevance,
            "coherence": coherence,
            "completeness": completeness,
            "clarity": clarity,
            "calibrated_confidence": calibratedConfidence,
            "uncertainty_score": uncertaintyScore,
            "uncertainty_count": uncertaintyFactors.count,
            "critical_uncertainties": uncertaintyFactors.filter { $0.isCritical }.count,
            "quality_tier": qualityTier.rawValue,
            "meets_professional_standards": meetsProfessionalStandards,
            "validation_level": validationLevel.rawValue,
            "processing_time": processingTime,
            "model_count": modelContributions.count
        ]
        
        if let consensusScore = consensusScore {
            data["consensus_score"] = consensusScore
        }
        
        return data
    }
}

// MARK: - Array Extensions for Quality Analysis

extension Array where Element == ResponseQuality {
    /// Get average quality score
    var averageQualityScore: Double {
        guard !isEmpty else { return 0.0 }
        return reduce(0) { $0 + $1.overallScore } / Double(count)
    }
    
    /// Get quality distribution
    var qualityDistribution: [QualityTier: Int] {
        var distribution: [QualityTier: Int] = [:]
        
        for quality in self {
            distribution[quality.qualityTier, default: 0] += 1
        }
        
        return distribution
    }
    
    /// Filter by quality tier
    func filterByTier(_ tier: QualityTier) -> [ResponseQuality] {
        return filter { $0.qualityTier == tier }
    }
    
    /// Get high-quality responses
    var highQuality: [ResponseQuality] {
        return filter { $0.qualityTier == .excellent || $0.qualityTier == .good }
    }
    
    /// Get responses needing attention
    var needingAttention: [ResponseQuality] {
        return filter { quality in
            quality.hasCriticalUncertainties || quality.qualityTier == .poor
        }
    }
}
