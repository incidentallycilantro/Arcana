//
// TemporalTypes.swift
// Arcana - Temporal intelligence data structures
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Core Temporal Types (NO DUPLICATES - USE EXISTING SHARED TYPES)

enum ActivityType: String, Codable, CaseIterable {
    case creative = "creative"
    case analytical = "analytical"
    case communication = "communication"
    case planning = "planning"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .creative: return "paintbrush"
        case .analytical: return "chart.bar"
        case .communication: return "message"
        case .planning: return "calendar"
        }
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
        case .earlyMorningLow: return "Early Morning Low"
        case .morningRise: return "Morning Rise"
        case .morningFocus: return "Morning Focus"
        case .midMorningPeak: return "Mid-Morning Peak"
        case .lunchDip: return "Lunch Dip"
        case .afternoonCreative: return "Afternoon Creative"
        case .afternoonPeak: return "Afternoon Peak"
        case .eveningTransition: return "Evening Transition"
        case .eveningReflection: return "Evening Reflection"
        case .nightWindDown: return "Night Wind Down"
        case .lateNightLow: return "Late Night Low"
        }
    }
    
    var optimalActivities: [ActivityType] {
        switch self {
        case .earlyMorningLow, .lateNightLow:
            return []
        case .morningRise:
            return [.planning]
        case .morningFocus, .midMorningPeak:
            return [.analytical, .planning]
        case .lunchDip:
            return []
        case .afternoonCreative:
            return [.creative, .communication]
        case .afternoonPeak:
            return [.analytical, .planning, .communication]
        case .eveningTransition:
            return [.communication, .creative]
        case .eveningReflection:
            return [.creative, .planning]
        case .nightWindDown:
            return [.creative]
        }
    }
    
    var energyLevel: Double {
        switch self {
        case .midMorningPeak: return 0.95
        case .morningFocus: return 0.9
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

// MARK: - Temporal Context (USE SEASON FROM SHARED TYPES)

struct TemporalContext: Codable {
    let timestamp: Date
    let hour: Int
    let dayOfWeek: Int
    let dayOfYear: Int
    let weekOfYear: Int
    let month: Int
    let season: Season  // Uses Season from SharedQualityTypes
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
        self.season = Self.determineSeason(for: now)
        self.circadianPhase = Self.determineCircadianPhase(for: now)
        self.isWorkingHours = Self.isWorkingHours(now)
        self.isWeekend = calendar.isDateInWeekend(now)
    }
    
    static func determineSeason(for date: Date) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .winter
        }
    }
    
    static func determineCircadianPhase(for date: Date) -> CircadianPhase {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<7: return .earlyMorningLow
        case 7..<9: return .morningRise
        case 9..<11: return .morningFocus
        case 11..<12: return .midMorningPeak
        case 12..<14: return .lunchDip
        case 14..<16: return .afternoonCreative
        case 16..<18: return .afternoonPeak
        case 18..<20: return .eveningTransition
        case 20..<22: return .eveningReflection
        case 22..<24: return .nightWindDown
        default: return .lateNightLow
        }
    }
    
    static func isWorkingHours(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 9 && hour < 17
    }
}

// MARK: - Communication and Preferences

enum CommunicationStyle: String, Codable {
    case brief, detailed, conversational, technical, creative
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct OptimalWindow: Codable {
    let dayOfWeek: Int?
    let startHour: Int
    let endHour: Int
    
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

// MARK: - Temporal Predictions

struct TemporalPrediction: Codable {
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
    
    var temporalWeight: Double {
        switch self {
        case .taskOriented: return 0.4
        case .reflective: return 0.6
        case .seasonal: return 0.8
        case .energyBased: return 0.9
        case .patternBased: return 0.7
        }
    }
}

// MARK: - Enhanced Temporal Intelligence

struct TemporalRecommendation: Codable, Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let confidence: Double
    let action: RecommendedAction
    
    var priority: Int {
        switch type {
        case .circadian: return 3
        case .seasonal: return 1
        case .weeklyPattern: return 2
        case .energyOptimization: return 4
        case .optimalTiming: return 5
        case .circadianAlignment: return 3
        case .seasonalOptimization: return 1
        case .energyManagement: return 4
        }
    }
}

enum RecommendationType: String, Codable {
    case circadian = "circadian"
    case seasonal = "seasonal"
    case weeklyPattern = "weekly_pattern"
    case energyOptimization = "energy_optimization"
    case optimalTiming = "optimal_timing"
    case circadianAlignment = "circadian_alignment"
    case seasonalOptimization = "seasonal_optimization"
    case energyManagement = "energy_management"
}

enum RecommendedAction: String, Codable {
    case adjustTiming = "adjust_timing"
    case changeWorkspace = "change_workspace"
    case modifyApproach = "modify_approach"
    case enhanceContext = "enhance_context"
    case optimizeEnergy = "optimize_energy"
    case alignWithRhythm = "align_with_rhythm"
    case suggestAnalyticalTasks = "suggest_analytical_tasks"
    case suggestBreak = "suggest_break"
    case suggestCreativeTasks = "suggest_creative_tasks"
    case suggestPlanningTasks = "suggest_planning_tasks"
    case adjustWorkspace = "adjust_workspace"
}

// MARK: - Temporal Intelligence Analysis (NO CODABLE - USE STRUCTS WITHOUT CONFORMANCE)

struct TemporalIntelligence {
    let contextualRecommendation: ContextualRecommendation
    let workspaceOptimization: WorkspaceOptimization
    let privacyConsiderations: PrivacyConsideration
    let intelligenceBoost: IntelligenceBoost
}

struct ContextualRecommendation {
    let communicationStyle: CommunicationStyle
    let urgencyLevel: UrgencyLevel
    let detailLevel: DetailLevel
    let suggestionType: SuggestionType
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
    let recommendedPrivacyLevel: PrivacyLevel  // Use local definition
    let reasoning: String
    let dataRetentionGuidance: String
    
    init(recommendedPrivacyLevel: PrivacyLevel, reasoning: String) {
        self.recommendedPrivacyLevel = recommendedPrivacyLevel
        self.reasoning = reasoning
        self.dataRetentionGuidance = "Standard temporal learning patterns"
    }
}

struct IntelligenceBoost {
    let enhancedProcessing: Bool
    let ensembleRecommendation: Bool
    let qualityPrediction: Double
}

// MARK: - User Patterns (NO CODABLE FOR SEASON DICTIONARY)

struct UserTemporalPatterns {
    var morningPatterns: [String] = []
    var afternoonPatterns: [String] = []
    var eveningPatterns: [String] = []
    var weekendPatterns: [String] = []
    var seasonalPatterns: [Season: [String]] = [:]
    var lastUpdated: Date = Date()
}

struct TimeBasedPreferences {
    var communicationStyles: [CircadianPhase: CommunicationStyle] = [:]
    var workspacePreferences: [CircadianPhase: WorkspaceManager.WorkspaceType] = [:]
    var privacyLevels: [CircadianPhase: PrivacyLevel] = [:]
}

// MARK: - Enhanced Temporal Context

struct EnhancedTemporalContext: Codable {
    let timestamp: Date
    let circadianPhase: CircadianPhase
    let energyLevel: Double
    let cognitiveOptimality: Double
    let seasonalContext: SeasonalContext?
    let userPatternMatch: UserPatternMatch?
    let temporalRecommendations: [TemporalRecommendation]
}

struct SeasonalContext: Codable {
    let season: Season  // Uses Season from SharedQualityTypes
    let weekInSeason: Int
    let seasonalEnergy: Double
    let seasonalMood: String
}

struct UserPatternMatch: Codable {
    let patternType: String
    let confidence: Double
    let historicalData: [String]
}

// MARK: - Supporting Types

enum UrgencyLevel: String, Codable {
    case low, medium, high, critical
}

enum DetailLevel: String, Codable {
    case brief, standard, detailed, comprehensive
}

enum SuggestionType: String, Codable {
    case productive, creative, reflective, social
}

// MARK: - LOCAL PRIVACY LEVEL (TO AVOID DEPENDENCY)
enum PrivacyLevel: String, Codable {
    case minimal, standard, enhanced, maximum
}

// MARK: - CircadianPhase Extensions

extension CircadianPhase {
    func isOptimalForActivity(_ activity: ActivityType) -> Bool {
        return optimalActivities.contains(activity)
    }
    
    func getActivityRecommendations() -> [ActivityType] {
        return optimalActivities
    }
    
    func getEnergyDescription() -> String {
        let percentage = Int(energyLevel * 100)
        return "\(percentage)% energy"
    }
}

// MARK: - Circadian Types for CircadianOptimizer

struct CircadianState: Codable {
    let phase: CircadianPhase
    let energyLevel: Double
    let optimalActivities: [ActivityType]
    let timestamp: Date
    let afternoonCreativityScore: Double  // ADDED MISSING PROPERTY
    
    init() {
        let context = TemporalContext()
        self.phase = context.circadianPhase
        self.energyLevel = context.circadianPhase.energyLevel
        self.optimalActivities = context.circadianPhase.optimalActivities
        self.timestamp = Date()
        self.afternoonCreativityScore = 0.8  // Default value
    }
}

struct EnergyForecastPoint: Codable, Identifiable {
    let id = UUID()
    let time: Date
    let energyLevel: Double
    let phase: CircadianPhase
    let activities: [ActivityType]
    
    init(time: Date, energyLevel: Double, phase: CircadianPhase, activities: [ActivityType]) {
        self.time = time
        self.energyLevel = energyLevel
        self.phase = phase
        self.activities = activities
    }
}

struct ActivityWindow: Codable, Identifiable {
    let id = UUID()
    let activity: ActivityType
    let startTime: Date
    let endTime: Date
    let energyLevel: Double
    let confidence: Double
    
    init(activity: ActivityType, startTime: Date, endTime: Date, energyLevel: Double, confidence: Double) {
        self.activity = activity
        self.startTime = startTime
        self.endTime = endTime
        self.energyLevel = energyLevel
        self.confidence = confidence
    }
}

struct CircadianInsights: Codable {
    let currentState: CircadianState
    let recommendations: [TemporalRecommendation]
    let optimalWindows: [ActivityWindow]
    let energyForecast: [EnergyForecastPoint]
    let timestamp: Date
    
    // ADDED CONVENIENCE PROPERTIES FOR TEMPORALINTELLIGENCEENGINE
    var currentPhase: CircadianPhase { currentState.phase }
    var energyLevel: Double { currentState.energyLevel }
    var cognitiveOptimality: Double { currentState.energyLevel * 0.9 } // Calculated from energy
    
    init(currentState: CircadianState, recommendations: [TemporalRecommendation], optimalWindows: [ActivityWindow], energyForecast: [EnergyForecastPoint]) {
        self.currentState = currentState
        self.recommendations = recommendations
        self.optimalWindows = optimalWindows
        self.energyForecast = energyForecast
        self.timestamp = Date()
    }
}
