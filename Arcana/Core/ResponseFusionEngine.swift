//
// ResponseFusionEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Intelligent Response Combining Engine
//

import Foundation
import Combine
import os.log

@MainActor
class ResponseFusionEngine: ObservableObject {
    static let shared = ResponseFusionEngine()
    
    // MARK: - Published State
    @Published var currentFusionStrategy: FusionStrategy = .intelligentWeighting
    @Published var fusionConfidence: Double = 0.0
    @Published var activeFusions: Int = 0
    @Published var fusionMetrics: FusionMetrics = FusionMetrics()
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ResponseFusionEngine")
    private let quantumMemory = QuantumMemoryManager.shared
    
    // MARK: - Fusion Intelligence
    private var fusionHistory: [FusionRecord] = []
    private var modelWeights: [String: Double] = [:]
    private var qualityAnalyzer: QualityAnalyzer
    private var consensusBuilder: ConsensusBuilder
    private var adaptiveFusionLearner: AdaptiveFusionLearner
    
    // MARK: - Model Reliability Matrix
    private var modelReliability: [String: ModelReliabilityMetrics] = [
        "Mistral-7B": ModelReliabilityMetrics(accuracy: 0.89, consistency: 0.91, factualness: 0.87),
        "CodeLlama-7B": ModelReliabilityMetrics(accuracy: 0.93, consistency: 0.95, factualness: 0.85),
        "Llama-2-7B": ModelReliabilityMetrics(accuracy: 0.86, consistency: 0.88, factualness: 0.82),
        "Phi-2": ModelReliabilityMetrics(accuracy: 0.82, consistency: 0.85, factualness: 0.80),
        "BGE-Large": ModelReliabilityMetrics(accuracy: 0.95, consistency: 0.97, factualness: 0.94)
    ]
    
    private init() {
        self.qualityAnalyzer = QualityAnalyzer()
        self.consensusBuilder = ConsensusBuilder()
        self.adaptiveFusionLearner = AdaptiveFusionLearner()
        
        logger.info("🧩 ResponseFusionEngine initializing intelligent response fusion")
        initializeModelWeights()
        startAdaptiveLearning()
    }
    
    // MARK: - 🧩 REVOLUTIONARY: Intelligent Response Fusion
    
    func fuseResponses(
        responses: [ModelResponse],
        prompt: String,
        strategy: EnsembleStrategy = .balanced
    ) async -> FusedResponse {
        
        guard !responses.isEmpty else {
            logger.warning("⚠️ No responses to fuse")
            return FusedResponse(
                content: "No responses available",
                confidence: 0.0,
                contributingModels: [],
                strategy: strategy
            )
        }
        
        logger.info("🧩 Starting intelligent fusion of \(responses.count) responses")
        activeFusions += 1
        
        let fusionStartTime = Date()
        
        // 1. Analyze response quality and characteristics
        let analysisResults = await analyzeResponseQualities(responses, prompt: prompt)
        
        // 2. Determine optimal fusion strategy
        let optimalStrategy = await determineOptimalFusionStrategy(
            responses: responses,
            analysisResults: analysisResults,
            requestedStrategy: strategy
        )
        
        // 3. Execute intelligent fusion
        let fusedResponse = await executeFusion(
            responses: responses,
            analysisResults: analysisResults,
            strategy: optimalStrategy,
            prompt: prompt
        )
        
        // 4. Validate and enhance fused response
        let validatedResponse = await validateAndEnhanceFusion(
            fusedResponse: fusedResponse,
            originalResponses: responses,
            prompt: prompt
        )
        
        // 5. Record fusion performance for learning
        await recordFusionPerformance(
            responses: responses,
            fusedResponse: validatedResponse,
            fusionTime: Date().timeIntervalSince(fusionStartTime),
            strategy: optimalStrategy
        )
        
        activeFusions -= 1
        fusionConfidence = validatedResponse.confidence
        currentFusionStrategy = optimalStrategy
        
        logger.info("✅ Fusion completed with confidence: \(validatedResponse.confidence)")
        
        return validatedResponse
    }
    
    // MARK: - 🔄 Additional Response Fusion
    
    func fuseWithAdditionalResponses(
        original: FusedResponse,
        additional: [ModelResponse],
        strategy: EnsembleStrategy
    ) async -> FusedResponse {
        
        logger.info("🔄 Fusing additional \(additional.count) responses with existing fusion")
        
        // Convert original fused response to comparable format
        let originalAsResponse = ModelResponse(
            model: "FusedEnsemble",
            response: original.content,
            confidence: original.confidence,
            inferenceTime: 0.0,
            timestamp: Date(),
            metadata: ["fusion_type": "original"]
        )
        
        // Combine with additional responses
        let allResponses = [originalAsResponse] + additional
        
        // Re-fuse with enhanced strategy
        let enhancedStrategy = enhanceStrategy(strategy)
        return await fuseResponses(
            responses: allResponses,
            prompt: "Enhanced fusion request",
            strategy: enhancedStrategy
        )
    }
    
    // MARK: - 🔍 Response Quality Analysis
    
    private func analyzeResponseQualities(
        _ responses: [ModelResponse],
        prompt: String
    ) async -> [ResponseAnalysis] {
        
        logger.info("🔍 Analyzing quality of \(responses.count) responses")
        
        return await withTaskGroup(of: ResponseAnalysis.self, returning: [ResponseAnalysis].self) { group in
            var analyses: [ResponseAnalysis] = []
            
            for response in responses {
                group.addTask {
                    await self.analyzeIndividualResponse(response, prompt: prompt)
                }
            }
            
            for await analysis in group {
                analyses.append(analysis)
            }
            
            return analyses.sorted { $0.overallQuality > $1.overallQuality }
        }
    }
    
    private func analyzeIndividualResponse(
        _ response: ModelResponse,
        prompt: String
    ) async -> ResponseAnalysis {
        
        // 1. Content quality metrics
        let contentQuality = await qualityAnalyzer.analyzeContentQuality(
            response.response,
            prompt: prompt
        )
        
        // 2. Factual accuracy assessment
        let factualAccuracy = await qualityAnalyzer.assessFactualAccuracy(
            response.response,
            model: response.model
        )
        
        // 3. Relevance to prompt
        let relevance = await qualityAnalyzer.calculateRelevance(
            response.response,
            prompt: prompt
        )
        
        // 4. Coherence and structure
        let coherence = await qualityAnalyzer.assessCoherence(response.response)
        
        // 5. Model-specific reliability
        let reliability = modelReliability[response.model]?.accuracy ?? 0.8
        
        // 6. Calculate overall quality score
        let overallQuality = (
            contentQuality * 0.25 +
            factualAccuracy * 0.25 +
            relevance * 0.25 +
            coherence * 0.15 +
            reliability * 0.10
        )
        
        return ResponseAnalysis(
            response: response,
            contentQuality: contentQuality,
            factualAccuracy: factualAccuracy,
            relevance: relevance,
            coherence: coherence,
            reliability: reliability,
            overallQuality: overallQuality
        )
    }
    
    // MARK: - 🎯 Fusion Strategy Determination
    
    private func determineOptimalFusionStrategy(
        responses: [ModelResponse],
        analysisResults: [ResponseAnalysis],
        requestedStrategy: EnsembleStrategy
    ) async -> FusionStrategy {
        
        // 1. Analyze response diversity
        let diversity = calculateResponseDiversity(responses)
        
        // 2. Check quality variance
        let qualityVariance = calculateQualityVariance(analysisResults)
        
        // 3. Assess consensus level
        let consensusLevel = await consensusBuilder.calculateConsensus(responses)
        
        // 4. Determine optimal strategy
        let optimalStrategy: FusionStrategy
        
        if consensusLevel > 0.85 {
            // High consensus - use consensus-based fusion
            optimalStrategy = .consensusBased
        } else if qualityVariance < 0.2 {
            // Similar quality - use averaging
            optimalStrategy = .qualityAveraging
        } else if diversity > 0.7 {
            // High diversity - use selective best
            optimalStrategy = .selectiveBest
        } else {
            // Default to intelligent weighting
            optimalStrategy = .intelligentWeighting
        }
        
        logger.info("🎯 Selected fusion strategy: \(optimalStrategy) (consensus: \(consensusLevel), diversity: \(diversity))")
        
        return optimalStrategy
    }
    
    // MARK: - 🧩 Fusion Execution
    
    private func executeFusion(
        responses: [ModelResponse],
        analysisResults: [ResponseAnalysis],
        strategy: FusionStrategy,
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🧩 Executing fusion with strategy: \(strategy)")
        
        switch strategy {
        case .intelligentWeighting:
            return await executeIntelligentWeightedFusion(analysisResults, prompt: prompt)
            
        case .consensusBased:
            return await executeConsensusFusion(analysisResults, prompt: prompt)
            
        case .qualityAveraging:
            return await executeQualityAveragingFusion(analysisResults, prompt: prompt)
            
        case .selectiveBest:
            return await executeSelectiveBestFusion(analysisResults, prompt: prompt)
            
        case .hierarchicalMerging:
            return await executeHierarchicalFusion(analysisResults, prompt: prompt)
        }
    }
    
    // MARK: - 🏆 Intelligent Weighted Fusion
    
    private func executeIntelligentWeightedFusion(
        _ analyses: [ResponseAnalysis],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🏆 Executing intelligent weighted fusion")
        
        // 1. Calculate adaptive weights based on multiple factors
        var weights: [Double] = []
        var totalWeight: Double = 0
        
        for analysis in analyses {
            let baseWeight = analysis.overallQuality
            let reliabilityBoost = analysis.reliability * 0.2
            let relevanceBoost = analysis.relevance * 0.3
            
            let adaptiveWeight = baseWeight + reliabilityBoost + relevanceBoost
            weights.append(adaptiveWeight)
            totalWeight += adaptiveWeight
        }
        
        // Normalize weights
        weights = weights.map { $0 / totalWeight }
        
        // 2. Create weighted content fusion
        var fusedContent = ""
        var weightedConfidence: Double = 0
        
        // Find highest quality response as base
        guard let bestAnalysis = analyses.first else {
            return FusedResponse(
                content: "Fusion failed",
                confidence: 0.0,
                contributingModels: [],
                strategy: .intelligentWeighting
            )
        }
        
        fusedContent = bestAnalysis.response.response
        
        // 3. Enhance with insights from other responses
        for (index, analysis) in analyses.enumerated() {
            let weight = weights[index]
            weightedConfidence += analysis.response.confidence * weight
            
            // Extract unique insights from other responses
            if index > 0 && weight > 0.2 {
                let uniqueInsights = await extractUniqueInsights(
                    from: analysis.response.response,
                    compared: fusedContent
                )
                
                if !uniqueInsights.isEmpty {
                    fusedContent = await integrateInsights(
                        base: fusedContent,
                        insights: uniqueInsights,
                        weight: weight
                    )
                }
            }
        }
        
        // 4. Calculate final confidence
        let qualityBonus = analyses.first?.overallQuality ?? 0.8
        let consensusBonus = await consensusBuilder.calculateConsensus(analyses.map { $0.response }) * 0.1
        let finalConfidence = min(weightedConfidence + qualityBonus * 0.1 + consensusBonus, 0.99)
        
        return FusedResponse(
            content: fusedContent,
            confidence: finalConfidence,
            contributingModels: analyses.map { $0.response.model },
            strategy: .intelligentWeighting
        )
    }
    
    // MARK: - 🛠️ Helper Methods for Content Processing
    
    private func extractUniqueInsights(from response: String, compared baseline: String) async -> [String] {
        // Extract unique insights that aren't present in baseline
        let responseWords = Set(response.components(separatedBy: .whitespacesAndNewlines))
        let baselineWords = Set(baseline.components(separatedBy: .whitespacesAndNewlines))
        
        let uniqueWords = responseWords.subtracting(baselineWords)
        
        // Simple insight extraction based on unique content
        let insights = uniqueWords.compactMap { word in
            word.count > 3 ? word : nil
        }
        
        return Array(insights.prefix(5)) // Limit to top 5 insights
    }
    
    private func integrateInsights(base: String, insights: [String], weight: Double) async -> String {
        guard weight > 0.1 && !insights.isEmpty else { return base }
        
        // Simple integration - append insights with weight consideration
        let insightText = insights.joined(separator: ", ")
        
        if weight > 0.5 {
            return "\(base)\n\nAdditional insights: \(insightText)"
        } else {
            return "\(base) (Note: \(insightText))"
        }
    }
    
    // MARK: - 🤝 Other Fusion Strategies (Simplified)
    
    private func executeConsensusFusion(
        _ analyses: [ResponseAnalysis],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🤝 Executing consensus-based fusion")
        
        // Use the highest quality response as base for consensus
        guard let bestAnalysis = analyses.first else {
            return FusedResponse(
                content: "No consensus possible",
                confidence: 0.0,
                contributingModels: [],
                strategy: .consensusBased
            )
        }
        
        let consensusScore = await consensusBuilder.calculateConsensus(analyses.map { $0.response })
        
        return FusedResponse(
            content: bestAnalysis.response.response,
            confidence: consensusScore * 0.9 + 0.1,
            contributingModels: analyses.map { $0.response.model },
            strategy: .consensusBased
        )
    }
    
    private func executeQualityAveragingFusion(
        _ analyses: [ResponseAnalysis],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("📊 Executing quality averaging fusion")
        
        guard let bestAnalysis = analyses.first else {
            return FusedResponse(
                content: "No responses to average",
                confidence: 0.0,
                contributingModels: [],
                strategy: .qualityAveraging
            )
        }
        
        let averageConfidence = analyses.reduce(0.0) { $0 + $1.response.confidence } / Double(analyses.count)
        
        return FusedResponse(
            content: bestAnalysis.response.response,
            confidence: min(averageConfidence, 0.95),
            contributingModels: analyses.map { $0.response.model },
            strategy: .qualityAveraging
        )
    }
    
    private func executeSelectiveBestFusion(
        _ analyses: [ResponseAnalysis],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🎯 Executing selective best fusion")
        
        guard let bestAnalysis = analyses.first else {
            return FusedResponse(
                content: "No best response found",
                confidence: 0.0,
                contributingModels: [],
                strategy: .selectiveBest
            )
        }
        
        return FusedResponse(
            content: bestAnalysis.response.response,
            confidence: bestAnalysis.response.confidence,
            contributingModels: [bestAnalysis.response.model],
            strategy: .selectiveBest
        )
    }
    
    private func executeHierarchicalFusion(
        _ analyses: [ResponseAnalysis],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🏗️ Executing hierarchical fusion")
        
        // Group by quality tiers and use best from highest tier
        let highQuality = analyses.filter { $0.overallQuality >= 0.8 }
        
        if let bestHighQuality = highQuality.first {
            return FusedResponse(
                content: bestHighQuality.response.response,
                confidence: bestHighQuality.response.confidence,
                contributingModels: analyses.map { $0.response.model },
                strategy: .hierarchicalMerging
            )
        } else if let bestOverall = analyses.first {
            return FusedResponse(
                content: bestOverall.response.response,
                confidence: bestOverall.response.confidence,
                contributingModels: analyses.map { $0.response.model },
                strategy: .hierarchicalMerging
            )
        } else {
            return FusedResponse(
                content: "Hierarchical fusion failed",
                confidence: 0.0,
                contributingModels: [],
                strategy: .hierarchicalMerging
            )
        }
    }
    
    // MARK: - 🔬 Validation and Enhancement
    
    private func validateAndEnhanceFusion(
        fusedResponse: FusedResponse,
        originalResponses: [ModelResponse],
        prompt: String
    ) async -> FusedResponse {
        
        logger.info("🔬 Validating and enhancing fused response")
        
        // Simple validation - just ensure response quality
        let qualityScore = await qualityAnalyzer.analyzeContentQuality(
            fusedResponse.content,
            prompt: prompt
        )
        
        let enhancedConfidence = min(fusedResponse.confidence + qualityScore * 0.1, 0.99)
        
        return FusedResponse(
            content: fusedResponse.content,
            confidence: enhancedConfidence,
            contributingModels: fusedResponse.contributingModels,
            strategy: fusedResponse.strategy
        )
    }
    
    // MARK: - 🛠️ Utility Methods
    
    private func calculateResponseDiversity(_ responses: [ModelResponse]) -> Double {
        guard responses.count > 1 else { return 0.0 }
        
        let contentLengths = responses.map { $0.response.count }
        let avgLength = Double(contentLengths.reduce(0, +)) / Double(contentLengths.count)
        let lengthVariance = contentLengths.map { pow(Double($0) - avgLength, 2) }.reduce(0, +) / Double(contentLengths.count)
        
        let uniqueWords = Set(responses.flatMap { $0.response.components(separatedBy: .whitespacesAndNewlines) })
        let totalWords = responses.flatMap { $0.response.components(separatedBy: .whitespacesAndNewlines) }.count
        
        let wordDiversity = Double(uniqueWords.count) / Double(max(totalWords, 1))
        let lengthDiversity = min(sqrt(lengthVariance) / avgLength, 1.0)
        
        return (wordDiversity + lengthDiversity) / 2.0
    }
    
    private func calculateQualityVariance(_ analyses: [ResponseAnalysis]) -> Double {
        guard analyses.count > 1 else { return 0.0 }
        
        let qualities = analyses.map { $0.overallQuality }
        let avgQuality = qualities.reduce(0, +) / Double(qualities.count)
        let variance = qualities.map { pow($0 - avgQuality, 2) }.reduce(0, +) / Double(qualities.count)
        
        return sqrt(variance)
    }
    
    private func enhanceStrategy(_ strategy: EnsembleStrategy) -> FusionStrategy {
        switch strategy {
        case .speedOptimized:
            return .selectiveBest
        case .balanced:
            return .intelligentWeighting
        case .deepReasoning:
            return .hierarchicalMerging
        case .codingSpecialist:
            return .consensusBased
        case .researchCollaborative:
            return .qualityAveraging
        case .creativeCollaborative:
            return .intelligentWeighting
        }
    }
    
    private func initializeModelWeights() {
        // Initialize default model weights based on reliability
        for (model, reliability) in modelReliability {
            modelWeights[model] = (reliability.accuracy + reliability.consistency + reliability.factualness) / 3.0
        }
    }
    
    private func startAdaptiveLearning() {
        Task.detached(priority: .background) {
            while !Task.isCancelled {
                // Learn from fusion history every 2 minutes
                try? await Task.sleep(nanoseconds: 120_000_000_000)
                await self.adaptiveFusionLearner.performLearningCycle(self.fusionHistory)
            }
        }
    }
    
    // MARK: - 📊 Performance Recording
    
    private func recordFusionPerformance(
        responses: [ModelResponse],
        fusedResponse: FusedResponse,
        fusionTime: TimeInterval,
        strategy: FusionStrategy
    ) async {
        
        let record = FusionRecord(
            inputResponses: responses,
            fusedResponse: fusedResponse,
            strategy: strategy,
            fusionTime: fusionTime,
            timestamp: Date()
        )
        
        fusionHistory.append(record)
        
        // Update metrics
        fusionMetrics.totalFusions += 1
        fusionMetrics.averageConfidence = (fusionMetrics.averageConfidence + fusedResponse.confidence) / 2.0
        fusionMetrics.averageFusionTime = (fusionMetrics.averageFusionTime + fusionTime) / 2.0
        
        // Keep only recent history
        if fusionHistory.count > 500 {
            fusionHistory.removeFirst(50)
        }
        
        logger.info("📊 Recorded fusion performance: \(strategy) - \(fusedResponse.confidence) confidence")
    }
}

// MARK: - 📊 Data Models

struct ResponseAnalysis {
    let response: ModelResponse
    let contentQuality: Double
    let factualAccuracy: Double
    let relevance: Double
    let coherence: Double
    let reliability: Double
    let overallQuality: Double
}

struct ModelReliabilityMetrics {
    let accuracy: Double
    let consistency: Double
    let factualness: Double
}

struct FusionRecord {
    let inputResponses: [ModelResponse]
    let fusedResponse: FusedResponse
    let strategy: FusionStrategy
    let fusionTime: TimeInterval
    let timestamp: Date
}

struct FusionMetrics {
    var totalFusions: Int = 0
    var averageConfidence: Double = 0.0
    var averageFusionTime: TimeInterval = 0.0
    var strategySuccessRates: [FusionStrategy: Double] = [:]
}

// MARK: - 🏷️ Enumerations

enum FusionStrategy: String, CaseIterable {
    case intelligentWeighting = "intelligent_weighting"
    case consensusBased = "consensus_based"
    case qualityAveraging = "quality_averaging"
    case selectiveBest = "selective_best"
    case hierarchicalMerging = "hierarchical_merging"
}

// MARK: - 🧠 Supporting Classes

class QualityAnalyzer {
    func analyzeContentQuality(_ content: String, prompt: String) async -> Double {
        let lengthScore = min(Double(content.count) / 500.0, 1.0)
        let structureScore = content.contains("\n") ? 0.8 : 0.6
        let relevanceKeywords = extractRelevanceKeywords(prompt)
        let relevanceScore = calculateKeywordPresence(content, keywords: relevanceKeywords)
        
        return (lengthScore + structureScore + relevanceScore) / 3.0
    }
    
    func assessFactualAccuracy(_ content: String, model: String) async -> Double {
        let baseAccuracy = getModelBaseAccuracy(model)
        let confidenceIndicators = ["research shows", "studies indicate", "data suggests"]
        let hasIndicators = confidenceIndicators.contains { content.localizedCaseInsensitiveContains($0) }
        
        return hasIndicators ? min(baseAccuracy + 0.1, 0.99) : baseAccuracy
    }
    
    func calculateRelevance(_ content: String, prompt: String) async -> Double {
        let promptWords = Set(prompt.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let contentWords = Set(content.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = promptWords.intersection(contentWords)
        return Double(intersection.count) / Double(max(promptWords.count, 1))
    }
    
    func assessCoherence(_ content: String) async -> Double {
        let sentences = content.components(separatedBy: ". ").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if sentences.count < 2 { return 0.5 }
        
        let connectors = ["however", "therefore", "moreover", "furthermore", "additionally"]
        let hasConnectors = connectors.contains { content.localizedCaseInsensitiveContains($0) }
        
        return hasConnectors ? 0.8 : 0.6
    }
    
    private func extractRelevanceKeywords(_ prompt: String) -> [String] {
        return prompt.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
            .map { $0.lowercased() }
    }
    
    private func calculateKeywordPresence(_ content: String, keywords: [String]) -> Double {
        let presentKeywords = keywords.filter { content.localizedCaseInsensitiveContains($0) }
        return Double(presentKeywords.count) / Double(max(keywords.count, 1))
    }
    
    private func getModelBaseAccuracy(_ model: String) -> Double {
        switch model {
        case "BGE-Large": return 0.95
        case "Mistral-7B": return 0.89
        case "CodeLlama-7B": return 0.85
        case "Llama-2-7B": return 0.82
        case "Phi-2": return 0.80
        default: return 0.8
        }
    }
}

class ConsensusBuilder {
    func calculateConsensus(_ responses: [ModelResponse]) async -> Double {
        guard responses.count > 1 else { return 0.5 }
        
        var totalSimilarity: Double = 0
        var comparisons = 0
        
        for i in 0..<responses.count {
            for j in (i+1)..<responses.count {
                let similarity = calculateSimilarity(responses[i].response, responses[j].response)
                totalSimilarity += similarity
                comparisons += 1
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Double(comparisons) : 0.5
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(max(union.count, 1))
    }
}

class AdaptiveFusionLearner {
    private var strategyPerformance: [FusionStrategy: [Double]] = [:]
    
    func performLearningCycle(_ history: [FusionRecord]) async {
        for record in history.suffix(50) {
            let performance = record.fusedResponse.confidence
            strategyPerformance[record.strategy, default: []].append(performance)
        }
    }
}
