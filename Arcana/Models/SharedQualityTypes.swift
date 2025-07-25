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

enum Season: String, Codable, CaseIterable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
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
    let location: String? // Where in the response this uncertainty was detected
    let confidence: Double // How confident we are about this uncertainty
    
    init(
        type: UncertaintyType,
        description: String,
        severity: Double,
        location: String? = nil,
        confidence: Double = 0.8
    ) {
        self.type = type
        self.description = description
        self.severity = min(max(severity, 0.0), 1.0) // Clamp between 0 and 1
        self.location = location
        self.confidence = min(max(confidence, 0.0), 1.0)
    }
    
    /// Calculate weighted severity based on type and individual severity
    var weightedSeverity: Double {
        return severity * type.severityWeight
    }
    
    /// Determine if this uncertainty is critical
    var isCritical: Bool {
        return weightedSeverity > 0.7
    }
}

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

// MARK: - Temporal Context

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
        default: self.dayOfWeek = .monday
        }
        
        // Determine season (Northern Hemisphere)
        switch month {
        case 3...5: self.season = .spring
        case 6...8: self.season = .summer
        case 9...11: self.season = .fall
        default: self.season = .winter
        }
        
        // Calculate derived properties
        self.isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        self.isBusinessHours = hour >= 9 && hour < 17 && !isWeekend
    }
    
    /// Get a human-readable time description
    var contextDescription: String {
        var components: [String] = []
        
        components.append(timeOfDay.rawValue.replacingOccurrences(of: "_", with: " "))
        components.append("on \(dayOfWeek.rawValue)")
        
        if isWeekend {
            components.append("(weekend)")
        }
        
        components.append("in \(season.rawValue)")
        
        return components.joined(separator: " ")
    }
    
    /// Determine if this is an optimal time for complex reasoning
    var isOptimalForReasoning: Bool {
        // Morning and afternoon are generally better for complex tasks
        return timeOfDay == .morning || timeOfDay == .afternoon
    }
    
    /// Determine if this is an optimal time for creative tasks
    var isOptimalForCreativity: Bool {
        // Evening and night can be good for creative work
        return timeOfDay == .evening || timeOfDay == .night
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
        codingScore: Double = 0.6
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
    
    /// Get overall capability score
    var overallCapability: Double {
        return (factualAccuracyScore + creativityScore + reasoningScore + codingScore) / 4.0
    }
    
    /// Get recommended use cases based on scores
    var recommendedUseCases: [String] {
        var useCases: [String] = []
        
        if factualAccuracyScore >= 0.8 {
            useCases.append("Factual queries")
        }
        if creativityScore >= 0.8 {
            useCases.append("Creative writing")
        }
        if reasoningScore >= 0.8 {
            useCases.append("Complex reasoning")
        }
        if codingScore >= 0.8 {
            useCases.append("Code generation")
        }
        
        return useCases
    }
}

// MARK: - Extensions for Better Integration

extension TimeOfDay {
    var emoji: String {
        switch self {
        case .earlyMorning:
            return "🌅"
        case .morning:
            return "☀️"
        case .afternoon:
            return "🌤️"
        case .evening:
            return "🌇"
        case .night:
            return "🌙"
        }
    }
}

extension Season {
    var emoji: String {
        switch self {
        case .spring:
            return "🌸"
        case .summer:
            return "☀️"
        case .fall:
            return "🍂"
        case .winter:
            return "❄️"
        }
    }
}

extension DayOfWeek {
    var isWeekend: Bool {
        return self == .saturday || self == .sunday
    }
}
