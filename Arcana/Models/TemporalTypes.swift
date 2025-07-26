//
// TemporalTypes.swift
// Arcana - Time-aware intelligence data structures
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Core Temporal Types

enum CircadianPhase: String, Codable, CaseIterable {
    // UPDATED: Add ALL the cases CircadianOptimizer expects
    case earlyMorningLow = "early_morning_low"        // 0:00-5:00
    case morningRise = "morning_rise"                 // 5:00-7:00
    case morningFocus = "morning_focus"               // 7:00-9:00
    case midMorningPeak = "mid_morning_peak"          // 9:00-11:00
    case lunchDip = "lunch_dip"                       // 11:00-12:00
    case afternoonCreative = "afternoon_creative"     // 12:00-14:00
    case afternoonPeak = "afternoon_peak"             // 14:00-16:00
    case eveningTransition = "evening_transition"     // 16:00-18:00
    case eveningReflection = "evening_reflection"     // 18:00-20:00
    case nightWindDown = "night_wind_down"            // 20:00-22:00
    case lateNightLow = "late_night_low"              // 22:00-24:00
    
    // LEGACY COMPATIBILITY: Keep existing cases for other files
    case earlyMorning = "early_morning"               // Alias for earlyMorningLow
    case morning = "morning"                          // Alias for morningRise
    case lateMorning = "late_morning"                 // Alias for midMorningPeak
    case earlyAfternoon = "early_afternoon"           // Alias for afternoonCreative
    case afternoon = "afternoon"                      // Alias for afternoonPeak
    case earlyEvening = "early_evening"               // Alias for eveningTransition
    case evening = "evening"                          // Alias for eveningReflection
    case night = "night"                              // Alias for lateNightLow
    
    var energyLevel: Double {
        switch self {
        case .earlyMorningLow, .lateNightLow: return 0.3
        case .morningRise, .earlyMorning: return 0.4
        case .morningFocus, .morning: return 0.8
        case .midMorningPeak, .lateMorning: return 0.9
        case .lunchDip: return 0.7
        case .afternoonCreative, .earlyAfternoon: return 0.6
        case .afternoonPeak, .afternoon: return 0.7
        case .eveningTransition, .earlyEvening: return 0.5
        case .eveningReflection, .evening: return 0.5
        case .nightWindDown, .night: return 0.3
        }
    }
    
    var optimalActivities: [ActivityType] {
        switch self {
        case .earlyMorningLow, .lateNightLow: return [.reflection, .planning]
        case .morningRise, .earlyMorning: return [.reflection, .planning]
        case .morningFocus, .morning: return [.creative, .learning, .writing]
        case .midMorningPeak, .lateMorning: return [.problemSolving, .analysis, .research]
        case .lunchDip: return [.routine, .administrative, .organization]
        case .afternoonCreative, .earlyAfternoon: return [.creative, .synthesis, .brainstorming]
        case .afternoonPeak, .afternoon: return [.communication, .meetings, .collaboration]
        case .eveningTransition, .earlyEvening: return [.creative, .synthesis, .brainstorming]
        case .eveningReflection, .evening: return [.reflection, .review, .social]
        case .nightWindDown, .night: return [.relaxation, .planning]
        }
    }
    
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
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .lateMorning: return "Late Morning"
        case .earlyAfternoon: return "Early Afternoon"
        case .afternoon: return "Afternoon"
        case .earlyEvening: return "Early Evening"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
    
    var icon: String {
        switch self {
        case .earlyMorningLow, .lateNightLow: return "moon.fill"
        case .morningRise, .earlyMorning: return "sunrise"
        case .morningFocus, .morning: return "sun.max"
        case .midMorningPeak, .lateMorning: return "sun.max.fill"
        case .lunchDip: return "sun.max"
        case .afternoonCreative, .earlyAfternoon: return "sun.max"
        case .afternoonPeak, .afternoon: return "sun.max"
        case .eveningTransition, .earlyEvening: return "sunset"
        case .eveningReflection, .evening: return "moon"
        case .nightWindDown, .night: return "moon.fill"
        }
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case creative = "creative"
    case analytical = "analytical"
    case communication = "communication"
    case learning = "learning"
    case writing = "writing"
    case problemSolving = "problem_solving"
    case research = "research"
    case meetings = "meetings"
    case collaboration = "collaboration"
    case routine = "routine"
    case administrative = "administrative"
    case organization = "organization"
    case synthesis = "synthesis"
    case brainstorming = "brainstorming"
    case reflection = "reflection"
    case review = "review"
    case social = "social"
    case relaxation = "relaxation"
    case planning = "planning"
    case analysis = "analysis"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var icon: String {
        switch self {
        case .creative: return "paintbrush"
        case .analytical: return "chart.bar"
        case .communication: return "message"
        case .learning: return "book"
        case .writing: return "pencil"
        case .problemSolving: return "lightbulb"
        case .research: return "magnifyingglass"
        case .meetings: return "person.3"
        case .collaboration: return "person.2"
        case .routine: return "checklist"
        case .administrative: return "folder"
        case .organization: return "tray.2"
        case .synthesis: return "arrow.triangle.merge"
        case .brainstorming: return "brain.head.profile"
        case .reflection: return "moon.stars"
        case .review: return "eye"
        case .social: return "person.crop.circle"
        case .relaxation: return "leaf"
        case .planning: return "calendar"
        case .analysis: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum CommunicationStyle: String, Codable {
    case formal = "formal"
    case casual = "casual"
    case creative = "creative"
    case analytical = "analytical"
    case supportive = "supportive"
    case direct = "direct"
    case collaborative = "collaborative"
    case reflective = "reflective"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .formal: return "Professional and structured communication"
        case .casual: return "Relaxed and friendly conversation"
        case .creative: return "Innovative and imaginative expression"
        case .analytical: return "Data-driven and logical discussion"
        case .supportive: return "Encouraging and empathetic guidance"
        case .direct: return "Clear and concise communication"
        case .collaborative: return "Team-oriented and inclusive approach"
        case .reflective: return "Thoughtful and introspective dialogue"
        }
    }
}

// MARK: - Time Context

struct TemporalContext: Codable {
    let timestamp: Date
    let circadianPhase: CircadianPhase
    let timeOfDay: String
    let dayOfWeek: String
    let season: String
    let isWeekend: Bool
    let energyLevel: Double
    let optimalActivities: [ActivityType]
    
    init() {
        let now = Date()
        self.timestamp = now
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let month = calendar.component(.month, from: now)
        
        // Determine circadian phase
        self.circadianPhase = {
            switch hour {
            case 0..<5: return .earlyMorningLow
            case 5..<7: return .morningRise
            case 7..<9: return .morningFocus
            case 9..<11: return .midMorningPeak
            case 11..<12: return .lunchDip
            case 12..<14: return .afternoonCreative
            case 14..<16: return .afternoonPeak
            case 16..<18: return .eveningTransition
            case 18..<20: return .eveningReflection
            case 20..<22: return .nightWindDown
            default: return .lateNightLow
            }
        }()
        
        self.timeOfDay = {
            switch hour {
            case 5..<12: return "morning"
            case 12..<17: return "afternoon"
            case 17..<21: return "evening"
            default: return "night"
            }
        }()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        self.dayOfWeek = formatter.string(from: now)
        
        self.season = {
            switch month {
            case 12, 1, 2: return "winter"
            case 3, 4, 5: return "spring"
            case 6, 7, 8: return "summer"
            case 9, 10, 11: return "fall"
            default: return "unknown"
            }
        }()
        
        self.isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
        self.energyLevel = circadianPhase.energyLevel
        self.optimalActivities = circadianPhase.optimalActivities
    }
}

// MARK: - Temporal Recommendation Types (MISSING DEFINITIONS ADDED)

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

// MARK: - Temporal Intelligence Types

struct TemporalRecommendation: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let recommendation: String
    let rationale: String
    let confidence: Double
    let urgencyLevel: UrgencyLevel
    let detailLevel: DetailLevel
    let suggestionType: SuggestionType
    
    // ADDED: Properties that CircadianOptimizer expects
    let type: RecommendationType
    let title: String
    let message: String
    let action: RecommendedAction
    
    // ADDED: Proper initializer for CircadianOptimizer
    init(
        type: RecommendationType,
        title: String,
        message: String,
        confidence: Double,
        action: RecommendedAction,
        urgencyLevel: UrgencyLevel = .medium,
        detailLevel: DetailLevel = .standard,
        suggestionType: SuggestionType = .productive
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.confidence = confidence
        self.action = action
        self.urgencyLevel = urgencyLevel
        self.detailLevel = detailLevel
        self.suggestionType = suggestionType
        
        // Set computed values
        self.timestamp = Date()
        self.recommendation = title
        self.rationale = message
    }
    
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
    // REMOVED: duplicate PrivacyLevel reference
    // Use PrivacyTypes.PrivacyLevel when needed
    let reasoning: String
    let dataRetentionGuidance: String
    
    init(reasoning: String) {
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
    // REMOVED: privacyLevels - use PrivacyTypes when needed
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
    
    init(activity: ActivityType, startTime: Date, endTime: Date, energyLevel: Double, confidence: Double = 0.8) {
        self.activity = activity
        self.startTime = startTime
        self.endTime = endTime
        self.energyLevel = energyLevel
        self.confidence = confidence
    }
}

// ADDED: CircadianInsights definition (MISSING TYPE)
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

// MARK: - Temporal Learning Types

struct TemporalPattern: Codable, Identifiable {
    let id = UUID()
    let patternType: String
    let timeRange: DateInterval
    let frequency: Int
    let confidence: Double
    let metadata: [String: String]
    
    init(patternType: String, timeRange: DateInterval, frequency: Int, confidence: Double = 0.7, metadata: [String: String] = [:]) {
        self.patternType = patternType
        self.timeRange = timeRange
        self.frequency = frequency
        self.confidence = confidence
        self.metadata = metadata
    }
}

struct TemporalInsight: Codable, Identifiable {
    let id = UUID()
    let insight: String
    let category: InsightCategory
    let confidence: Double
    let actionable: Bool
    let timestamp: Date
    let relatedPatterns: [UUID]
    
    init(insight: String, category: InsightCategory, confidence: Double, actionable: Bool = true, relatedPatterns: [UUID] = []) {
        self.insight = insight
        self.category = category
        self.confidence = confidence
        self.actionable = actionable
        self.timestamp = Date()
        self.relatedPatterns = relatedPatterns
    }
}

enum InsightCategory: String, Codable {
    case productivity, communication, creativity, learning, wellness
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .communication: return "message.circle"
        case .creativity: return "lightbulb"
        case .learning: return "brain.head.profile"
        case .wellness: return "heart.circle"
        }
    }
}

// MARK: - Daily Intelligence Types

struct DailyIntelligence: Codable {
    let date: Date
    let overallEnergyForecast: [EnergyForecastPoint]
    let recommendedActivities: [ActivityWindow]
    let communicationStyle: CommunicationStyle
    let insights: [TemporalInsight]
    let confidence: Double
    
    init(date: Date, overallEnergyForecast: [EnergyForecastPoint], recommendedActivities: [ActivityWindow], communicationStyle: CommunicationStyle, insights: [TemporalInsight], confidence: Double = 0.8) {
        self.date = date
        self.overallEnergyForecast = overallEnergyForecast
        self.recommendedActivities = recommendedActivities
        self.communicationStyle = communicationStyle
        self.insights = insights
        self.confidence = confidence
    }
}

struct WeeklyOptimization: Codable {
    let weekStart: Date
    let dailyRecommendations: [Date: DailyIntelligence]
    let weeklyGoals: [String]
    let energyPattern: String
    let recommendedSchedule: [ActivityWindow]
    
    init(weekStart: Date, dailyRecommendations: [Date: DailyIntelligence] = [:], weeklyGoals: [String] = [], energyPattern: String = "Standard", recommendedSchedule: [ActivityWindow] = []) {
        self.weekStart = weekStart
        self.dailyRecommendations = dailyRecommendations
        self.weeklyGoals = weeklyGoals
        self.energyPattern = energyPattern
        self.recommendedSchedule = recommendedSchedule
    }
}
