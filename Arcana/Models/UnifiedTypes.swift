//
// UnifiedTypes.swift
// Arcana - Unified Type System (Single Source of Truth)
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
// PURPOSE: Centralized type definitions to eliminate dependency conflicts

import Foundation
import SwiftUI

// MARK: - CORE UNIFIED TYPES

// =====================================================
// WORKSPACE & PROJECT TYPES (AUTHORITATIVE)
// =====================================================

extension WorkspaceManager {
    enum WorkspaceType: String, Codable, CaseIterable, Hashable {
        case general = "general"
        case code = "code"
        case creative = "creative"
        case research = "research"
        
        var emoji: String {
            switch self {
            case .general: return "💬"
            case .code: return "⚡"
            case .creative: return "🎨"
            case .research: return "🔬"
            }
        }
        
        var displayName: String {
            switch self {
            case .general: return "General"
            case .code: return "Development"
            case .creative: return "Creative"
            case .research: return "Research"
            }
        }
        
        var description: String {
            switch self {
            case .general: return "General conversations and assistance"
            case .code: return "Software development and programming"
            case .creative: return "Creative writing and design projects"
            case .research: return "Research and analysis work"
            }
        }
    }
}

// =====================================================
// CHAT & MESSAGE TYPES (AUTHORITATIVE)
// =====================================================

enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// =====================================================
// TEMPORAL TYPES (AUTHORITATIVE - NO DUPLICATES)
// =====================================================

enum Season: String, Codable, CaseIterable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum CircadianPhase: String, Codable, CaseIterable {
    case dawn = "dawn"
    case morning = "morning"
    case midday = "midday"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    case deepSleep = "deep_sleep"
    
    var energyLevel: Double {
        switch self {
        case .dawn: return 0.3
        case .morning: return 0.9
        case .midday: return 0.8
        case .afternoon: return 0.7
        case .evening: return 0.6
        case .night: return 0.4
        case .deepSleep: return 0.1
        }
    }
    
    static func fromHour(_ hour: Int) -> CircadianPhase {
        switch hour {
        case 5...6: return .dawn
        case 7...11: return .morning
        case 12...13: return .midday
        case 14...17: return .afternoon
        case 18...21: return .evening
        case 22...23: return .night
        default: return .deepSleep
        }
    }
}

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

// =====================================================
// QUALITY & VALIDATION TYPES (AUTHORITATIVE)
// =====================================================

enum ValidationLevel: String, Codable, CaseIterable {
    case none = "none"
    case basic = "basic"
    case standard = "standard"
    case comprehensive = "comprehensive"
    case research = "research"
    
    var displayName: String {
        switch self {
        case .none: return "No Validation"
        case .basic: return "Basic Check"
        case .standard: return "Standard Validation"
        case .comprehensive: return "Comprehensive Review"
        case .research: return "Research Grade"
        }
    }
    
    var confidenceMultiplier: Double {
        switch self {
        case .none: return 0.5
        case .basic: return 0.7
        case .standard: return 0.85
        case .comprehensive: return 0.95
        case .research: return 0.98
        }
    }
}

enum QualityTier: String, Codable, CaseIterable {
    case poor = "poor"
    case acceptable = "acceptable"
    case good = "good"
    case excellent = "excellent"
    case exceptional = "exceptional"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var scoreRange: ClosedRange<Double> {
        switch self {
        case .poor: return 0.0...0.4
        case .acceptable: return 0.4...0.6
        case .good: return 0.6...0.8
        case .excellent: return 0.8...0.95
        case .exceptional: return 0.95...1.0
        }
    }
    
    var color: Color {
        switch self {
        case .poor: return .red
        case .acceptable: return .orange
        case .good: return .yellow
        case .excellent: return .green
        case .exceptional: return .blue
        }
    }
}

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
        case .linguisticMarker: return "Linguistic Uncertainty"
        case .contradiction: return "Internal Contradiction"
        case .insufficientContext: return "Insufficient Context"
        case .factualUncertainty: return "Factual Uncertainty"
        case .temporalInconsistency: return "Temporal Inconsistency"
        case .sourceReliability: return "Source Reliability"
        case .modelLimitation: return "Model Limitation"
        case .crossReferenceFailure: return "Cross-Reference Failure"
        }
    }
    
    var severityWeight: Double {
        switch self {
        case .linguisticMarker: return 0.3
        case .contradiction: return 0.9
        case .insufficientContext: return 0.6
        case .factualUncertainty: return 0.8
        case .temporalInconsistency: return 0.7
        case .sourceReliability: return 0.8
        case .modelLimitation: return 0.5
        case .crossReferenceFailure: return 0.7
        }
    }
}

// =====================================================
// CORE DATA STRUCTURES (AUTHORITATIVE)
// =====================================================

struct UncertaintyFactor: Codable, Hashable {
    let type: UncertaintyType
    let description: String
    let severity: Double // 0.0 to 1.0
    let location: String?
    let suggestion: String?
    
    var weightedSeverity: Double {
        return severity * type.severityWeight
    }
    
    init(
        type: UncertaintyType,
        description: String,
        severity: Double,
        location: String? = nil,
        suggestion: String? = nil
    ) {
        self.type = type
        self.description = description
        self.severity = min(max(severity, 0.0), 1.0) // Clamp to [0, 1]
        self.location = location
        self.suggestion = suggestion
    }
}

struct TimeContext: Codable, Hashable {
    let timestamp: Date
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let season: Season
    let circadianPhase: CircadianPhase
    let energyLevel: Double
    let cognitiveOptimality: Double
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        let weekday = calendar.component(.weekday, from: timestamp)
        let month = calendar.component(.month, from: timestamp)
        
        // Map hour to TimeOfDay
        switch hour {
        case 5...8: self.timeOfDay = .earlyMorning
        case 9...11: self.timeOfDay = .morning
        case 12...17: self.timeOfDay = .afternoon
        case 18...21: self.timeOfDay = .evening
        default: self.timeOfDay = .night
        }
        
        // Map weekday to DayOfWeek
        let dayMapping: [DayOfWeek] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        self.dayOfWeek = dayMapping[weekday - 1]
        
        // Map month to Season
        switch month {
        case 12, 1, 2: self.season = .winter
        case 3, 4, 5: self.season = .spring
        case 6, 7, 8: self.season = .summer
        case 9, 10, 11: self.season = .autumn
        default: self.season = .spring
        }
        
        self.circadianPhase = CircadianPhase.fromHour(hour)
        self.energyLevel = circadianPhase.energyLevel
        self.cognitiveOptimality = energyLevel * 0.9
    }
}

struct ModelCapabilities: Codable, Hashable {
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

// =====================================================
// COMPARISON & ANALYSIS TYPES
// =====================================================

struct QualityComparison: Codable {
    let firstScore: Double
    let secondScore: Double
    let difference: Double
    let significantDifference: Bool
    let betterResponse: ComparisonResult
    let analysisDetails: String
    
    init(first: Double, second: Double, threshold: Double = 0.1) {
        self.firstScore = first
        self.secondScore = second
        self.difference = first - second
        self.significantDifference = abs(difference) > threshold
        
        if difference > threshold {
            self.betterResponse = .first
        } else if difference < -threshold {
            self.betterResponse = .second
        } else {
            self.betterResponse = .equivalent
        }
        
        self.analysisDetails = QualityComparison.generateAnalysis(
            first: first,
            second: second,
            difference: difference,
            significant: significantDifference
        )
    }
    
    private static func generateAnalysis(
        first: Double,
        second: Double,
        difference: Double,
        significant: Bool
    ) -> String {
        if !significant {
            return "Responses are of equivalent quality (difference: \(String(format: "%.1f%%", abs(difference) * 100)))"
        }
        
        let better = difference > 0 ? "first" : "second"
        let worse = difference > 0 ? "second" : "first"
        let betterScore = max(first, second)
        let worseScore = min(first, second)
        
        return "The \(better) response shows significantly better quality (\(String(format: "%.1f%%", betterScore * 100)) vs \(String(format: "%.1f%%", worseScore * 100)))"
    }
}

enum ComparisonResult: String, Codable {
    case first = "first"
    case second = "second"
    case equivalent = "equivalent"
    
    var displayName: String {
        switch self {
        case .first: return "First Response Better"
        case .second: return "Second Response Better"
        case .equivalent: return "Equivalent Quality"
        }
    }
}

// =====================================================
// RESPONSE PROVENANCE & METADATA
// =====================================================

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
}

// =====================================================
// QUALITY STANDARDS (STATIC CONFIGURATION)
// =====================================================

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
        case excellenceStandardScore...1.0: return "Excellent"
        case professionalStandardScore..<excellenceStandardScore: return "Professional"
        case minimumAcceptableScore..<professionalStandardScore: return "Acceptable"
        default: return "Needs Improvement"
        }
    }
    
    static func getQualityTier(score: Double) -> QualityTier {
        switch score {
        case 0.95...1.0: return .exceptional
        case 0.8...0.95: return .excellent
        case 0.6...0.8: return .good
        case 0.4...0.6: return .acceptable
        default: return .poor
        }
    }
}

// =====================================================
// REVOLUTIONARY INTELLIGENCE TYPES (FUTURE-READY)
// =====================================================

protocol QuantumMemoryCompatible {
    var quantumSignature: String { get }
    var temporalWeight: Double { get }
    var memoryPriority: Int { get }
}

protocol EnsembleIntelligenceReady {
    var ensembleCompatibility: [String] { get }
    var consensusWeight: Double { get }
    var intelligenceContribution: Double { get }
}

// Extension to make TimeContext quantum memory compatible
extension TimeContext: QuantumMemoryCompatible {
    var quantumSignature: String {
        return "\(timeOfDay.rawValue)_\(circadianPhase.rawValue)_\(season.rawValue)"
    }
    
    var temporalWeight: Double {
        return energyLevel * cognitiveOptimality
    }
    
    var memoryPriority: Int {
        switch circadianPhase {
        case .morning: return 10
        case .midday: return 8
        case .afternoon: return 6
        case .evening: return 4
        case .dawn: return 2
        case .night, .deepSleep: return 1
        }
    }
}

// =====================================================
// SYSTEM INTEGRATION UTILITIES
// =====================================================

struct SystemValidation {
    static func validateTypeConsistency() -> Bool {
        // Runtime validation of type system integrity
        let seasonCount = Season.allCases.count
        let circadianCount = CircadianPhase.allCases.count
        let qualityTierCount = QualityTier.allCases.count
        let uncertaintyTypeCount = UncertaintyType.allCases.count
        
        // Ensure all enums have expected minimum cases
        return seasonCount >= 4 &&
               circadianCount >= 7 &&
               qualityTierCount >= 5 &&
               uncertaintyTypeCount >= 8
    }
    
    static func getSystemInfo() -> [String: Any] {
        return [
            "unified_types_version": "1.0.0",
            "last_validation": Date(),
            "type_consistency": validateTypeConsistency(),
            "season_cases": Season.allCases.count,
            "circadian_phases": CircadianPhase.allCases.count,
            "quality_tiers": QualityTier.allCases.count,
            "uncertainty_types": UncertaintyType.allCases.count,
            "validation_levels": ValidationLevel.allCases.count,
            "workspace_types": WorkspaceManager.WorkspaceType.allCases.count
        ]
    }
}

// =====================================================
// DEPRECATION NOTICE
// =====================================================

/*
 IMPORTANT: This file replaces all scattered type definitions across the system.
 
 DEPRECATED FILES (DO NOT USE):
 - Any duplicate Season, CircadianPhase, UncertaintyType enums
 - Scattered ValidationLevel definitions
 - Multiple QualityTier implementations
 
 MIGRATION NOTES:
 - All files must import from UnifiedTypes.swift
 - Remove duplicate type definitions
 - Update import statements to reference unified types
 - Ensure consistent enum case usage across all files
 
 CRITICAL: This is the SINGLE SOURCE OF TRUTH for all type definitions.
 */
