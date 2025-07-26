//
// TemporalTypes.swift
// Arcana - Temporal intelligence data structures
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Core Temporal Types

struct TemporalContext: Codable {
    let timestamp: Date
    let hour: Int
    let dayOfWeek: Int
    let dayOfYear: Int
    let weekOfYear: Int
    let month: Int
    let season: Season
    let circadianPhase: CircadianPhase
    let isWorkingHours: Bool
    let isWeekend: Bool
    
    init() {
        let now = Date()
        let calendar = Calendar.current
        
        self.timestamp = now
        self.hour = calendar.component(.hour, from: now)
        self.dayOfWeek = calendar.component(.weekday, from: now)
        self.dayOfYear = calendar.component(.dayOfYear, from: now)
        self.weekOfYear = calendar.component(.weekOfYear, from: now)
        self.month = calendar.component(.month, from: now)
        self.season = Season.current
        self.circadianPhase = .morningFocus // Would be calculated
        self.isWorkingHours = (hour >= 9 && hour <= 17)
        self.isWeekend = calendar.isDateInWeekend(now)
    }
    
    init(timestamp: Date, hour: Int, dayOfWeek: Int, dayOfYear: Int, weekOfYear: Int, month: Int, season: Season, circadianPhase: CircadianPhase, isWorkingHours: Bool, isWeekend: Bool) {
        self.timestamp = timestamp
        self.hour = hour
        self.dayOfWeek = dayOfWeek
        self.dayOfYear = dayOfYear
        self.weekOfYear = weekOfYear
        self.month = month
        self.season = season
        self.circadianPhase = circadianPhase
        self.isWorkingHours = isWorkingHours
        self.isWeekend = isWeekend
    }
}

struct EnhancedTemporalContext: Codable {
    let timestamp: Date
    let circadianPhase: CircadianPhase
    let energyLevel: Double
    let cognitiveOptimality: Double
    let seasonalContext: SeasonalContext?
    let userPatternMatch: UserPatternMatch?
    let temporalRecommendations: [TemporalRecommendation]
}

// MARK: - Season & Circadian Types

enum Season: String, Codable, CaseIterable {
    case spring, summer, fall, winter
    
    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .spring
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum CircadianPhase: String, Codable, CaseIterable {
    case earlyMorningLow = "early_morning_low"
    case morningRise = "morning_rise"
    case morningFocus = "morning_focus"
    case midMorningPeak = "mid_morning_peak"
    case lunchDip = "lunch_dip"
    case afternoonCreative = "afternoon_creative"
    case afternoonPeak = "afternoon_peak"
    case eveningTransition = "evening_transition"
    case eveningReflection = "evening_reflection"
    case nightWindDown = "night_wind_down"
    case lateNightLow = "late_night_low"
    
    var displayName: String {
        switch self {
        case .earlyMorningLow: return "Early Morning"
        case .morningRise: return "Morning Rise"
        case .morningFocus: return "Morning Focus"
        case .midMorningPeak: return "Peak Focus"
        case .lunchDip: return "Lunch Dip"
        case .afternoonCreative: return "Creative Peak"
        case .afternoonPeak: return "Afternoon Peak"
        case .eveningTransition: return "Evening Transition"
        case .eveningReflection: return "Evening Reflection"
        case .nightWindDown: return "Winding Down"
        case .lateNightLow: return "Late Night"
        }
    }
    
    var baseEnergyLevel: Double {
        switch self {
        case .earlyMorningLow, .lateNightLow: return 0.2
        case .morningRise: return 0.6
        case .morningFocus, .midMorningPeak: return 0.9
        case .lunchDip: return 0.4
        case .afternoonCreative, .afternoonPeak: return 0.8
        case .eveningTransition: return 0.6
        case .eveningReflection: return 0.7
        case .nightWindDown: return 0.3
        }
    }
    
    var baseCognitiveOptimality: Double {
        switch self {
        case .morningFocus, .midMorningPeak: return 0.95
        case .afternoonCreative: return 0.85
        case .eveningReflection: return 0.75
        case .afternoonPeak: return 0.8
        case .morningRise: return 0.7
        case .eveningTransition: return 0.6
        case .nightWindDown: return 0.4
        case .lunchDip: return 0.3
        case .earlyMorningLow, .lateNightLow: return 0.2
        }
    }
    
    var icon: String {
        switch self {
        case .earlyMorningLow: return "moon.zzz"
        case .morningRise: return "sunrise"
        case .morningFocus, .midMorningPeak: return "brain.head.profile"
        case .lunchDip: return "fork.knife"
        case .afternoonCreative: return "lightbulb"
        case .afternoonPeak: return "bolt"
        case .eveningTransition: return "sunset"
        case .eveningReflection: return "thought.bubble"
        case .nightWindDown: return "moon"
        case .lateNightLow: return "moon.zzz"
        }
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case creative, analytical, communication, planning
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .creative: return "paintbrush"
        case .analytical: return "chart.bar"
        case .communication: return "bubble.left.and.bubble.right"
        case .planning: return "calendar"
        }
    }
}

// MARK: - Temporal Recommendations

struct TemporalRecommendation: Codable, Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let confidence: Double
    let action: RecommendedAction
    
    var priority: RecommendationPriority {
        switch confidence {
        case 0.9...1.0: return .critical
        case 0.8..<0.9: return .high
        case 0.6..<0.8: return .medium
        default: return .low
        }
    }
}

enum RecommendationType: String, Codable {
    case optimalTiming = "optimal_timing"
    case circadianAlignment = "circadian_alignment"
    case productivityPeak = "productivity_peak"
    case energyManagement = "energy_management"
    case weeklyPattern = "weekly_pattern"
    case seasonalOptimization = "seasonal_optimization"
    
    var displayName: String {
        switch self {
        case .optimalTiming: return "Optimal Timing"
        case .circadianAlignment: return "Circadian Alignment"
        case .productivityPeak: return "Productivity Peak"
        case .energyManagement: return "Energy Management"
        case .weeklyPattern: return "Weekly Pattern"
        case .seasonalOptimization: return "Seasonal Optimization"
        }
    }
    
    var icon: String {
        switch self {
        case .optimalTiming: return "clock"
        case .circadianAlignment: return "sun.and.horizon"
        case .productivityPeak: return "chart.line.uptrend.xyaxis"
        case .energyManagement: return "battery.100"
        case .weeklyPattern: return "calendar.badge.clock"
        case .seasonalOptimization: return "leaf"
        }
    }
}

enum RecommendedAction: String, Codable {
    case suggestComplexTasks = "suggest_complex_tasks"
    case suggestCreativeTasks = "suggest_creative_tasks"
    case suggestPlanningTasks = "suggest_planning_tasks"
    case suggestBreak = "suggest_break"
    case applySeasonalContext = "apply_seasonal_context"
    
    var displayName: String {
        switch self {
        case .suggestComplexTasks: return "Complex Tasks"
        case .suggestCreativeTasks: return "Creative Tasks"
        case .suggestPlanningTasks: return "Planning Tasks"
        case .suggestBreak: return "Take a Break"
        case .applySeasonalContext: return "Seasonal Context"
        }
    }
}

enum RecommendationPriority: String, Codable {
    case low, medium, high, critical
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Seasonal Context

struct SeasonalContext: Codable {
    let season: Season
    let seasonalMood: SeasonalMood
    let culturalEvents: [CulturalEvent]
    let naturalCycles: [NaturalCycle]
    let seasonalOptimizations: [SeasonalOptimization]
}

enum SeasonalMood: String, Codable {
    case renewal, energetic, reflective, contemplative
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var contextualPrefix: String {
        switch self {
        case .renewal: return "With spring's energy in mind,"
        case .energetic: return "Taking advantage of summer's vigor,"
        case .reflective: return "As we move through fall's contemplative season,"
        case .contemplative: return "In winter's thoughtful spirit,"
        }
    }
    
    var description: String {
        switch self {
        case .renewal: return "A time of new beginnings and fresh energy"
        case .energetic: return "Peak energy and long days for productivity"
        case .reflective: return "Time for planning and thoughtful consideration"
        case .contemplative: return "Deep thinking and strategic reflection"
        }
    }
}

struct CulturalEvent: Codable {
    let name: String
    let date: Date
    let significance: String
    let impact: CulturalImpact
}

enum CulturalImpact: String, Codable {
    case low, medium, high
}

struct NaturalCycle: Codable {
    let type: CycleType
    let intensity: Double
    let description: String
    
    init(type: CycleType, intensity: Double) {
        self.type = type
        self.intensity = intensity
        self.description = type.description
    }
}

enum CycleType: String, Codable {
    case daylightIncrease = "daylight_increase"
    case longDays = "long_days"
    case daylightDecrease = "daylight_decrease"
    case shortDays = "short_days"
    
    var description: String {
        switch self {
        case .daylightIncrease: return "Increasing daylight hours"
        case .longDays: return "Long summer days"
        case .daylightDecrease: return "Decreasing daylight hours"
        case .shortDays: return "Short winter days"
        }
    }
}

struct SeasonalOptimization: Codable {
    let title: String
    let description: String
    let applicableMonths: [Int]
    let recommendedActions: [String]
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
        self.applicableMonths = []
        self.recommendedActions = []
    }
}

// MARK: - User Pattern Types

struct UserPatternMatch: Codable {
    let patternId: UUID
    let confidence: Double
    let patternType: PatternType
    let recommendations: [TemporalRecommendation]
    let prefersBriefResponses: Bool
    let prefersDetailedExplanations: Bool
    let optimalInteractionTimes: [TimeRange]
    let communicationStylePreferences: [CommunicationStylePreference]
}

enum PatternType: String, Codable {
    case daily, weekly, seasonal, irregular
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct TimeRange: Codable {
    let startHour: Int
    let endHour: Int
    let dayOfWeek: Int?
    
    var description: String {
        let startTime = String(format: "%02d:00", startHour)
        let endTime = String(format: "%02d:00", endHour)
        
        if let day = dayOfWeek {
            let dayName = Calendar.current.weekdaySymbols[day - 1]
            return "\(dayName) \(startTime)-\(endTime)"
        } else {
            return "\(startTime)-\(endTime)"
        }
    }
}

struct CommunicationStylePreference: Codable {
    let style: CommunicationStyle
    let confidence: Double
    let timeContext: TimeContext
}

enum CommunicationStyle: String, Codable {
    case brief, detailed, conversational, technical, creative
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct TimeContext: Codable {
    let hour: Int
    let dayOfWeek: Int
    let season: Season
    let energyLevel: Double
}

// MARK: - Temporal Predictions

struct TemporalPrediction: Codable {
    let id = UUID()
    let type: PredictionType
    let content: String
    let confidence: Double
    let reasoning: String
    let temporalContext: String
    let validityWindow: TimeInterval
    
    var isValid: Bool {
        return Date().timeIntervalSinceNow < validityWindow
    }
}

enum PredictionType: String, Codable {
    case taskOriented = "task_oriented"
    case reflective = "reflective"
    case seasonal = "seasonal"
    case energyBased = "energy_based"
    case patternBased = "pattern_based"
    
    var displayName: String {
        switch self {
        case .taskOriented: return "Task Oriented"
        case .reflective: return "Reflective"
        case .seasonal: return "Seasonal"
        case .energyBased: return "Energy Based"
        case .patternBased: return "Pattern Based"
        }
    }
    
    var icon: String {
        switch self {
        case .taskOriented: return "checkmark.square"
        case .reflective: return "thought.bubble"
        case .seasonal: return "leaf"
        case .energyBased: return "bolt"
        case .patternBased: return "chart.xyaxis.line"
        }
    }
}

// MARK: - Enhanced Prediction Types

struct EnhancedPrediction: Codable {
    let id = UUID()
    let content: String
    let confidence: Double
    let temporalBoost: Double
    let privacyScore: Double
    let workspaceAlignment: Double
    let generatedAt: Date
    
    var overallScore: Double {
        return (confidence * 0.4 + temporalBoost * 0.3 + workspaceAlignment * 0.2 + privacyScore * 0.1)
    }
    
    var qualityGrade: String {
        switch overallScore {
        case 0.9...1.0: return "Excellent"
        case 0.8..<0.9: return "Good"
        case 0.7..<0.8: return "Fair"
        default: return "Poor"
        }
    }
}

// MARK: - Circadian State Types

struct CircadianState: Codable {
    var currentPhase: CircadianPhase = .morningFocus
    var energyLevel: Double = 0.8
    var morningOptimalityScore: Double = 0.9
    var afternoonCreativityScore: Double = 0.7
    var eveningReflectionScore: Double = 0.6
    var lastUpdated: Date = Date()
    
    var overallOptimality: Double {
        switch currentPhase {
        case .morningFocus, .midMorningPeak:
            return morningOptimalityScore
        case .afternoonCreative:
            return afternoonCreativityScore
        case .eveningReflection:
            return eveningReflectionScore
        default:
            return energyLevel
        }
    }
}

// MARK: - Intelligence Integration Types

struct EnhancedTemporalRecommendation {
    let originalRecommendation: TemporalRecommendation
    let workspaceOptimization: WorkspaceOptimization
    let privacyConsiderations: PrivacyConsideration
    let intelligenceBoost: IntelligenceBoost
}

struct WorkspaceOptimization {
    let suggestedWorkspaceType: WorkspaceManager.WorkspaceType
    let rationale: String
    let confidenceBoost: Double
    
    init(suggestedWorkspaceType: WorkspaceManager.WorkspaceType, rationale: String) {
        self.suggestedWorkspaceType = suggestedWorkspaceType
        self.rationale = rationale
        self.confidenceBoost = 0.1
    }
}

struct PrivacyConsideration {
    let recommendedPrivacyLevel: PrivacyLevel
    let reasoning: String
    let dataRetentionGuidance: String
    
    init(recommendedPrivacyLevel: PrivacyLevel, reasoning: String) {
        self.recommendedPrivacyLevel = recommendedPrivacyLevel
        self.reasoning = reasoning
        self.dataRetentionGuidance = "Standard temporal learning patterns"
    }
}

struct IntelligenceBoost {
    let boostType: BoostType
    let multiplier: Double
    let description: String
    let estimatedImprovement: String
    
    init(boostType: BoostType, multiplier: Double, description: String) {
        self.boostType = boostType
        self.multiplier = multiplier
        self.description = description
        self.estimatedImprovement = "\(Int(multiplier * 100))% improvement"
    }
}

enum BoostType: String, Codable {
    case temporal = "temporal"
    case contextual = "contextual"
    case seasonal = "seasonal"
    case circadian = "circadian"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Privacy Response Integration

struct PrivacyProcessedResponse {
    let content: String
    let privacyProcessedMessage: PrivacyProcessedMessage
    let temporalContext: EnhancedTemporalContext
    let privacyLevel: PrivacyLevel
    let processingMetrics: ResponseProcessingMetrics
}

struct ResponseProcessingMetrics {
    let temporalAnalysisTime: TimeInterval
    let privacyProcessingTime: TimeInterval
    let totalProcessingTime: TimeInterval
    let confidenceScore: Double
    let qualityScore: Double
    
    init() {
        self.temporalAnalysisTime = 0.0
        self.privacyProcessingTime = 0.0
        self.totalProcessingTime = 0.0
        self.confidenceScore = 0.0
        self.qualityScore = 0.0
    }
}

// MARK: - Prediction Integration Types

struct Prediction {
    let content: String
    let confidence: Double
    let estimatedComplexity: Double
    let generatedAt: Date
    
    init(content: String, confidence: Double, estimatedComplexity: Double = 0.5) {
        self.content = content
        self.confidence = confidence
        self.estimatedComplexity = estimatedComplexity
        self.generatedAt = Date()
    }
}

struct QualityComparison {
    let higherQualityMessage: UUID
    let qualityDifference: Double
    let primaryFactors: [String]
    let recommendation: String
}

// MARK: - Supporting Utility Types

extension CircadianPhase {
    var isOptimalForActivity(_ activity: ActivityType) -> Bool {
        switch (self, activity) {
        case (.morningFocus, .analytical), (.midMorningPeak, .analytical):
            return true
        case (.afternoonCreative, .creative):
            return true
        case (.eveningReflection, .planning):
            return true
        case (.afternoonPeak, .communication):
            return true
        default:
            return false
        }
    }
    
    var suggestedActivities: [ActivityType] {
        switch self {
        case .morningFocus, .midMorningPeak:
            return [.analytical, .planning]
        case .afternoonCreative:
            return [.creative]
        case .afternoonPeak:
            return [.communication, .analytical]
        case .eveningReflection:
            return [.planning, .communication]
        default:
            return []
        }
    }
}

extension Season {
    var characteristics: SeasonCharacteristics {
        switch self {
        case .spring:
            return SeasonCharacteristics(
                primaryMood: .renewal,
                energyLevel: 0.8,
                creativityBoost: 0.7,
                planningOptimality: 0.9,
                keyThemes: ["new beginnings", "growth", "renewal"]
            )
        case .summer:
            return SeasonCharacteristics(
                primaryMood: .energetic,
                energyLevel: 1.0,
                creativityBoost: 0.8,
                planningOptimality: 0.6,
                keyThemes: ["energy", "productivity", "achievement"]
            )
        case .fall:
            return SeasonCharacteristics(
                primaryMood: .reflective,
                energyLevel: 0.7,
                creativityBoost: 0.6,
                planningOptimality: 1.0,
                keyThemes: ["preparation", "reflection", "planning"]
            )
        case .winter:
            return SeasonCharacteristics(
                primaryMood: .contemplative,
                energyLevel: 0.5,
                creativityBoost: 0.9,
                planningOptimality: 0.8,
                keyThemes: ["contemplation", "strategy", "deep work"]
            )
        }
    }
}

struct SeasonCharacteristics {
    let primaryMood: SeasonalMood
    let energyLevel: Double
    let creativityBoost: Double
    let planningOptimality: Double
    let keyThemes: [String]
}

// MARK: - Time-based Utilities

extension Date {
    var circadianPhase: CircadianPhase {
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)
        let timeDecimal = Double(hour) + Double(minute) / 60.0
        
        switch timeDecimal {
        case 5.0..<7.0: return .earlyMorningLow
        case 7.0..<9.0: return .morningRise
        case 9.0..<11.0: return .morningFocus
        case 11.0..<12.0: return .midMorningPeak
        case 12.0..<14.0: return .lunchDip
        case 14.0..<16.0: return .afternoonCreative
        case 16.0..<18.0: return .afternoonPeak
        case 18.0..<20.0: return .eveningTransition
        case 20.0..<22.0: return .eveningReflection
        case 22.0..<24.0: return .nightWindDown
        case 0.0..<5.0: return .lateNightLow
        default: return .morningFocus
        }
    }
    
    var season: Season {
        let month = Calendar.current.component(.month, from: self)
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .spring
        }
    }
    
    var isWorkingHours: Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour >= 9 && hour <= 17
    }
    
    var energyLevel: Double {
        return circadianPhase.baseEnergyLevel
    }
    
    var cognitiveOptimality: Double {
        return circadianPhase.baseCognitiveOptimality
    }
}
