//
// TemporalTypes.swift
// Arcana - Temporal intelligence type definitions
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Core Temporal Types

struct TemporalContext: Codable {
    let timestamp: Date
    let circadianPhase: CircadianPhase
    let dayOfWeek: Int
    let seasonalContext: Season
    let energyLevel: Double
    let cognitiveOptimality: Double
    
    init() {
        self.timestamp = Date()
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: timestamp)
        self.seasonalContext = TemporalContext.determineSeason(for: timestamp)
        
        // Calculate circadian phase based on time
        let hour = calendar.component(.hour, from: timestamp)
        self.circadianPhase = CircadianPhase.fromHour(hour)
        self.energyLevel = circadianPhase.energyLevel
        self.cognitiveOptimality = energyLevel * 0.9
    }
    
    // FIXED: Add missing determineSeason method
    static func determineSeason(for time: Date) -> Season {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: time)
        
        switch month {
        case 12, 1, 2:
            return .winter
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .autumn
        default:
            return .spring
        }
    }
}

enum CircadianPhase: String, Codable, CaseIterable {
    case earlyMorningLow = "early_morning_low"
    case morningFocus = "morning_focus"
    case midMorningPeak = "mid_morning_peak"
    case afternoonCreative = "afternoon_creative"
    case afternoonSteady = "afternoon_steady"
    case eveningReflection = "evening_reflection"
    case lateNightLow = "late_night_low"
    
    var displayName: String {
        switch self {
        case .earlyMorningLow: return "Early Morning Low"
        case .morningFocus: return "Morning Focus"
        case .midMorningPeak: return "Mid-Morning Peak"
        case .afternoonCreative: return "Afternoon Creative"
        case .afternoonSteady: return "Afternoon Steady"
        case .eveningReflection: return "Evening Reflection"
        case .lateNightLow: return "Late Night Low"
        }
    }
    
    var energyLevel: Double {
        switch self {
        case .earlyMorningLow: return 0.3
        case .morningFocus: return 0.9
        case .midMorningPeak: return 1.0
        case .afternoonCreative: return 0.8
        case .afternoonSteady: return 0.7
        case .eveningReflection: return 0.6
        case .lateNightLow: return 0.4
        }
    }
    
    var optimalActivities: [ActivityType] {
        switch self {
        case .earlyMorningLow:
            return [.routine, .relaxation]
        case .morningFocus:
            return [.analytical, .planning, .learning, .problemSolving]
        case .midMorningPeak:
            return [.analytical, .learning, .research, .meetings, .collaboration]
        case .afternoonCreative:
            return [.creative, .writing, .synthesis, .brainstorming]
        case .afternoonSteady:
            return [.administrative, .routine, .organization]
        case .eveningReflection:
            return [.reflection, .review, .organization, .synthesis]
        case .lateNightLow:
            return [.relaxation, .reflection, .routine]
        }
    }
    
    static func fromHour(_ hour: Int) -> CircadianPhase {
        switch hour {
        case 5...6: return .earlyMorningLow
        case 7...9: return .morningFocus
        case 10...12: return .midMorningPeak
        case 13...15: return .afternoonCreative
        case 16...18: return .afternoonSteady
        case 19...21: return .eveningReflection
        default: return .lateNightLow
        }
    }
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

// MARK: - Temporal Recommendations

struct TemporalRecommendation: Codable, Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let confidence: Double
    let action: RecommendationAction
    let timestamp: Date
    
    init(type: RecommendationType, title: String, message: String, confidence: Double, action: RecommendationAction) {
        self.type = type
        self.title = title
        self.message = message
        self.confidence = confidence
        self.action = action
        self.timestamp = Date()
    }
}

// FIXED: UUID Codable warning - exclude id from decoding
extension TemporalRecommendation {
    enum CodingKeys: String, CodingKey {
        case type, title, message, confidence, action, timestamp
        // Note: 'id' is excluded - will be generated fresh on decode
    }
}

enum RecommendationType: String, Codable {
    case circadian = "circadian"
    case seasonal = "seasonal"
    case weeklyPattern = "weekly_pattern"
    case userPattern = "user_pattern"
    case energyOptimization = "energy_optimization"
}

enum RecommendationAction: String, Codable {
    case adjustWorkspace = "adjust_workspace"
    case suggestBreak = "suggest_break"
    case optimizeSchedule = "optimize_schedule"
    case changeEnvironment = "change_environment"
    case suggestAnalyticalTasks = "suggest_analytical"
    case suggestCreativeTasks = "suggest_creative"
    case suggestPlanningTasks = "suggest_planning"
    case suggestReflection = "suggest_reflection"
}

// MARK: - Activity Types

enum ActivityType: String, Codable, CaseIterable {
    case creative = "creative"
    case analytical = "analytical"
    case communication = "communication"
    case planning = "planning"
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
    case analysis = "analysis"
    
    var displayName: String {
        switch self {
        case .creative: return "Creative Work"
        case .analytical: return "Analytical Tasks"
        case .communication: return "Communication"
        case .planning: return "Planning"
        case .learning: return "Learning"
        case .writing: return "Writing"
        case .problemSolving: return "Problem Solving"
        case .research: return "Research"
        case .meetings: return "Meetings"
        case .collaboration: return "Collaboration"
        case .routine: return "Routine Tasks"
        case .administrative: return "Administrative Work"
        case .organization: return "Organization"
        case .synthesis: return "Synthesis"
        case .brainstorming: return "Brainstorming"
        case .reflection: return "Reflection"
        case .review: return "Review"
        case .social: return "Social Activities"
        case .relaxation: return "Relaxation"
        case .analysis: return "Analysis"
        }
    }
}

// MARK: - Communication Style

struct CommunicationStyle: Codable {
    let verbosity: Verbosity
    let tone: Tone
    let detailLevel: DetailLevel
    let urgencyLevel: UrgencyLevel
    
    // FIXED: Add missing static properties
    static var brief: CommunicationStyle {
        return CommunicationStyle(
            verbosity: .concise,
            tone: .professional,
            detailLevel: .brief,
            urgencyLevel: .medium
        )
    }
    
    static var conversational: CommunicationStyle {
        return CommunicationStyle(
            verbosity: .balanced,
            tone: .friendly,
            detailLevel: .standard,
            urgencyLevel: .low
        )
    }
    
    static var detailed: CommunicationStyle {
        return CommunicationStyle(
            verbosity: .verbose,
            tone: .professional,
            detailLevel: .comprehensive,
            urgencyLevel: .low
        )
    }
}

enum Verbosity: String, Codable {
    case concise, balanced, verbose
}

enum Tone: String, Codable {
    case professional, friendly, casual, formal
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

// FIXED: UUID Codable warning - exclude id from decoding
extension EnergyForecastPoint {
    enum CodingKeys: String, CodingKey {
        case time, energyLevel, phase, activities
        // Note: 'id' is excluded - will be generated fresh on decode
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

// FIXED: UUID Codable warning - exclude id from decoding
extension ActivityWindow {
    enum CodingKeys: String, CodingKey {
        case activity, startTime, endTime, energyLevel, confidence
        // Note: 'id' is excluded - will be generated fresh on decode
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
    
    init(patternType: String, timeRange: DateInterval, frequency: Int, confidence: Double, metadata: [String: String] = [:]) {
        self.patternType = patternType
        self.timeRange = timeRange
        self.frequency = frequency
        self.confidence = confidence
        self.metadata = metadata
    }
}

// FIXED: UUID Codable warning - exclude id from decoding
extension TemporalPattern {
    enum CodingKeys: String, CodingKey {
        case patternType, timeRange, frequency, confidence, metadata
        // Note: 'id' is excluded - will be generated fresh on decode
    }
}

struct DailyIntelligence: Codable {
    let date: Date
    let recommendedFocus: ActivityType
    let energyPattern: [EnergyForecastPoint]
    let overallEnergyForecast: Double
    let recommendedActivities: [ActivityType]
    let communicationStyle: CommunicationStyle
    let insights: [String]
    let confidence: Double
    
    init(date: Date, recommendedFocus: ActivityType, energyPattern: [EnergyForecastPoint], overallEnergyForecast: Double, recommendedActivities: [ActivityType], communicationStyle: CommunicationStyle, insights: [String], confidence: Double) {
        self.date = date
        self.recommendedFocus = recommendedFocus
        self.energyPattern = energyPattern
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

// MARK: - Temporal Predictions (MISSING TYPE DEFINITION)

struct TemporalPrediction: Codable, Identifiable {
    let id = UUID()
    let type: PredictionType
    let content: String
    let confidence: Double
    let reasoning: String
    let temporalContext: String
    let validityWindow: TimeInterval
    let timestamp: Date
    
    init(type: PredictionType, content: String, confidence: Double, reasoning: String, temporalContext: String, validityWindow: TimeInterval) {
        self.type = type
        self.content = content
        self.confidence = confidence
        self.reasoning = reasoning
        self.temporalContext = temporalContext
        self.validityWindow = validityWindow
        self.timestamp = Date()
    }
    
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < validityWindow
    }
}

// FIXED: UUID Codable warning - exclude id from decoding
extension TemporalPrediction {
    enum CodingKeys: String, CodingKey {
        case type, content, confidence, reasoning, temporalContext, validityWindow, timestamp
        // Note: 'id' is excluded - will be generated fresh on decode
    }
}

enum PredictionType: String, Codable {
    case taskOriented = "task_oriented"
    case reflective = "reflective"
    case seasonal = "seasonal"
    case energyBased = "energy_based"
    case patternBased = "pattern_based"
}
