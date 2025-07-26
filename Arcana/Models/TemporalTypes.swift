//
// TemporalTypes.swift
// Arcana - Temporal Intelligence Types (Non-Conflicting)
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
// DEPENDENCIES: UnifiedTypes.swift
//
// NOTE: This file contains ONLY types that don't conflict with UnifiedTypes.swift
// CircadianPhase, TimeOfDay, Season are already defined in UnifiedTypes.swift

import Foundation

// MARK: - Advanced Temporal Types (Non-Conflicting)

struct TemporalContext {
    let timestamp: Date
    let circadianPhase: CircadianPhase  // From UnifiedTypes.swift
    let energyLevel: Double
    let cognitiveOptimality: Double
    let season: Season                  // From UnifiedTypes.swift
    let dayOfWeek: Int
    let timeOfDay: TimeOfDay           // From UnifiedTypes.swift
    
    init() {
        self.timestamp = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        
        // Use the CircadianPhase from UnifiedTypes.swift
        self.circadianPhase = CircadianPhase.fromHour(hour)
        self.energyLevel = circadianPhase.energyLevel
        self.cognitiveOptimality = energyLevel * 0.9
        
        // Use Season from UnifiedTypes.swift
        let month = calendar.component(.month, from: timestamp)
        switch month {
        case 12, 1, 2: self.season = .winter
        case 3, 4, 5: self.season = .spring
        case 6, 7, 8: self.season = .summer
        case 9, 10, 11: self.season = .autumn
        default: self.season = .spring
        }
        
        // Use TimeOfDay from UnifiedTypes.swift
        switch hour {
        case 5...8: self.timeOfDay = .earlyMorning
        case 9...11: self.timeOfDay = .morning
        case 12...17: self.timeOfDay = .afternoon
        case 18...21: self.timeOfDay = .evening
        default: self.timeOfDay = .night
        }
        
        self.dayOfWeek = calendar.component(.weekday, from: timestamp)
    }
    
    static func determineSeason(for date: Date) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .spring
        }
    }
}

struct EnhancedTemporalContext {
    let timestamp: Date
    let circadianPhase: CircadianPhase      // From UnifiedTypes.swift
    let energyLevel: Double
    let cognitiveOptimality: Double
    let seasonalContext: SeasonalContext?
    let userPatternMatch: UserPatternMatch?
    let temporalRecommendations: [TemporalRecommendation]
}

struct CircadianState {
    let currentPhase: CircadianPhase        // From UnifiedTypes.swift
    let energyLevel: Double
    let cognitiveOptimality: Double
    let nextOptimalPhase: CircadianPhase    // From UnifiedTypes.swift
    let timeToNextPhase: TimeInterval
    
    init() {
        let hour = Calendar.current.component(.hour, from: Date())
        self.currentPhase = CircadianPhase.fromHour(hour)
        self.energyLevel = currentPhase.energyLevel
        self.cognitiveOptimality = energyLevel * 0.9
        
        // Calculate next phase
        let nextHour = (hour + 1) % 24
        self.nextOptimalPhase = CircadianPhase.fromHour(nextHour)
        self.timeToNextPhase = 3600 // 1 hour
    }
}

struct SeasonalContext {
    let season: Season                      // From UnifiedTypes.swift
    let weekInSeason: Int
    let seasonalEnergy: Double
    let seasonalMood: String
}

struct UserPatternMatch {
    let patternType: PatternType
    let confidence: Double
    let historicalData: [String: Any]
    let suggestions: [String]
    
    enum PatternType {
        case productivity
        case communication
        case creativity
        case focus
    }
}

struct TemporalRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let priority: Priority
    let timeframe: String
    
    enum RecommendationType {
        case circadian
        case seasonal
        case productivity
        case wellness
    }
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct CircadianInsights {
    let currentState: CircadianState
    let recommendations: [TemporalRecommendation]
    let optimalWindows: [ActivityWindow]
    let energyForecast: [EnergyPoint]
}

struct ActivityWindow {
    let activity: ActivityType
    let startTime: Date
    let endTime: Date
    let energyLevel: Double
    let confidence: Double
}

struct EnergyPoint {
    let time: Date
    let predictedEnergy: Double
    let confidence: Double
}

struct TemporalPrediction {
    let category: PredictionCategory
    let prediction: String
    let confidence: Double
    let timeframe: String
    
    enum PredictionCategory {
        case productivity
        case mood
        case creativity
        case focus
    }
}

// MARK: - Activity and Communication Types

enum ActivityType: String, CaseIterable {
    case coding = "coding"
    case creative = "creative"
    case analysis = "analysis"
    case social = "social"
    case relaxation = "relaxation"
    case routine = "routine"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum CommunicationStyle: String, CaseIterable {
    case energetic = "energetic"
    case calm = "calm"
    case focused = "focused"
    case creative = "creative"
    case supportive = "supportive"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Enhanced CircadianPhase Extension (Non-Conflicting)

extension CircadianPhase {
    var optimalActivities: [ActivityType] {
        switch self {
        case .dawn: return [.relaxation]
        case .morning: return [.analysis, .coding]
        case .midday: return [.analysis, .coding, .creative]
        case .afternoon: return [.creative, .social]
        case .evening: return [.creative, .relaxation]
        case .night, .deepSleep: return [.relaxation]
        }
    }
    
    var displayName: String {
        switch self {
        case .dawn: return "Dawn"
        case .morning: return "Morning Focus"
        case .midday: return "Midday Peak"
        case .afternoon: return "Afternoon Creative"
        case .evening: return "Evening Reflection"
        case .night: return "Night Wind Down"
        case .deepSleep: return "Deep Sleep"
        }
    }
}
