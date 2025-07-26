//
// ResponseQuality.swift
// Arcana - Complete Quality Assessment System
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
// DEPENDENCIES: UnifiedTypes.swift (import all unified types)

import Foundation

// MARK: - Core Quality Assessment Structure

struct ResponseQuality: Codable, Hashable {
    
    // MARK: - Core Quality Metrics
    let overallScore: Double
    let contentQuality: Double
    let factualAccuracy: Double
    let relevance: Double
    let coherence: Double
    let completeness: Double
    let clarity: Double
    
    // MARK: - Confidence Assessment
    let rawConfidence: Double
    let calibratedConfidence: Double
    let uncertaintyScore: Double
    let uncertaintyFactors: [UncertaintyFactor]
    
    // MARK: - Validation Information
    let validationLevel: ValidationLevel
    let modelContributions: [String]
    let processingTime: TimeInterval
    let consensusScore: Double?
    
    // MARK: - Quality Standards Compliance
    let meetsProfessionalStandards: Bool
    let hasCriticalUncertainties: Bool
    let qualityTier: QualityTier
    
    // MARK: - Temporal Context
    let assessmentTimestamp: Date
    let temporalContext: TimeContext?
    
    // MARK: - Initializer
    
    init(
        overallScore: Double,
        contentQuality: Double,
        factualAccuracy: Double,
        relevance: Double,
        coherence: Double,
        completeness: Double,
        clarity: Double,
        rawConfidence: Double,
        calibratedConfidence: Double? = nil,
        uncertaintyFactors: [UncertaintyFactor] = [],
        validationLevel: ValidationLevel = .standard,
        modelContributions: [String] = [],
        processingTime: TimeInterval = 0.0,
        consensusScore: Double? = nil,
        temporalContext: TimeContext? = nil
    ) {
        // Clamp all scores to valid range [0.0, 1.0]
        self.overallScore = min(max(overallScore, 0.0), 1.0)
        self.contentQuality = min(max(contentQuality, 0.0), 1.0)
        self.factualAccuracy = min(max(factualAccuracy, 0.0), 1.0)
        self.relevance = min(max(relevance, 0.0), 1.0)
        self.coherence = min(max(coherence, 0.0), 1.0)
        self.completeness = min(max(completeness, 0.0), 1.0)
        self.clarity = min(max(clarity, 0.0), 1.0)
        self.rawConfidence = min(max(rawConfidence, 0.0), 1.0)
        
        // Calculate calibrated confidence if not provided
        if let calibrated = calibratedConfidence {
            self.calibratedConfidence = min(max(calibrated, 0.0), 1.0)
        } else {
            self.calibratedConfidence = self.calculateCalibratedConfidence(
                raw: self.rawConfidence,
                validation: validationLevel,
                uncertainties: uncertaintyFactors
            )
        }
        
        // Calculate uncertainty score
        self.uncertaintyScore = ResponseQuality.calculateUncertaintyScore(uncertaintyFactors)
        self.uncertaintyFactors = uncertaintyFactors
        
        // Store validation information
        self.validationLevel = validationLevel
        self.modelContributions = modelContributions
        self.processingTime = max(processingTime, 0.0)
        self.consensusScore = consensusScore
        
        // Determine quality standards compliance
        self.meetsProfessionalStandards = QualityStandards.meetsProfessionalStandards(
            score: self.overallScore,
            uncertaintyCount: uncertaintyFactors.count,
            confidence: self.calibratedConfidence
        )
        
        self.hasCriticalUncertainties = uncertaintyFactors.contains { factor in
            factor.severity > 0.8 || factor.type == .contradiction
        }
        
        self.qualityTier = QualityStandards.getQualityTier(score: self.overallScore)
        
        // Store temporal information
        self.assessmentTimestamp = Date()
        self.temporalContext = temporalContext ?? TimeContext()
    }
    
    // MARK: - Confidence Calibration
    
    private func calculateCalibratedConfidence(
        raw: Double,
        validation: ValidationLevel,
        uncertainties: [UncertaintyFactor]
    ) -> Double {
        var calibrated = raw * validation.confidenceMultiplier
        
        // Apply uncertainty penalties
        for uncertainty in uncertainties {
            let penalty = uncertainty.weightedSeverity * 0.2
            calibrated = max(calibrated - penalty, 0.0)
        }
        
        return min(calibrated, 1.0)
    }
    
    private static func calculateUncertaintyScore(_ factors: [UncertaintyFactor]) -> Double {
        guard !factors.isEmpty else { return 0.0 }
        
        let totalWeightedSeverity = factors.reduce(0.0) { sum, factor in
            sum + factor.weightedSeverity
        }
        
        return min(totalWeightedSeverity / Double(factors.count), 1.0)
    }
    
    // MARK: - Quality Analysis Methods
    
    /// Generate human-readable quality summary
    var qualitySummary: String {
        let grade = QualityStandards.getQualityGrade(overallScore)
        let percentage = String(format: "%.1f%%", overallScore * 100)
        
        return "\(grade) (\(percentage)) - \(qualityTier.displayName) tier"
    }
    
    /// Get detailed breakdown of quality metrics
    var detailedBreakdown: [String: Double] {
        return [
            "overall": overallScore,
            "content": contentQuality,
            "accuracy": factualAccuracy,
            "relevance": relevance,
            "coherence": coherence,
            "completeness": completeness,
            "clarity": clarity,
            "confidence": calibratedConfidence,
            "uncertainty": uncertaintyScore
        ]
    }
    
    /// Generate improvement suggestions based on weak areas
    func generateImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // Check individual metrics for improvement opportunities
        if contentQuality < 0.7 {
            suggestions.append("Enhance content depth and substance")
        }
        
        if factualAccuracy < 0.8 {
            suggestions.append("Verify factual claims and add sources")
        }
        
        if relevance < 0.7 {
            suggestions.append("Better align response with user's specific question")
        }
        
        if coherence < 0.7 {
            suggestions.append("Improve logical flow and structure")
        }
        
        if completeness < 0.7 {
            suggestions.append("Address all aspects of the user's request")
        }
        
        if clarity < 0.7 {
            suggestions.append("Simplify language and improve readability")
        }
        
        if calibratedConfidence < 0.6 {
            suggestions.append("Increase confidence through better validation")
        }
        
        // Add uncertainty-specific suggestions
        for factor in uncertaintyFactors where factor.severity > 0.6 {
            if let suggestion = factor.suggestion {
                suggestions.append(suggestion)
            }
        }
        
        // If no specific issues found but score is low
        if suggestions.isEmpty && overallScore < 0.7 {
            suggestions.append("General improvement needed across all quality dimensions")
        }
        
        return suggestions
    }
    
    /// Check if response meets specific quality threshold
    func meetsThreshold(_ threshold: Double) -> Bool {
        return overallScore >= threshold
    }
    
    /// Compare quality with another ResponseQuality instance
    func compare(to other: ResponseQuality) -> QualityComparison {
        return QualityComparison(
            first: self.overallScore,
            second: other.overallScore
        )
    }
    
    /// Check if this quality is better than another
    func isBetterThan(_ other: ResponseQuality) -> Bool {
        return self.overallScore > other.overallScore
    }
    
    // MARK: - Export and Reporting
    
    /// Export quality data for external systems
    func exportData() -> [String: Any] {
        var data: [String: Any] = [
            "overall_score": overallScore,
            "quality_tier": qualityTier.rawValue,
            "meets_professional_standards": meetsProfessionalStandards,
            "detailed_metrics": detailedBreakdown,
            "raw_confidence": rawConfidence,
            "calibrated_confidence": calibratedConfidence,
            "uncertainty_score": uncertaintyScore,
            "validation_level": validationLevel.rawValue,
            "model_contributions": modelContributions,
            "processing_time": processingTime,
            "has_critical_uncertainties": hasCriticalUncertainties,
            "assessment_timestamp": assessmentTimestamp.timeIntervalSince1970
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
        
        if let temporal = temporalContext {
            data["temporal_context"] = [
                "time_of_day": temporal.timeOfDay.rawValue,
                "circadian_phase": temporal.circadianPhase.rawValue,
                "season": temporal.season.rawValue,
                "energy_level": temporal.energyLevel,
                "cognitive_optimality": temporal.cognitiveOptimality
            ]
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

// MARK: - Static Factory Methods

extension ResponseQuality {
    
    /// Create a high-quality response assessment
    static func excellentQuality(
        confidence: Double = 0.95,
        modelContributions: [String] = ["Enhanced Intelligence"],
        processingTime: TimeInterval = 1.0
    ) -> ResponseQuality {
        return ResponseQuality(
            overallScore: 0.92,
            contentQuality: 0.95,
            factualAccuracy: 0.93,
            relevance: 0.96,
            coherence: 0.94,
            completeness: 0.91,
            clarity: 0.93,
            rawConfidence: confidence,
            uncertaintyFactors: [],
            validationLevel: .comprehensive,
            modelContributions: modelContributions,
            processingTime: processingTime
        )
    }
    
    /// Create a standard quality response assessment
    static func standardQuality(
        confidence: Double = 0.8,
        uncertainties: [UncertaintyFactor] = [],
        modelContributions: [String] = ["Standard Intelligence"],
        processingTime: TimeInterval = 2.0
    ) -> ResponseQuality {
        return ResponseQuality(
            overallScore: 0.75,
            contentQuality: 0.78,
            factualAccuracy: 0.8,
            relevance: 0.82,
            coherence: 0.76,
            completeness: 0.73,
            clarity: 0.79,
            rawConfidence: confidence,
            uncertaintyFactors: uncertainties,
            validationLevel: .standard,
            modelContributions: modelContributions,
            processingTime: processingTime
        )
    }
    
    /// Create a basic quality response assessment
    static func basicQuality(
        confidence: Double = 0.6,
        uncertainties: [UncertaintyFactor] = [],
        modelContributions: [String] = ["Basic Intelligence"],
        processingTime: TimeInterval = 0.5
    ) -> ResponseQuality {
        return ResponseQuality(
            overallScore: 0.65,
            contentQuality: 0.68,
            factualAccuracy: 0.7,
            relevance: 0.72,
            coherence: 0.63,
            completeness: 0.61,
            clarity: 0.66,
            rawConfidence: confidence,
            uncertaintyFactors: uncertainties,
            validationLevel: .basic,
            modelContributions: modelContributions,
            processingTime: processingTime
        )
    }
}

// MARK: - Quality Metrics Utilities

struct QualityMetrics {
    
    /// Calculate weighted average of multiple quality scores
    static func averageQuality(_ qualities: [ResponseQuality], weights: [Double]? = nil) -> ResponseQuality? {
        guard !qualities.isEmpty else { return nil }
        
        let actualWeights = weights ?? Array(repeating: 1.0, count: qualities.count)
        guard qualities.count == actualWeights.count else { return nil }
        
        let totalWeight = actualWeights.reduce(0, +)
        guard totalWeight > 0 else { return nil }
        
        let normalizedWeights = actualWeights.map { $0 / totalWeight }
        
        var weightedOverall = 0.0
        var weightedContent = 0.0
        var weightedAccuracy = 0.0
        var weightedRelevance = 0.0
        var weightedCoherence = 0.0
        var weightedCompleteness = 0.0
        var weightedClarity = 0.0
        var weightedConfidence = 0.0
        
        for (index, quality) in qualities.enumerated() {
            let weight = normalizedWeights[index]
            weightedOverall += quality.overallScore * weight
            weightedContent += quality.contentQuality * weight
            weightedAccuracy += quality.factualAccuracy * weight
            weightedRelevance += quality.relevance * weight
            weightedCoherence += quality.coherence * weight
            weightedCompleteness += quality.completeness * weight
            weightedClarity += quality.clarity * weight
            weightedConfidence += quality.calibratedConfidence * weight
        }
        
        // Combine uncertainty factors
        let allUncertainties = qualities.flatMap { $0.uncertaintyFactors }
        let uniqueUncertainties = Array(Set(allUncertainties))
        
        // Use highest validation level
        let maxValidationLevel = qualities.map { $0.validationLevel }.max { a, b in
            ValidationLevel.allCases.firstIndex(of: a)! < ValidationLevel.allCases.firstIndex(of: b)!
        } ?? .standard
        
        // Combine model contributions
        let allModels = qualities.flatMap { $0.modelContributions }
        let uniqueModels = Array(Set(allModels))
        
        // Average processing time
        let avgProcessingTime = qualities.reduce(0.0) { $0 + $1.processingTime } / Double(qualities.count)
        
        return ResponseQuality(
            overallScore: weightedOverall,
            contentQuality: weightedContent,
            factualAccuracy: weightedAccuracy,
            relevance: weightedRelevance,
            coherence: weightedCoherence,
            completeness: weightedCompleteness,
            clarity: weightedClarity,
            rawConfidence: weightedConfidence,
            calibratedConfidence: weightedConfidence,
            uncertaintyFactors: uniqueUncertainties,
            validationLevel: maxValidationLevel,
            modelContributions: uniqueModels,
            processingTime: avgProcessingTime
        )
    }
    
    /// Find the best quality from a collection
    static func bestQuality(from qualities: [ResponseQuality]) -> ResponseQuality? {
        return qualities.max { a, b in
            a.overallScore < b.overallScore
        }
    }
    
    /// Filter qualities that meet minimum standards
    static func filterByStandards(_ qualities: [ResponseQuality], minimum: Double = 0.7) -> [ResponseQuality] {
        return qualities.filter { $0.meetsThreshold(minimum) }
    }
}
