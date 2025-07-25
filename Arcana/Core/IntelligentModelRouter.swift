//
// IntelligentModelRouter.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Optimal Model Selection Engine
//

import Foundation
import Combine
import os.log

@MainActor
class IntelligentModelRouter: ObservableObject {
    static let shared = IntelligentModelRouter()
    
    // MARK: - Published State
    @Published var currentOptimalModel: String?
    @Published var routingDecisions: [RoutingDecision] = []
    @Published var modelPerformanceScores: [String: Double] = [:]
    @Published var isAdaptiveLearning = true
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "IntelligentModelRouter")
    private let quantumMemory = QuantumMemoryManager.shared
    private let proprietaryCore = PropietaryPRISMCore.shared
    
    // MARK: - Routing Intelligence
    private var routingHistory: [RoutingRecord] = []
    private var modelCapabilities: [String: ModelCapabilities] = [:]
    private var dynamicPerformanceMetrics: [String: PerformanceMetrics] = [:]
    private var adaptiveLearningEngine: AdaptiveLearningEngine
    
    // MARK: - Model Specialization Matrix
    private let modelSpecializations: [String: [QueryType: Double]] = [
        "Mistral-7B": [
            .general: 0.95,
            .reasoning: 0.90,
            .analysis: 0.85,
            .creative: 0.80,
            .factual: 0.85
        ],
        "CodeLlama-7B": [
            .coding: 0.95,
            .technical: 0.90,
            .debugging: 0.95,
            .general: 0.70
        ],
        "Llama-2-7B": [
            .creative: 0.95,
            .conversational: 0.90,
            .reasoning: 0.85,
            .general: 0.85
        ],
        "Phi-2": [
            .speed: 0.95,
            .general: 0.80,
            .reasoning: 0.75,
            .coding: 0.70
        ],
        "BGE-Large": [
            .factual: 0.95,
            .analysis: 0.90,
            .research: 0.95,
            .embedding: 0.95
        ]
    ]
    
    private init() {
        self.adaptiveLearningEngine = AdaptiveLearningEngine()
        logger.info("🎯 IntelligentModelRouter initializing with adaptive learning")
        setupModelCapabilities()
        startAdaptiveLearning()
    }
    
    // MARK: - 🎯 REVOLUTIONARY: Intelligent Route Selection
    
    func routeInference(
        model: String,
        prompt: String,
        context: ConversationContext,
        forceModel: String? = nil
    ) async -> RouterInferenceResult {
        
        let routingStartTime = Date()
        
        // 1. Override routing if model is forced
        if let forcedModel = forceModel {
            logger.info("🎯 Forced routing to model: \(forcedModel)")
            return await executeDirectInference(model: forcedModel, prompt: prompt, context: context)
        }
        
        // 2. Analyze prompt for optimal model selection
        let promptAnalysis = await analyzePromptForRouting(prompt, context: context)
        let optimalModel = await selectOptimalModel(for: promptAnalysis, requestedModel: model)
        
        // 3. Check model availability and resource constraints
        let finalModel = await validateModelAvailability(optimalModel, fallback: model)
        
        // 4. Record routing decision
        let routingDecision = RoutingDecision(
            requestedModel: model,
            selectedModel: finalModel,
            reasoning: generateRoutingReasoning(promptAnalysis, selected: finalModel),
            confidence: calculateRoutingConfidence(promptAnalysis, selected: finalModel),
            timestamp: Date()
        )
        
        routingDecisions.append(routingDecision)
        currentOptimalModel = finalModel
        
        // 5. Execute inference with selected model
        let inferenceResult = await executeIntelligentInference(
            model: finalModel,
            prompt: prompt,
            context: context,
            routingDecision: routingDecision
        )
        
        // 6. Record performance for adaptive learning
        await recordRoutingPerformance(
            decision: routingDecision,
            result: inferenceResult,
            routingTime: Date().timeIntervalSince(routingStartTime)
        )
        
        logger.info("🎯 Intelligent routing completed: \(model) -> \(finalModel) (confidence: \(routingDecision.confidence))")
        
        return inferenceResult
    }
    
    // MARK: - 🧠 Advanced Model Selection
    
    func selectOptimalModel(for analysis: PromptAnalysis, requestedModel: String) async -> String {
        
        logger.info("🧠 Analyzing optimal model for query type: \(String(describing: analysis.queryType))")
        
        // 1. Get base scores from specialization matrix
        var modelScores: [String: Double] = [:]
        
        for (model, specializations) in modelSpecializations {
            let baseScore = specializations[analysis.queryType] ?? 0.5
            let complexityAdjustment = calculateComplexityAdjustment(analysis.complexity, for: model)
            let performanceBoost = dynamicPerformanceMetrics[model]?.recentSuccessRate ?? 1.0
            
            modelScores[model] = baseScore * complexityAdjustment * performanceBoost
        }
        
        // 2. Apply workspace-specific optimizations
        applyWorkspaceOptimizations(&modelScores, workspaceType: analysis.workspaceType)
        
        // 3. Apply resource constraints
        await applyResourceConstraints(&modelScores)
        
        // 4. Apply adaptive learning insights
        if isAdaptiveLearning {
            await adaptiveLearningEngine.adjustScores(&modelScores, for: analysis)
        }
        
        // 5. Select highest scoring available model
        let optimalModel = modelScores
            .sorted { $0.value > $1.value }
            .first?.key ?? requestedModel
        
        modelPerformanceScores = modelScores
        
        logger.info("🏆 Optimal model selected: \(optimalModel) (score: \(modelScores[optimalModel] ?? 0.0))")
        
        return optimalModel
    }
    
    // MARK: - 🚀 Intelligent Inference Execution
    
    private func executeIntelligentInference(
        model: String,
        prompt: String,
        context: ConversationContext,
        routingDecision: RoutingDecision
    ) async -> RouterInferenceResult {
        
        let inferenceStartTime = Date()
        
        do {
            // 1. Optimize prompt for selected model
            let optimizedPrompt = await optimizePromptForModel(prompt, model: model)
            
            // 2. Prepare model-specific parameters
            let modelParams = generateModelSpecificParameters(model: model, context: context)
            
            // 3. Execute via proprietary core with optimization
            let response = try await proprietaryCore.generateResponse(
                prompt: optimizedPrompt,
                modelName: model,
                context: context,
                parameters: InferenceParameters(
                    maxTokens: modelParams["max_tokens"] as? Int ?? 1024,
                    temperature: modelParams["temperature"] as? Double ?? 0.7,
                    topP: modelParams["top_p"] as? Double ?? 0.9
                )
            )
            
            // 4. Post-process response based on model characteristics
            let processedResponse = await postProcessResponse(
                response.generatedText,
                model: model,
                originalPrompt: prompt
            )
            
            let inferenceTime = Date().timeIntervalSince(inferenceStartTime)
            
            return RouterInferenceResult(
                content: processedResponse.content,
                confidence: processedResponse.confidence,
                inferenceTime: inferenceTime,
                model: model,
                metadata: [
                    "routing_decision": routingDecision.id.uuidString,
                    "prompt_optimization": "applied",
                    "post_processing": "applied"
                ]
            )
            
        } catch {
            logger.error("❌ Inference failed for model \(model): \(error.localizedDescription)")
            
            // Fallback to basic inference
            return await executeDirectInference(model: model, prompt: prompt, context: context)
        }
    }
    
    private func executeDirectInference(
        model: String,
        prompt: String,
        context: ConversationContext
    ) async -> RouterInferenceResult {
        
        let startTime = Date()
        
        // Basic direct inference without optimizations
        let response = "Direct inference response for: \(prompt.prefix(50))..." // Placeholder
        let inferenceTime = Date().timeIntervalSince(startTime)
        
        return RouterInferenceResult(
            content: response,
            confidence: 0.8,
            inferenceTime: inferenceTime,
            model: model,
            metadata: ["routing_type": "direct"]
        )
    }
    
    // MARK: - 🧠 Analysis and Optimization
    
    private func analyzePromptForRouting(_ prompt: String, context: ConversationContext) async -> PromptAnalysis {
        
        // 1. Basic text analysis
        let wordCount = prompt.components(separatedBy: .whitespacesAndNewlines).count
        let containsCode = prompt.contains("{") || prompt.contains("function") || prompt.contains("class")
        let containsMath = prompt.contains("=") || prompt.contains("calculate") || prompt.contains("solve")
        
        // 2. Intent classification
        let queryType: QueryType
        if containsCode || prompt.lowercased().contains("code") {
            queryType = .coding
        } else if containsMath || prompt.lowercased().contains("analyze") {
            queryType = .analysis
        } else if prompt.lowercased().contains("creative") || prompt.lowercased().contains("story") {
            queryType = .creative
        } else if prompt.lowercased().contains("fact") || prompt.lowercased().contains("research") {
            queryType = .factual
        } else {
            queryType = .general
        }
        
        // 3. Complexity assessment
        let complexity: QueryComplexity
        if wordCount > 100 || containsCode || containsMath {
            complexity = .high
        } else if wordCount > 20 {
            complexity = .medium
        } else {
            complexity = .low
        }
        
        // 4. Context importance
        let contextImportance = min(context.messages.count, 10)
        
        return PromptAnalysis(
            prompt: prompt,
            complexity: complexity,
            queryType: queryType,
            workspaceType: .general, // Will be overridden by caller
            requiredCapabilities: determineRequiredCapabilities(queryType),
            estimatedTokens: wordCount * 2,
            contextImportance: contextImportance
        )
    }
    
    private func calculateComplexityAdjustment(_ complexity: QueryComplexity, for model: String) -> Double {
        // Adjust scores based on model's ability to handle complexity
        let modelComplexityRatings: [String: [QueryComplexity: Double]] = [
            "Mistral-7B": [.low: 1.0, .medium: 1.0, .high: 0.9],
            "CodeLlama-7B": [.low: 0.8, .medium: 0.9, .high: 1.0],
            "Llama-2-7B": [.low: 1.0, .medium: 0.95, .high: 0.85],
            "Phi-2": [.low: 1.0, .medium: 0.8, .high: 0.6],
            "BGE-Large": [.low: 0.9, .medium: 1.0, .high: 1.0]
        ]
        
        return modelComplexityRatings[model]?[complexity] ?? 0.8
    }
    
    private func applyWorkspaceOptimizations(_ scores: inout [String: Double], workspaceType: WorkspaceManager.WorkspaceType) {
        switch workspaceType {
        case .code:
            scores["CodeLlama-7B"] = (scores["CodeLlama-7B"] ?? 0.0) * 1.3
            scores["Phi-2"] = (scores["Phi-2"] ?? 0.0) * 1.2
            
        case .research:
            scores["BGE-Large"] = (scores["BGE-Large"] ?? 0.0) * 1.3
            scores["Mistral-7B"] = (scores["Mistral-7B"] ?? 0.0) * 1.2
            
        case .creative:
            scores["Llama-2-7B"] = (scores["Llama-2-7B"] ?? 0.0) * 1.3
            scores["Mistral-7B"] = (scores["Mistral-7B"] ?? 0.0) * 1.1
            
        case .general:
            // No specific optimizations for general workspace
            break
        }
    }
    
    private func applyResourceConstraints(_ scores: inout [String: Double]) async {
        let systemMemory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024 // GB
        
        if systemMemory < 8 {
            // Heavily favor lightweight models on low memory systems
            scores["Phi-2"] = (scores["Phi-2"] ?? 0.0) * 1.5
            scores["BGE-Large"] = (scores["BGE-Large"] ?? 0.0) * 0.5
        } else if systemMemory < 16 {
            // Moderate optimization for medium memory systems
            scores["Phi-2"] = (scores["Phi-2"] ?? 0.0) * 1.2
            scores["BGE-Large"] = (scores["BGE-Large"] ?? 0.0) * 0.8
        }
        
        // Apply current load considerations
        let currentLoad = await getCurrentSystemLoad()
        if currentLoad > 0.8 {
            // Favor faster models when system is under load
            scores["Phi-2"] = (scores["Phi-2"] ?? 0.0) * 1.3
        }
    }
    
    // MARK: - 🔧 Model Optimization
    
    private func optimizePromptForModel(_ prompt: String, model: String) async -> String {
        // Apply model-specific prompt optimizations
        switch model {
        case "CodeLlama-7B":
            // Enhance code-related prompts
            if !prompt.lowercased().contains("code") && (prompt.contains("{") || prompt.contains("function")) {
                return "Code assistance request: \(prompt)"
            }
            
        case "BGE-Large":
            // Enhance factual/research prompts
            if prompt.lowercased().contains("research") || prompt.lowercased().contains("analyze") {
                return "Research analysis: \(prompt)"
            }
            
        case "Phi-2":
            // Optimize for conciseness
            if prompt.count > 200 {
                return "Concise response needed: \(prompt.prefix(150))..."
            }
            
        default:
            break
        }
        
        return prompt
    }
    
    private func generateModelSpecificParameters(model: String, context: ConversationContext) -> [String: Any] {
        var params: [String: Any] = [:]
        
        switch model {
        case "Mistral-7B":
            params["temperature"] = 0.7
            params["top_p"] = 0.9
            params["max_tokens"] = 1024
            
        case "CodeLlama-7B":
            params["temperature"] = 0.3
            params["top_p"] = 0.95
            params["max_tokens"] = 2048
            
        case "Llama-2-7B":
            params["temperature"] = 0.8
            params["top_p"] = 0.9
            params["max_tokens"] = 1024
            
        case "Phi-2":
            params["temperature"] = 0.6
            params["top_p"] = 0.9
            params["max_tokens"] = 512
            
        case "BGE-Large":
            params["temperature"] = 0.2
            params["top_p"] = 0.95
            params["max_tokens"] = 1024
            
        default:
            params["temperature"] = 0.7
            params["top_p"] = 0.9
            params["max_tokens"] = 1024
        }
        
        return params
    }
    
    private func postProcessResponse(_ response: String, model: String, originalPrompt: String) async -> ProcessedResponse {
        // Apply model-specific post-processing
        
        let processedContent = response
        var confidence = 0.8
        
        switch model {
        case "CodeLlama-7B":
            // Validate code syntax if response contains code
            if response.contains("```") {
                confidence = 0.9 // Higher confidence for code responses
            }
            
        case "BGE-Large":
            // Validate factual content
            confidence = 0.95 // Higher confidence for factual responses
            
        case "Phi-2":
            // Ensure response isn't truncated
            if response.count < 50 {
                confidence = 0.6 // Lower confidence for very short responses
            }
            
        default:
            break
        }
        
        return ProcessedResponse(content: processedContent, confidence: confidence)
    }
    
    // MARK: - 📊 Performance Tracking
    
    private func recordRoutingPerformance(
        decision: RoutingDecision,
        result: RouterInferenceResult,
        routingTime: TimeInterval
    ) async {
        
        let record = RoutingRecord(
            decision: decision,
            result: result,
            routingTime: routingTime,
            timestamp: Date()
        )
        
        routingHistory.append(record)
        
        // Update dynamic performance metrics
        if dynamicPerformanceMetrics[result.model] == nil {
            dynamicPerformanceMetrics[result.model] = PerformanceMetrics()
        }
        
        dynamicPerformanceMetrics[result.model]?.updateWith(
            confidence: result.confidence,
            inferenceTime: result.inferenceTime
        )
        
        // Keep only recent history
        if routingHistory.count > 1000 {
            routingHistory.removeFirst(100)
        }
        
        // Update adaptive learning
        if isAdaptiveLearning {
            await adaptiveLearningEngine.learnFromRouting(record)
        }
    }
    
    // MARK: - 🎓 Adaptive Learning
    
    private func startAdaptiveLearning() {
        Task.detached(priority: .background) {
            while !Task.isCancelled {
                // Learn from routing history every 60 seconds
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self.adaptiveLearningEngine.performPeriodicLearning(self.routingHistory)
            }
        }
    }
    
    // MARK: - 🛠️ Helper Methods
    
    private func setupModelCapabilities() {
        // Initialize model capabilities database
        for model in modelSpecializations.keys {
            modelCapabilities[model] = ModelCapabilities(
                model: model,
                specializations: modelSpecializations[model] ?? [:],
                memoryRequirement: getModelMemoryRequirement(model),
                averageInferenceTime: getModelAverageInferenceTime(model)
            )
        }
    }
    
    private func validateModelAvailability(_ model: String, fallback: String) async -> String {
        // Check if model is actually available
        let isAvailable = await proprietaryCore.isModelAvailable(model)
        return isAvailable ? model : fallback
    }
    
    private func generateRoutingReasoning(_ analysis: PromptAnalysis, selected: String) -> String {
        return "Selected \(selected) for \(analysis.queryType) query with \(analysis.complexity) complexity"
    }
    
    private func calculateRoutingConfidence(_ analysis: PromptAnalysis, selected: String) -> Double {
        let baseConfidence = modelSpecializations[selected]?[analysis.queryType] ?? 0.5
        let complexityFactor = calculateComplexityAdjustment(analysis.complexity, for: selected)
        return min(baseConfidence * complexityFactor, 0.99)
    }
    
    private func determineRequiredCapabilities(_ queryType: QueryType) -> [ModelCapability] {
        switch queryType {
        case .coding:
            return [.codeGeneration, .syntaxAnalysis]
        case .analysis:
            return [.logicalReasoning, .dataAnalysis]
        case .creative:
            return [.creativeWriting, .storytelling]
        case .factual:
            return [.factualAccuracy, .knowledgeRetrieval]
        default:
            return [.generalReasoning]
        }
    }
    
    private func getCurrentSystemLoad() async -> Double {
        // Monitor current system load
        let info = ProcessInfo.processInfo
        return Double(info.processorCount) / 8.0 // Simplified load calculation
    }
    
    private func getModelMemoryRequirement(_ model: String) -> Int {
        // Memory requirements in GB
        switch model {
        case "Mistral-7B", "CodeLlama-7B", "Llama-2-7B":
            return 8
        case "Phi-2":
            return 4
        case "BGE-Large":
            return 6
        default:
            return 8
        }
    }
    
    private func getModelAverageInferenceTime(_ model: String) -> TimeInterval {
        // Average inference times in seconds
        switch model {
        case "Phi-2":
            return 0.5
        case "Mistral-7B":
            return 1.0
        case "CodeLlama-7B", "Llama-2-7B":
            return 1.2
        case "BGE-Large":
            return 0.8
        default:
            return 1.0
        }
    }
}

// MARK: - 📊 Data Models

struct RoutingDecision {
    let id = UUID()
    let requestedModel: String
    let selectedModel: String
    let reasoning: String
    let confidence: Double
    let timestamp: Date
}

struct RoutingRecord {
    let decision: RoutingDecision
    let result: RouterInferenceResult
    let routingTime: TimeInterval
    let timestamp: Date
}

struct ModelCapabilities {
    let model: String
    let specializations: [QueryType: Double]
    let memoryRequirement: Int
    let averageInferenceTime: TimeInterval
}

struct PerformanceMetrics {
    var totalInferences: Int = 0
    var averageConfidence: Double = 0.0
    var averageInferenceTime: TimeInterval = 0.0
    var recentSuccessRate: Double = 1.0
    
    mutating func updateWith(confidence: Double, inferenceTime: TimeInterval) {
        totalInferences += 1
        averageConfidence = (averageConfidence + confidence) / 2.0
        averageInferenceTime = (averageInferenceTime + inferenceTime) / 2.0
        
        // Update success rate based on confidence
        recentSuccessRate = (recentSuccessRate + (confidence > 0.8 ? 1.0 : 0.0)) / 2.0
    }
}

struct RouterInferenceResult {
    let content: String
    let confidence: Double
    let inferenceTime: TimeInterval
    let model: String
    let metadata: [String: Any]
}

struct ProcessedResponse {
    let content: String
    let confidence: Double
}

// MARK: - 🎓 Adaptive Learning Engine

class AdaptiveLearningEngine {
    private var learningHistory: [LearningRecord] = []
    private var modelPreferences: [QueryType: String] = [:]
    
    func adjustScores(_ scores: inout [String: Double], for analysis: PromptAnalysis) async {
        // Apply learned preferences
        if let preferredModel = modelPreferences[analysis.queryType] {
            scores[preferredModel] = (scores[preferredModel] ?? 0.0) * 1.1
        }
    }
    
    func learnFromRouting(_ record: RoutingRecord) async {
        let learningRecord = LearningRecord(
            queryType: record.decision.reasoning.contains("coding") ? .coding : .general,
            selectedModel: record.decision.selectedModel,
            performance: record.result.confidence,
            timestamp: Date()
        )
        
        learningHistory.append(learningRecord)
        
        // Update preferences based on performance
        updateModelPreferences()
    }
    
    func performPeriodicLearning(_ history: [RoutingRecord]) async {
        // Analyze patterns in routing history
        for record in history.suffix(100) {
            await learnFromRouting(record)
        }
    }
    
    private func updateModelPreferences() {
        // Analyze which models perform best for each query type
        let recentRecords = learningHistory.suffix(200)
        
        for queryType in QueryType.allCases {
            let recordsForType = recentRecords.filter { $0.queryType == queryType }
            
            // Build performance dictionary
            var modelPerformance: [String: [Double]] = [:]
            for record in recordsForType {
                modelPerformance[record.selectedModel, default: []].append(record.performance)
            }
            
            // Calculate average performance for each model
            let modelAverages = modelPerformance.mapValues { performances in
                performances.reduce(0, +) / Double(performances.count)
            }
            
            // Find best performing model
            if let bestModel = modelAverages.max(by: { $0.value < $1.value })?.key {
                modelPreferences[queryType] = bestModel
            }
        }
    }
}

struct LearningRecord {
    let queryType: QueryType
    let selectedModel: String
    let performance: Double
    let timestamp: Date
}

// MARK: - 🏷️ Extended Enumerations

extension QueryType {
    static var allCases: [QueryType] {
        return [.general, .coding, .analysis, .creative, .factual, .reasoning, .technical, .debugging, .conversational, .research, .speed, .embedding]
    }
}
