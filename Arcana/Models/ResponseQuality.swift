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
        case 0.6..<0.8:
            return .acceptable
        default:
            return .poor
        }
    }
    
    /// Compare with another ResponseQuality
    func compare(to other: ResponseQuality) -> QualityComparison {
        let scoreDifference = overallScore - other.overallScore
        
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
        
        let components = [
            "Overall: \(String(format: "%.1f", overallScore * 100))%",
            "Factual: \(String(format: "%.1f", factualAccuracy * 100))%",
            "Confidence: \(String(format: "%.1f", calibratedConfidence * 100))%",
            uncertaintyText,
            consensusText
        ].filter { !$0.isEmpty }
        
        return components.joined(separator: ", ")
    }
    
    /// ADDED: Generate improvement suggestions based on quality metrics
    func generateImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Overall score improvements
        if overallScore < 0.6 {
            suggestions.append("Consider revising the response for better clarity and completeness")
        }
        
        // Content quality improvements
        if contentQuality < 0.7 {
            suggestions.append("Enhance content structure and organization")
        }
        
        // Factual accuracy improvements
        if factualAccuracy < 0.8 {
            suggestions.append("Verify facts and add reliable sources")
        }
        
        // Relevance improvements
        if relevance < 0.7 {
            suggestions.append("Focus more directly on the user's specific question")
        }
        
        // Coherence improvements
        if coherence < 0.7 {
            suggestions.append("Improve logical flow and connection between ideas")
        }
        
        // Completeness improvements
        if completeness < 0.7 {
            suggestions.append("Provide more comprehensive coverage of the topic")
        }
        
        // Clarity improvements
        if clarity < 0.7 {
            suggestions.append("Use simpler language and clearer explanations")
        }
        
        // Confidence-related suggestions
        if calibratedConfidence < 0.6 {
            suggestions.append("Add confidence indicators and acknowledge uncertainties")
        }
        
        // Uncertainty-specific suggestions
        if uncertaintyScore > 0.5 {
            suggestions.append("Address identified uncertainties with additional context")
        }
        
        // Critical uncertainty handling
        if hasCriticalUncertainties {
            suggestions.append("⚠️ Review and resolve critical uncertainties before finalizing")
        }
        
        // Model-specific suggestions
        if modelContributions.count == 1 {
            suggestions.append("Consider using ensemble validation for improved accuracy")
        }
        
        return suggestions.isEmpty ? ["Response quality is good - no specific improvements needed"] : suggestions
    }
}

// MARK: - Quality Tiers

enum QualityTier: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .acceptable:
            return "Acceptable"
        case .poor:
            return "Poor"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent:
            return "🌟"
        case .good:
            return "✅"
        case .acceptable:
            return "👍"
        case .poor:
            return "⚠️"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .acceptable:
            return "orange"
        case .poor:
            return "red"
        }
    }
    
    var scoreThreshold: Double {
        switch self {
        case .excellent:
            return 0.9
        case .good:
            return 0.8
        case .acceptable:
            return 0.6
        case .poor:
            return 0.0
        }
    }
    
    /// ADDED: Create QualityTier from numerical score
    static func fromScore(_ score: Double) -> QualityTier {
        switch score {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .acceptable
        default:
            return .poor
        }
    }
    
    /// Get minimum score threshold for this tier
    var minimumScore: Double {
        switch self {
        case .excellent: return 0.9
        case .good: return 0.8
        case .acceptable: return 0.6
        case .poor: return 0.0
        }
    }
    
    /// Get maximum score threshold for this tier
    var maximumScore: Double {
        switch self {
        case .excellent: return 1.0
        case .good: return 0.899
        case .acceptable: return 0.799
        case .poor: return 0.599
        }
    }
    
    /// Check if score falls within this tier
    func contains(score: Double) -> Bool {
        return score >= minimumScore && score <= maximumScore
    }
}

// MARK: - Validation Level

enum ValidationLevel: String, Codable {
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    case research = "research"
    
    var displayName: String {
        return rawValue.capitalized
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
    
    /// ADDED: Create a failed quality assessment for error handling
    static func failed(error: String) -> ResponseQuality {
        let errorUncertainty = UncertaintyFactor(
            type: .modelLimitation,
            description: "Validation failed: \(error)",
            severity: 1.0,
            location: nil,
            detectedAt: Date(),
            confidence: 1.0
        )
        
        return ResponseQuality(
            overallScore: 0.0,
            contentQuality: 0.0,
            factualAccuracy: 0.0,
            relevance: 0.0,
            coherence: 0.0,
            completeness: 0.0,
            clarity: 0.0,
            rawConfidence: 0.0,
            calibratedConfidence: 0.0,
            uncertaintyFactors: [errorUncertainty],
            uncertaintyScore: 1.0,
            validationLevel: .basic,
            modelContributions: ["ValidationFailure"]
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
            "validation_level": validationLevel.rawValue,
            "model_contributions": modelContributions,
            "processing_time": processingTime,
            "meets_professional_standards": meetsProfessionalStandards,
            "has_critical_uncertainties": hasCriticalUncertainties
        ]
        
        if let consensus = consensusScore {
            data["consensus_score"] = consensus
        }
        
        if !uncertaintyFactors.isEmpty {
            data["uncertainty_factors"] = uncertaintyFactors.map { factor in
                [
                    "type": factor.type.rawValue,
                    "description": factor.description,
                    "severity": factor.severity,
                    "weighted_severity": factor.weightedSeverity
                ]
            }
        }
        
        return data
    }
    
    /// Create quality report for external systems
    var qualityReport: String {
        let report = """
        Quality Assessment Report
        ========================
        Overall Score: \(String(format: "%.1f%%", overallScore * 100))
        Quality Tier: \(qualityTier.displayName)
        
        Detailed Metrics:
        - Content Quality: \(String(format: "%.1f%%", contentQuality * 100))
        - Factual Accuracy: \(String(format: "%.1f%%", factualAccuracy * 100))
        - Relevance: \(String(format: "%.1f%%", relevance * 100))
        - Coherence: \(String(format: "%.1f%%", coherence * 100))
        - Completeness: \(String(format: "%.1f%%", completeness * 100))
        - Clarity: \(String(format: "%.1f%%", clarity * 100))
        
        Confidence Analysis:
        - Raw Confidence: \(String(format: "%.1f%%", rawConfidence * 100))
        - Calibrated Confidence: \(String(format: "%.1f%%", calibratedConfidence * 100))
        - Uncertainty Score: \(String(format: "%.1f%%", uncertaintyScore * 100))
        
        Validation:
        - Level: \(validationLevel.displayName)
        - Processing Time: \(String(format: "%.3f", processingTime))s
        - Models: \(modelContributions.joined(separator: ", "))
        
        Professional Standards: \(meetsProfessionalStandards ? "✅ Met" : "❌ Not Met")
        """
        
        return report
    }
}
