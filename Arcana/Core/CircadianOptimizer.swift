//
// CircadianOptimizer.swift
// Arcana - Circadian rhythm optimization for responses
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
//

import Foundation

@MainActor
class CircadianOptimizer: ObservableObject {
    
    // MARK: - Circadian State
    @Published var currentCircadianState: CircadianState
    @Published var energyForecast: [EnergyForecastPoint] = []
    @Published var optimalActivityWindows: [ActivityWindow] = []
    
    // MARK: - User Circadian Profile
    private var userCircadianProfile: UserCircadianProfile
    private var circadianCalibration: CircadianCalibration
    
    // MARK: - Learning Components
    private let circadianLearner = CircadianLearner()
    private let energyTracker = EnergyTracker()
    
    init() {
        self.currentCircadianState = CircadianState()
        self.userCircadianProfile = UserCircadianProfile()
        self.circadianCalibration = CircadianCalibration()
    }
    
    func initialize() async {
        print("🌅 Initializing Circadian Optimizer...")
        
        // Load user's circadian profile
        await loadUserCircadianProfile()
        
        // Start energy tracking
        await energyTracker.startTracking()
        
        // Initialize learning components
        await circadianLearner.initialize()
        
        // Generate initial forecasts
        await updateEnergyForecast()
        await updateOptimalActivityWindows()
        
        print("✅ Circadian Optimizer ready")
    }
    
    // MARK: - Core Circadian Analysis
    
    func analyzeCircadianOptimality(at time: Date) async -> CircadianInsights {
        let phase = await getCurrentPhase(at: time)
        let energyLevel = calculateEnergyLevel(at: time, phase: phase)
        let cognitiveOptimality = calculateCognitiveOptimality(at: time, phase: phase)
        
        let insights = CircadianInsights(
            timestamp: time,
            currentPhase: phase,
            energyLevel: energyLevel,
            cognitiveOptimality: cognitiveOptimality,
            recommendedActivities: getRecommendedActivities(for: phase),
            avoidActivities: getActivitiesToAvoid(for: phase),
            recommendations: generateCircadianRecommendations(
                phase: phase,
                energy: energyLevel,
                cognitive: cognitiveOptimality
            )
        )
        
        // Learn from user interaction patterns
        await circadianLearner.recordInteraction(insights: insights)
        
        return insights
    }
    
    func getCurrentPhase(at time: Date = Date()) async -> CircadianPhase {
        let hour = Calendar.current.component(.hour, from: time)
        let minute = Calendar.current.component(.minute, from: time)
        let timeDecimal = Double(hour) + Double(minute) / 60.0
        
        // Adjust for user's chronotype
        let adjustedTime = adjustForChronotype(time: timeDecimal)
        
        switch adjustedTime {
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
    
    func getCurrentCircadianState() async -> CircadianState {
        let now = Date()
        let phase = await getCurrentPhase(at: now)
        let energyLevel = calculateEnergyLevel(at: now, phase: phase)
        
        return CircadianState(
            currentPhase: phase,
            energyLevel: energyLevel,
            morningOptimalityScore: calculatePhaseOptimality(.morningFocus),
            afternoonCreativityScore: calculatePhaseOptimality(.afternoonCreative),
            eveningReflectionScore: calculatePhaseOptimality(.eveningReflection),
            lastUpdated: now
        )
    }
    
    // MARK: - Response Optimization
    
    func optimizeResponse(
        response: String,
        circadianPhase: CircadianPhase,
        energyLevel: Double
    ) async -> String {
        
        var optimizedResponse = response
        
        // Apply phase-specific optimizations
        switch circadianPhase {
        case .morningFocus, .midMorningPeak:
            optimizedResponse = await applyMorningOptimization(response)
        case .afternoonCreative:
            optimizedResponse = await applyCreativeOptimization(response)
        case .eveningReflection:
            optimizedResponse = await applyReflectiveOptimization(response)
        case .lunchDip, .eveningTransition:
            optimizedResponse = await applyGentleOptimization(response)
        case .lateNightLow, .earlyMorningLow:
            optimizedResponse = await applySoftOptimization(response)
        default:
            break
        }
        
        // Apply energy-level adjustments
        if energyLevel < 0.3 {
            optimizedResponse = await applyLowEnergyOptimization(optimizedResponse)
        } else if energyLevel > 0.8 {
            optimizedResponse = await applyHighEnergyOptimization(optimizedResponse)
        }
        
        return optimizedResponse
    }
    
    // MARK: - Energy Forecasting
    
    private func updateEnergyForecast() async {
        let now = Date()
        var forecast: [EnergyForecastPoint] = []
        
        // Generate 24-hour forecast
        for hour in 0..<24 {
            let futureTime = Calendar.current.date(byAdding: .hour, value: hour, to: now)!
            let phase = await getCurrentPhase(at: futureTime)
            let energy = calculateEnergyLevel(at: futureTime, phase: phase)
            
            forecast.append(EnergyForecastPoint(
                time: futureTime,
                energyLevel: energy,
                phase: phase,
                confidence: 0.8 - (Double(hour) * 0.02) // Confidence decreases over time
            ))
        }
        
        energyForecast = forecast
    }
    
    private func updateOptimalActivityWindows() async {
        let now = Date()
        var windows: [ActivityWindow] = []
        
        // Find optimal windows for different activities
        let activities: [ActivityType] = [.creative, .analytical, .communication, .planning]
        
        for activity in activities {
            let optimalTimes = await findOptimalTimeWindows(for: activity, from: now)
            windows.append(contentsOf: optimalTimes)
        }
        
        optimalActivityWindows = windows.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadUserCircadianProfile() async {
        // Load from persistence or use defaults
        userCircadianProfile = await CircadianPersistenceManager.shared.loadUserProfile()
        circadianCalibration = await CircadianPersistenceManager.shared.loadCalibration()
    }
    
    private func adjustForChronotype(time: Double) -> Double {
        // Adjust time based on user's chronotype (morning person, night owl, etc.)
        switch userCircadianProfile.chronotype {
        case .earlyBird:
            return time - 1.0 // Shift earlier
        case .nightOwl:
            return time + 1.0 // Shift later
        case .neutral:
            return time
        }
    }
    
    private func calculateEnergyLevel(at time: Date, phase: CircadianPhase) -> Double {
        let baseEnergy = phase.baseEnergyLevel
        let personalAdjustment = userCircadianProfile.getEnergyAdjustment(for: phase)
        let recentActivityImpact = energyTracker.getRecentActivityImpact()
        
        return min(1.0, max(0.0, baseEnergy + personalAdjustment + recentActivityImpact))
    }
    
    private func calculateCognitiveOptimality(at time: Date, phase: CircadianPhase) -> Double {
        let baseCognitive = phase.baseCognitiveOptimality
        let personalAdjustment = userCircadianProfile.getCognitiveAdjustment(for: phase)
        
        return min(1.0, max(0.0, baseCognitive + personalAdjustment))
    }
    
    private func calculatePhaseOptimality(_ phase: CircadianPhase) -> Double {
        // Calculate how optimal the given phase is relative to current time
        return phase.baseEnergyLevel * 0.7 + phase.baseCognitiveOptimality * 0.3
    }
    
    private func getRecommendedActivities(for phase: CircadianPhase) -> [ActivityType] {
        switch phase {
        case .morningFocus, .midMorningPeak:
            return [.analytical, .planning]
        case .afternoonCreative:
            return [.creative]
        case .eveningReflection:
            return [.communication, .planning]
        default:
            return []
        }
    }
    
    private func getActivitiesToAvoid(for phase: CircadianPhase) -> [ActivityType] {
        switch phase {
        case .lunchDip:
            return [.analytical]
        case .lateNightLow, .earlyMorningLow:
            return [.analytical, .creative]
        default:
            return []
        }
    }
    
    private func generateCircadianRecommendations(
        phase: CircadianPhase,
        energy: Double,
        cognitive: Double
    ) -> [TemporalRecommendation] {
        
        var recommendations: [TemporalRecommendation] = []
        
        if phase == .morningFocus && cognitive > 0.8 {
            recommendations.append(TemporalRecommendation(
                type: .circadianAlignment,
                title: "Peak Morning Focus",
                message: "Your cognitive performance is at its peak. Perfect time for complex problem-solving.",
                confidence: cognitive,
                action: .suggestComplexTasks
            ))
        }
        
        if phase == .afternoonCreative && energy > 0.7 {
            recommendations.append(TemporalRecommendation(
                type: .circadianAlignment,
                title: "Creative Peak Time",
                message: "Your creative energy is high. Great time for brainstorming and innovative thinking.",
                confidence: energy,
                action: .suggestCreativeTasks
            ))
        }
        
        if energy < 0.3 {
            recommendations.append(TemporalRecommendation(
                type: .energyManagement,
                title: "Low Energy Period",
                message: "Consider lighter tasks or taking a brief break to recharge.",
                confidence: 0.9,
                action: .suggestBreak
            ))
        }
        
        return recommendations
    }
    
    private func findOptimalTimeWindows(
        for activity: ActivityType,
        from startTime: Date
    ) async -> [ActivityWindow] {
        
        var windows: [ActivityWindow] = []
        let calendar = Calendar.current
        
        // Look ahead 24 hours
        for hour in 0..<24 {
            guard let time = calendar.date(byAdding: .hour, value: hour, to: startTime) else { continue }
            
            let phase = await getCurrentPhase(at: time)
            let suitability = calculateActivitySuitability(activity: activity, phase: phase)
            
            if suitability > 0.7 {
                // Find the duration of this optimal window
                var duration = 1
                var nextHour = hour + 1
                
                while nextHour < 24 {
                    guard let nextTime = calendar.date(byAdding: .hour, value: nextHour, to: startTime) else { break }
                    let nextPhase = await getCurrentPhase(at: nextTime)
                    let nextSuitability = calculateActivitySuitability(activity: activity, phase: nextPhase)
                    
                    if nextSuitability > 0.7 {
                        duration += 1
                        nextHour += 1
                    } else {
                        break
                    }
                }
                
                windows.append(ActivityWindow(
                    activity: activity,
                    startTime: time,
                    duration: duration,
                    suitabilityScore: suitability
                ))
            }
        }
        
        return windows
    }
    
    private func calculateActivitySuitability(activity: ActivityType, phase: CircadianPhase) -> Double {
        switch (activity, phase) {
        case (.analytical, .morningFocus), (.analytical, .midMorningPeak):
            return 0.9
        case (.creative, .afternoonCreative):
            return 0.9
        case (.communication, .afternoonPeak), (.communication, .eveningReflection):
            return 0.8
        case (.planning, .morningFocus), (.planning, .eveningReflection):
            return 0.8
        default:
            return 0.4
        }
    }
    
    // MARK: - Response Optimization Methods
    
    private func applyMorningOptimization(_ response: String) async -> String {
        let morningPrefixes = [
            "Let's tackle this step by step:",
            "Here's a structured approach:",
            "Starting with the fundamentals:"
        ]
        
        let prefix = morningPrefixes.randomElement()!
        return "\(prefix) \(response)"
    }
    
    private func applyCreativeOptimization(_ response: String) async -> String {
        let creativePrefixes = [
            "Here's an innovative approach:",
            "Let's think outside the box:",
            "Consider this creative solution:"
        ]
        
        let prefix = creativePrefixes.randomElement()!
        return "\(prefix) \(response)"
    }
    
    private func applyReflectiveOptimization(_ response: String) async -> String {
        let reflectivePrefixes = [
            "Looking at this thoughtfully:",
            "Taking a step back to consider:",
            "Reflecting on the bigger picture:"
        ]
        
        let prefix = reflectivePrefixes.randomElement()!
        return "\(prefix) \(response)"
    }
    
    private func applyGentleOptimization(_ response: String) async -> String {
        // Make response more gentle and supportive
        return "I understand this might be a transitional time. \(response)"
    }
    
    private func applySoftOptimization(_ response: String) async -> String {
        // Make response softer for low-energy periods
        return "Here's a gentle approach: \(response)"
    }
    
    private func applyLowEnergyOptimization(_ response: String) async -> String {
        // Simplify and shorten response for low energy
        let sentences = response.components(separatedBy: ". ")
        let simplified = Array(sentences.prefix(2)).joined(separator: ". ")
        return "Here's the key point: \(simplified)"
    }
    
    private func applyHighEnergyOptimization(_ response: String) async -> String {
        // Add more detail and energy for high-energy periods
        return "\(response)\n\nYou're in a great state to dive deeper into this topic. Would you like me to explore any specific aspects in more detail?"
    }
}

// MARK: - Supporting Stub Classes (Will be implemented)

class CircadianLearner {
    func initialize() async {}
    func recordInteraction(insights: CircadianInsights) async {}
}

class EnergyTracker {
    func startTracking() async {}
    func getRecentActivityImpact() -> Double { return 0.0 }
}

class UserCircadianProfile {
    let chronotype: Chronotype = .neutral
    
    func getEnergyAdjustment(for phase: CircadianPhase) -> Double { return 0.0 }
    func getCognitiveAdjustment(for phase: CircadianPhase) -> Double { return 0.0 }
}

class CircadianCalibration {}

class CircadianPersistenceManager {
    static let shared = CircadianPersistenceManager()
    func loadUserProfile() async -> UserCircadianProfile { return UserCircadianProfile() }
    func loadCalibration() async -> CircadianCalibration { return CircadianCalibration() }
}

enum Chronotype { case earlyBird, nightOwl, neutral }

// MARK: - Supporting Types

struct EnergyForecastPoint {
    let time: Date
    let energyLevel: Double
    let phase: CircadianPhase
    let confidence: Double
}

struct ActivityWindow {
    let activity: ActivityType
    let startTime: Date
    let duration: Int // hours
    let suitabilityScore: Double
}
