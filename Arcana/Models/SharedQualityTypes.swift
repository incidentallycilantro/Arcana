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
    case fall = "fall"
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
    let confidence: Double
    
    init(type: UncertaintyType, description: String, severity: Double, location: String? = nil, confidence: Double = 0.8) {
        self.type = type
        self.description = description
        self.severity = severity
        self.location = location
        self.confidence = confidence
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
    
    var weightedSeverity: Double {
        return severity * type.severityWeight
    }
    
    var displaySeverity: String {
        if isCritical {
            return "Critical"
        } else if isModerate {
            return "Moderate"
        } else {
            return "Minor"
        }
    }
}

// MARK: - Response Provenance

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
        let hour = calendar.component(.hour, from: timestamp)
        let weekday = calendar.component(.weekday, from: timestamp)
        let month = calendar.component(.month, from: timestamp)
        
        // Determine time of day
        switch hour {
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
        switch weekday {
        case 1: self.dayOfWeek = .sunday
        case 2: self.dayOfWeek = .monday
        case 3: self.dayOfWeek = .tuesday
        case 4: self.dayOfWeek = .wednesday
        case 5: self.dayOfWeek = .thursday
        case 6: self.dayOfWeek = .friday
        case 7: self.dayOfWeek = .saturday
        default: self.dayOfWeek = .sunday
        }
        
        // Determine season
        switch month {
        case 3, 4, 5: self.season = .spring
        case 6, 7, 8: self.season = .summer
        case 9, 10, 11: self.season = .fall
        default: self.season = .winter
        }
        
        self.isWeekend = calendar.isDateInWeekend(timestamp)
        self.isBusinessHours = hour >= 9 && hour < 17 && !self.isWeekend
    }
    
    // MARK: - Convenience Properties
    
    var contextualDescription: String {
        var components: [String] = []
        
        components.append(timeOfDay.rawValue.replacingOccurrences(of: "_", with: " "))
        components.append("on")
        components.append(dayOfWeek.rawValue)
        
        if isWeekend {
            components.append("(weekend)")
        }
        
        components.append("in")
        components.append(season.rawValue)
        
        return components.joined(separator: " ").capitalized
    }
    
    var isOptimalForFocus: Bool {
        return timeOfDay == .morning || (timeOfDay == .afternoon && !isWeekend)
    }
    
    var isOptimalForCreativity: Bool {
        return timeOfDay == .afternoon || timeOfDay == .evening
    }
    
    var energyLevel: Double {
        switch timeOfDay {
        case .earlyMorning: return 0.3
        case .morning: return 0.9
        case .afternoon: return 0.8
        case .evening: return 0.6
        case .night: return 0.2
        }
    }
    
    /// Determine if this is an optimal time for complex reasoning
    var isOptimalForReasoning: Bool {
        return timeOfDay == .morning || timeOfDay == .afternoon
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
            return "Equivalent Quality"
        case .slightlyWorse:
            return "Slightly Worse"
        case .moderatelyWorse:
            return "Moderately Worse"
        case .significantlyWorse:
            return "Significantly Worse"
        }
    }
    
    var scoreDelta: Double {
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

// MARK: - Performance Summary

struct PerformanceSummary: Codable {
    let responseTime: TimeInterval
    let confidence: Double
    let memoryUsage: Int
    let cacheHitRate: Double
    
    var performanceGrade: String {
        let score = calculatePerformanceScore()
        switch score {
        case 0.9...1.0: return "Excellent"
        case 0.7..<0.9: return "Good"
        case 0.5..<0.7: return "Average"
        case 0.3..<0.5: return "Below Average"
        default: return "Poor"
        }
    }
    
    private func calculatePerformanceScore() -> Double {
        let timeScore = responseTime < 2.0 ? 1.0 : max(0.0, 1.0 - (responseTime - 2.0) / 10.0)
        let confidenceScore = confidence
        let cacheScore = cacheHitRate
        
        return (timeScore + confidenceScore + cacheScore) / 3.0
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
}

// MARK: - Quality Metrics

struct QualityMetrics: Codable {
    let accuracyScore: Double
    let completenessScore: Double
    let clarityScore: Double
    let relevanceScore: Double
    let consistencyScore: Double
    
    var overallScore: Double {
        return (accuracyScore + completenessScore + clarityScore + relevanceScore + consistencyScore) / 5.0
    }
    
    var topStrength: String {
        let scores = [
            ("Accuracy", accuracyScore),
            ("Completeness", completenessScore),
            ("Clarity", clarityScore),
            ("Relevance", relevanceScore),
            ("Consistency", consistencyScore)
        ]
        
        return scores.max(by: { $0.1 < $1.1 })?.0 ?? "Unknown"
    }
    
    var improvementAreas: [String] {
        let scores = [
            ("Accuracy", accuracyScore),
            ("Completeness", completenessScore),
            ("Clarity", clarityScore),
            ("Relevance", relevanceScore),
            ("Consistency", consistencyScore)
        ]
        
        return scores.filter { $0.1 < 0.7 }.map { $0.0 }
    }
}
