//
// TemporalTypes.swift
// Arcana - Temporal intelligence data structures
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Local Season Enum (to avoid SharedQualityTypes dependency issues)

enum Season: String, Codable, CaseIterable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Core Temporal Types

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
    
    var energyLevel: Double {
        switch self {
        case .earlyMorningLow: return 0.3
        case .morningRise: return 0.6
        case .morningFocus: return 0.9
        case .midMorningPeak: return 1.0
        case .lunchDip: return 0.5
        case .afternoonCreative: return 0.8
        case .afternoonPeak: return 0.9
        case .eveningTransition: return 0.7
        case .eveningReflection: return 0.6
        case .nightWindDown: return 0.4
        case .lateNightLow: return 0.2
        }
    }
    
    var optimalActivities: [ActivityType] {
        switch self {
        case .morningFocus, .midMorningPeak:
            return [.analytical, .planning]
        case .afternoonCreative:
            return [.creative, .communication]
        case .eveningReflection:
            return [.planning, .creative]
        default:
            return [.communication]
        }
    }
    
    var baseEnergyLevel: Double {
        return energyLevel
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

// MARK: - Temporal Context

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
    let season: Season
    let weekInSeason: Int
    let seasonalEnergy: Double
    let seasonalMood: String
}

struct UserPatternMatch: Codable {
    let patternType: String
    let confidence: Double
    let historicalData: [String]
}

// MARK: - Temporal Intelligence Types

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
    
    var displayName: String {
        switch self {
        case .circadian: return "Circadian"
        case .seasonal: return "Seasonal"
        case .weeklyPattern: return "Weekly Pattern"
        case .energyOptimization: return "Energy Optimization"
        case .optimalTiming: return "Optimal Timing"
        case .circadianAlignment: return "Circadian Alignment"
        case .seasonalOptimization: return "Seasonal Optimization"
        case .energyManagement: return "Energy Management"
        }
    }
}

enum RecommendedAction: String, Codable {
    case suggestCreativeTasks = "suggest_creative_tasks"
    case suggestAnalyticalTasks = "suggest_analytical_tasks"
    case suggestPlanningTasks = "suggest_planning_tasks"
    case suggestBreak = "suggest_break"
    case adjustWorkspace = "adjust_workspace"
    case suggestComplexTasks = "suggest_complex_tasks"
    case applySeasonalContext = "apply_seasonal_context"
    
    var displayName: String {
        switch self {
        case .suggestCreativeTasks: return "Creative Tasks"
        case .suggestAnalyticalTasks: return "Analytical Tasks"
        case .suggestPlanningTasks: return "Planning Tasks"
        case .suggestBreak: return "Take a Break"
        case .adjustWorkspace: return "Adjust Workspace"
        case .suggestComplexTasks: return "Complex Tasks"
        case .applySeasonalContext: return "Apply Seasonal Context"
        }
    }
}

// MARK: - Circadian Optimization Types

struct CircadianInsights: Codable {
    let timestamp: Date
    let currentPhase: CircadianPhase
    let energyLevel: Double
    let cognitiveOptimality: Double
    let recommendedActivities: [ActivityType]
    let avoidActivities: [ActivityType]
    let recommendations: [TemporalRecommendation]
}

struct EnergyForecastPoint: Codable {
    let time: Date
    let energyLevel: Double
    let phase: CircadianPhase
    let confidence: Double
}

struct ActivityWindow: Codable {
    let activity: ActivityType
    let startTime: Date
    let endTime: Date
    let optimalityScore: Double
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
    let enhancedProcessing: Bool
    let ensembleRecommendation: Bool
    let qualityPrediction: Double
}

// MARK: - User Patterns

struct UserTemporalPatterns: Codable {
    var morningPatterns: [String] = []
    var afternoonPatterns: [String] = []
    var eveningPatterns: [String] = []
    var weekendPatterns: [String] = []
    var seasonalPatterns: [Season: [String]] = [:]
    var lastUpdated: Date = Date()
}

struct TimeBasedPreferences: Codable {
    var communicationStyles: [CircadianPhase: CommunicationStyle] = [:]
    var workspacePreferences: [CircadianPhase: WorkspaceManager.WorkspaceType] = [:]
    var privacyLevels: [CircadianPhase: PrivacyLevel] = [:]
}

// MARK: - CircadianPhase Extensions

extension CircadianPhase {
    func isOptimalForActivity(_ activity: ActivityType) -> Bool {
        return optimalActivities.contains(activity)
    }
    
    var preferredCommunicationStyle: CommunicationStyle {
        switch self {
        case .morningFocus, .midMorningPeak:
            return .brief
        case .afternoonCreative:
            return .conversational
        case .eveningReflection:
            return .detailed
        default:
            return .conversational
        }
    }
}

// MARK: - Supporting Types for Cultural and Seasonal Context

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
