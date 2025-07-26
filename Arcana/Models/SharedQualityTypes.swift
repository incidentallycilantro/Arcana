//
// SharedQualityTypes.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Centralized Quality and Temporal Type Definitions
//

import Foundation

// MARK: - Temporal Types (Codable versions to replace QuantumMemoryManager enums)

enum TimeOfDay: String, Codable, CaseIterable, Hashable {
    case earlyMorning = "early_morning"
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

enum DayOfWeek: String, Codable, CaseIterable, Hashable {
    case sunday = "sunday"
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
}

// MARK: - SINGLE SEASON DEFINITION (AUTHORITATIVE)
enum Season: String, Codable, CaseIterable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Quality Assessment Types

/// Centralized UncertaintyType definition - DO NOT DUPLICATE in other files
enum UncertaintyType: String, Codable, CaseIterable {
    case linguisticMarker = "linguistic_marker"
    case contradiction = "contradiction"
    case insufficientContext = "insufficient_context"
    case factualUncertainty = "factual_uncertainty"
    case temporalInconsistency = "temporal_inconsistency"
    case sourceReliability = "source_reliability"
    case modelLimitation = "model_limitation"
    case crossReferenceFailure = "cross_reference_failure"
    
    var displayName: String {
        switch self {
        case .linguisticMarker:
            return "Linguistic Uncertainty"
        case .contradiction:
            return "Internal Contradiction"
        case .insufficientContext:
            return "Insufficient Context"
        case .factualUncertainty:
            return "Factual Uncertainty"
        case .temporalInconsistency:
            return "Temporal Inconsistency"
        case .sourceReliability:
            return "Source Reliability"
        case .modelLimitation:
            return "Model Limitation"
        case .crossReferenceFailure:
            return "Cross-Reference Failure"
        }
    }
    
    var severityWeight: Double {
        switch self {
        case .linguisticMarker:
            return 0.3
        case .contradiction:
            return 0.9
        case .insufficientContext:
            return 0.6
        case .factualUncertainty:
            return 0.8
        case .temporalInconsistency:
            return 0.7
        case .sourceReliability:
            return 0.8
        case .modelLimitation:
            return 0.5
        case .crossReferenceFailure:
            return 0.7
        }
    }
}

struct UncertaintyFactor: Codable, Hashable {
    let type: UncertaintyType
    let description: String
    let severity: Double // 0.0 to 1.0
    let location: String?
    let detectedAt: Date
    let confidence: Double
    
    init(
        type: UncertaintyType,
        description: String,
        severity: Double,
        location: String? = nil,
        detectedAt: Date = Date(),
        confidence: Double = 0.8
    ) {
        self.type = type
        self.description = description
        self.severity = severity
        self.location = location
        self.detectedAt = detectedAt
        self.confidence = confidence
    }
    
    // ADDED: Missing weightedSeverity property that ResponseValidator expects
    var weightedSeverity: Double {
        return severity * type.severityWeight * confidence
    }
    
    var isCritical: Bool {
        return severity >= 0.8
    }
    
    var isModerate: Bool {
        return severity >= 0.5 && severity < 0.8
    }
    
    var isMinor: Bool {
        return severity < 0.5
    }
    
    var severityText: String {
        switch severity {
        case 0.8...1.0:
            return "Critical"
        case 0.6..<0.8:
            return "High"
        case 0.4..<0.6:
            return "Medium"
        case 0.2..<0.4:
            return "Low"
        default:
            return "Minimal"
        }
    }
}

// MARK: - Quality Comparison Types

enum QualityComparison: String, Codable {
    case significantlyBetter = "significantly_better"
    case moderatelyBetter = "moderately_better"
    case slightlyBetter = "slightly_better"
    case equivalent = "equivalent"
    case slightlyWorse = "slightly_worse"
    case moderatelyWorse = "moderately_worse"
    case significantlyWorse = "significantly_worse"
    
    var displayName: String {
        switch self {
        case .significantlyBetter:
            return "Significantly Better"
        case .moderatelyBetter:
            return "Moderately Better"
        case .slightlyBetter:
            return "Slightly Better"
        case .equivalent:
            return "Equivalent"
        case .slightlyWorse:
            return "Slightly Worse"
        case .moderatelyWorse:
            return "Moderately Worse"
        case .significantlyWorse:
            return "Significantly Worse"
        }
    }
    
    var emoji: String {
        switch self {
        case .significantlyBetter:
            return "🚀"
        case .moderatelyBetter:
            return "⬆️"
        case .slightlyBetter:
            return "↗️"
        case .equivalent:
            return "➡️"
        case .slightlyWorse:
            return "↘️"
        case .moderatelyWorse:
            return "⬇️"
        case .significantlyWorse:
            return "⬇️⬇️"
        }
    }
    
    var scoreDifference: Double {
        switch self {
        case .significantlyBetter:
            return 0.3
        case .moderatelyBetter:
            return 0.2
        case .slightlyBetter:
            return 0.1
        case .equivalent:
            return 0.0
        case .slightlyWorse:
            return -0.1
        case .moderatelyWorse:
            return -0.2
        case .significantlyWorse:
            return -0.3
        }
    }
}

// MARK: - Validation Types

enum ValidationLevel: String, Codable, CaseIterable {
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    case researchGrade = "research_grade"
    
    var displayName: String {
        switch self {
        case .basic:
            return "Basic"
        case .standard:
            return "Standard"
        case .comprehensive:
            return "Comprehensive"
        case .researchGrade:
            return "Research Grade"
        }
    }
    
    var description: String {
        switch self {
        case .basic:
            return "Quick format and length checks"
        case .standard:
            return "Content quality and coherence validation"
        case .comprehensive:
            return "Full quality assessment with uncertainty detection"
        case .researchGrade:
            return "Academic-level validation with fact-checking"
        }
    }
    
    var minimumConfidenceThreshold: Double {
        switch self {
        case .basic:
            return 0.5
        case .standard:
            return 0.7
        case .comprehensive:
            return 0.8
        case .researchGrade:
            return 0.9
        }
    }
}

// MARK: - Model Performance Types

struct ModelPerformanceProfile: Codable, Hashable {
    let modelName: String
    let averageConfidence: Double
    let averageResponseTime: TimeInterval
    let specialties: [String]
    let weaknesses: [String]
    let optimalTemperature: Double
    let recommendedMaxTokens: Int
    let factualAccuracyScore: Double
    let creativityScore: Double
    let reasoningScore: Double
    let codingScore: Double
    
    init(
        modelName: String,
        averageConfidence: Double = 0.8,
        averageResponseTime: TimeInterval = 2.0,
        specialties: [String] = [],
        weaknesses: [String] = [],
        optimalTemperature: Double = 0.7,
        recommendedMaxTokens: Int = 1024,
        factualAccuracyScore: Double = 0.8,
        creativityScore: Double = 0.7,
        reasoningScore: Double = 0.8,
        codingScore: Double = 0.7
    ) {
        self.modelName = modelName
        self.averageConfidence = averageConfidence
        self.averageResponseTime = averageResponseTime
        self.specialties = specialties
        self.weaknesses = weaknesses
        self.optimalTemperature = optimalTemperature
        self.recommendedMaxTokens = recommendedMaxTokens
        self.factualAccuracyScore = factualAccuracyScore
        self.creativityScore = creativityScore
        self.reasoningScore = reasoningScore
        self.codingScore = codingScore
    }
}

// MARK: - Quality Standards

struct QualityStandards {
    static let minimumAcceptableScore: Double = 0.6
    static let professionalStandardScore: Double = 0.8
    static let excellenceStandardScore: Double = 0.9
    
    static let maxUncertaintyFactors: Int = 3
    static let maxResponseTime: TimeInterval = 5.0
    static let minimumConfidence: Double = 0.7
    
    static func meetsProfessionalStandards(
        score: Double,
        uncertaintyCount: Int,
        confidence: Double?
    ) -> Bool {
        return score >= professionalStandardScore &&
               uncertaintyCount <= maxUncertaintyFactors &&
               (confidence ?? 0.0) >= minimumConfidence
    }
    
    static func getQualityGrade(score: Double) -> String {
        switch score {
        case excellenceStandardScore...1.0:
            return "Excellent"
        case professionalStandardScore..<excellenceStandardScore:
            return "Professional"
        case minimumAcceptableScore..<professionalStandardScore:
            return "Acceptable"
        default:
            return "Needs Improvement"
        }
    }
}

// MARK: - Response Provenance Types

struct ResponseProvenance: Codable, Hashable {
    let primaryModel: String
    let ensembleModels: [String]
    let validationEngine: String
    let generationTimestamp: Date
    let validationDuration: TimeInterval
    let qualityChecksPassed: Bool
    let factCheckingPerformed: Bool
    let confidenceCalibrated: Bool
    let ensembleStrategy: String?
    let consensusScore: Double?
    
    init(
        primaryModel: String,
        ensembleModels: [String] = [],
        validationEngine: String = "DefaultValidator",
        generationTimestamp: Date = Date(),
        validationDuration: TimeInterval = 0.0,
        qualityChecksPassed: Bool = false,
        factCheckingPerformed: Bool = false,
        confidenceCalibrated: Bool = false,
        ensembleStrategy: String? = nil,
        consensusScore: Double? = nil
    ) {
        self.primaryModel = primaryModel
        self.ensembleModels = ensembleModels
        self.validationEngine = validationEngine
        self.generationTimestamp = generationTimestamp
        self.validationDuration = validationDuration
        self.qualityChecksPassed = qualityChecksPassed
        self.factCheckingPerformed = factCheckingPerformed
        self.confidenceCalibrated = confidenceCalibrated
        self.ensembleStrategy = ensembleStrategy
        self.consensusScore = consensusScore
    }
    
    /// Check if provenance indicates high-quality response
    var indicatesHighQuality: Bool {
        return qualityChecksPassed &&
               factCheckingPerformed &&
               confidenceCalibrated &&
               ensembleModels.count > 1
    }
    
    /// Get human-readable generation summary
    var generationSummary: String {
        var components: [String] = []
        
        if ensembleModels.count > 1 {
            components.append("\(ensembleModels.count)-model ensemble")
        } else {
            components.append("Single model (\(primaryModel))")
        }
        
        if let strategy = ensembleStrategy {
            components.append(strategy)
        }
        
        if qualityChecksPassed {
            components.append("quality validated")
        }
        
        if factCheckingPerformed {
            components.append("fact-checked")
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Temporal Context (SINGLE AUTHORITATIVE DEFINITION)

struct TimeContext: Codable, Hashable {
    let timestamp: Date
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let season: Season
    let userTimezone: TimeZone?
    let isWeekend: Bool
    let isBusinessHours: Bool
    
    init(
        timestamp: Date = Date(),
        userTimezone: TimeZone? = nil
    ) {
        self.timestamp = timestamp
        self.userTimezone = userTimezone ?? TimeZone.current
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .weekday, .month], from: timestamp)
        
        // Determine time of day
        switch components.hour ?? 12 {
        case 5..<9:
            self.timeOfDay = .earlyMorning
        case 9..<12:
            self.timeOfDay = .morning
        case 12..<17:
            self.timeOfDay = .afternoon
        case 17..<21:
            self.timeOfDay = .evening
        default:
            self.timeOfDay = .night
        }
        
        // Determine day of week
        switch components.weekday ?? 1 {
        case 1: self.dayOfWeek = .sunday
        case 2: self.dayOfWeek = .monday
        case 3: self.dayOfWeek = .tuesday
        case 4: self.dayOfWeek = .wednesday
        case 5: self.dayOfWeek = .thursday
        case 6: self.dayOfWeek = .friday
        case 7: self.dayOfWeek = .saturday
        default: self.dayOfWeek = .monday
        }
        
        // Determine season
        switch components.month ?? 1 {
        case 12, 1, 2: self.season = .winter
        case 3, 4, 5: self.season = .spring
        case 6, 7, 8: self.season = .summer
        case 9, 10, 11: self.season = .autumn
        default: self.season = .spring
        }
        
        // Calculate weekend and business hours
        self.isWeekend = [.saturday, .sunday].contains(dayOfWeek)
        self.isBusinessHours = !isWeekend &&
                              (components.hour ?? 12) >= 9 &&
                              (components.hour ?? 12) < 17
    }
    
    var contextDescription: String {
        let timeText = timeOfDay.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        let dayText = dayOfWeek.rawValue.capitalized
        let seasonText = season.displayName
        
        return "\(timeText) on \(dayText) during \(seasonText)"
    }
    
    var isOptimalForWork: Bool {
        return timeOfDay == .morning || timeOfDay == .afternoon
    }
    
    var isOptimalForCreativity: Bool {
        return timeOfDay == .afternoon || timeOfDay == .evening
    }
}

// MARK: - Enhancement Tracking

struct ResponseEnhancement: Codable, Hashable {
    let enhancementType: EnhancementType
    let originalScore: Double
    let enhancedScore: Double
    let improvement: Double
    let enhancementDescription: String
    let appliedAt: Date
    
    init(
        enhancementType: EnhancementType,
        originalScore: Double,
        enhancedScore: Double,
        enhancementDescription: String
    ) {
        self.enhancementType = enhancementType
        self.originalScore = originalScore
        self.enhancedScore = enhancedScore
        self.improvement = enhancedScore - originalScore
        self.enhancementDescription = enhancementDescription
        self.appliedAt = Date()
    }
    
    var improvementPercentage: Double {
        guard originalScore > 0 else { return 0 }
        return (improvement / originalScore) * 100
    }
}

enum EnhancementType: String, Codable, CaseIterable {
    case ensembleProcessing = "ensemble_processing"
    case factChecking = "fact_checking"
    case confidenceCalibration = "confidence_calibration"
    case temporalOptimization = "temporal_optimization"
    case uncertaintyReduction = "uncertainty_reduction"
    case styleAdaptation = "style_adaptation"
    
    var displayName: String {
        switch self {
        case .ensembleProcessing:
            return "Ensemble Processing"
        case .factChecking:
            return "Fact Checking"
        case .confidenceCalibration:
            return "Confidence Calibration"
        case .temporalOptimization:
            return "Temporal Optimization"
        case .uncertaintyReduction:
            return "Uncertainty Reduction"
        case .styleAdaptation:
            return "Style Adaptation"
        }
    }
}
