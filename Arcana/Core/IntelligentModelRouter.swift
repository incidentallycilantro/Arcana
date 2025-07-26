//
// IntelligentModelRouter.swift
// Arcana - Revolutionary AI Model Routing Engine
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
// DEPENDENCIES: PropietaryPRISMCore.swift, UnifiedTypes.swift, WorkspaceManager.swift

import Foundation
import OSLog

@MainActor
class IntelligentModelRouter: ObservableObject {
    
    // MARK: - Singleton
    static let shared = IntelligentModelRouter()
    
    // MARK: - Published Properties
    @Published var currentModel: String = "Mistral-7B"
    @Published var isRouting: Bool = false
    @Published var routingConfidence: Double = 0.0
    @Published var modelPerformanceScores: [String: Double] = [:]
    @Published var isAdaptiveLearning: Bool = true
    
    // MARK: - Core Components
    private let proprietaryCore = PropietaryPRISMCore.shared
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ModelRouter")
    private let adaptiveLearningEngine = AdaptiveLearningEngine()
    
    // MARK: - Routing Intelligence
    private var modelSpecializations: [String: [QueryType: Double]] = [:]
    private var modelCapabilities: [String: ModelCapabilities] = [:]
    private var complexityAdjustments: [String: [ContextComplexity: Double]] = [:]
    private var dynamicPerformanceMetrics: [String: PerformanceMetrics] = [:]
    private var routingHistory: [RoutingRecord] = []
    
    // MARK: - Initialization
    
    private init() {
        setupModelSpecializations()
        setupModelCapabilities()
        setupComplexityAdjustments()
        startAdaptiveLearning()
        
        logger.info("🧠 IntelligentModelRouter initialized with revolutionary routing capabilities")
    }
    
    // MARK: - Core Routing Engine
    
    func routeRequest(
        prompt: String,
        requestedModel: String? = nil,
        context: ConversationContext? = nil,
        workspaceType: WorkspaceManager.WorkspaceType = .general
    ) async -> RouterInferenceResult {
        
        let routingStartTime = Date()
        isRouting = true
        
        do {
            // 1. Analyze prompt characteristics
            let analysis = await analyzePrompt(prompt, workspaceType: workspaceType)
            
            // 2. Determine optimal model
            let optimalModel = requestedModel ?? await selectOptimalModel(
                for: analysis,
                requestedModel: requestedModel ?? "auto"
            )
            
            // 3. Create routing decision
            let routingDecision = RoutingDecision(
                requestedModel: requestedModel ?? "auto",
                selectedModel: optimalModel,
                reasoning: generateRoutingReasoning(analysis, selected: optimalModel),
                confidence: calculateRoutingConfidence(analysis, selected: optimalModel),
                timestamp: Date()
            )
            
            // 4. Execute intelligent inference
            let result = await executeIntelligentInference(
                model: optimalModel,
                prompt: prompt,
                context: context ?? ConversationContext(),
                routingDecision: routingDecision
            )
            
            // 5. Update performance tracking
            await recordRoutingPerformance(
                decision: routingDecision,
                result: result,
                routingTime: Date().timeIntervalSince(routingStartTime)
            )
            
            // 6. Update UI state
            currentModel = optimalModel
            routingConfidence = routingDecision.confidence
            isRouting = false
            
            logger.info("✅ Request routed to \(optimalModel) with confidence \(routingDecision.confidence)")
            
            return result
            
        } catch {
            logger.error("❌ Routing failed: \(error.localizedDescription)")
            isRouting = false
            
            // Fallback to default model
            let fallbackResult = await executeFallbackInference(prompt: prompt, error: error)
            return fallbackResult
        }
    }
    
    // MARK: - Prompt Analysis Engine
    
    private func analyzePrompt(_ prompt: String, workspaceType: WorkspaceManager.WorkspaceType) async -> PromptAnalysis {
        let promptLength = prompt.count
        let complexity = determineComplexity(prompt)
        let queryType = await classifyQueryType(prompt)
        let requiredCapabilities = determineRequiredCapabilities(queryType)
        
        return PromptAnalysis(
            queryType: queryType,
            complexity: complexity,
            workspaceType: workspaceType,
            requiredCapabilities: requiredCapabilities,
            promptLength: promptLength,
            isTimeConstrained: false,
            prioritizeAccuracy: complexity != .low
        )
    }
    
    private func classifyQueryType(_ prompt: String) async -> QueryType {
        let promptLower = prompt.lowercased()
        
        // Code detection
        if promptLower.contains("code") || promptLower.contains("function") ||
           promptLower.contains("class") || promptLower.contains("variable") ||
           prompt.contains("{") || prompt.contains("def ") || prompt.contains("import ") {
            return .coding
        }
        
        // Creative writing detection
        if promptLower.contains("story") || promptLower.contains("creative") ||
           promptLower.contains("write") || promptLower.contains("poem") ||
           promptLower.contains("character") || promptLower.contains("narrative") {
            return .creative
        }
        
        // Analysis detection
        if promptLower.contains("analyze") || promptLower.contains("research") ||
           promptLower.contains("study") || promptLower.contains("examine") ||
           promptLower.contains("investigate") || promptLower.contains("compare") {
            return .analysis
        }
        
        // Factual questions
        if promptLower.contains("what is") || promptLower.contains("who is") ||
           promptLower.contains("when did") || promptLower.contains("where is") ||
           promptLower.contains("how many") || promptLower.contains("define") {
            return .factual
        }
        
        // Technical questions
        if promptLower.contains("how to") || promptLower.contains("explain") ||
           promptLower.contains("technical") || promptLower.contains("engineering") {
            return .technical
        }
        
        // Default to general reasoning
        return .reasoning
    }
    
    private func determineComplexity(_ prompt: String) -> ContextComplexity {
        let promptLength = prompt.count
        let sentenceCount = prompt.components(separatedBy: ".").count
        let complexWords = prompt.components(separatedBy: .whitespaces)
            .filter { $0.count > 8 }.count
        
        if promptLength > 500 || sentenceCount > 5 || complexWords > 10 {
            return .high
        } else if promptLength > 200 || sentenceCount > 2 || complexWords > 3 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Model Selection Engine
    
    private func selectOptimalModel(
        for analysis: PromptAnalysis,
        requestedModel: String
    ) async -> String {
        
        var modelScores: [String: Double] = [:]
        
        // 1. Calculate base compatibility scores
        for model in modelSpecializations.keys {
            let baseScore = modelSpecializations[model]?[analysis.queryType] ?? 0.5
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
    
    // MARK: - Intelligent Inference Execution
    
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
            
            // 4. Post-process response
            let processedResponse = await postProcessResponse(
                response.content,
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
                    "routing_decision": routingDecision,
                    "optimized_prompt": optimizedPrompt != prompt,
                    "model_parameters": modelParams
                ]
            )
            
        } catch {
            logger.error("💥 Inference execution failed: \(error.localizedDescription)")
            
            // Return fallback result
            return RouterInferenceResult(
                content: "I apologize, but I'm having difficulty processing your request right now. Please try again.",
                confidence: 0.1,
                inferenceTime: Date().timeIntervalSince(inferenceStartTime),
                model: model,
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    // MARK: - Optimization & Processing
    
    private func postProcessResponse(
        _ response: String,
        model: String,
        originalPrompt: String
    ) async -> ProcessedResponse {
        
        var processedContent = response
        var confidence = 0.8
        
        // Model-specific post-processing
        switch model {
        case "CodeLlama-7B":
            // Enhance code formatting
            if originalPrompt.lowercased().contains("code") {
                processedContent = enhanceCodeFormatting(processedContent)
                confidence = 0.9
            }
            
        case "BGE-Large":
            // Enhance factual accuracy confidence
            if originalPrompt.lowercased().contains("fact") || originalPrompt.lowercased().contains("research") {
                confidence = 0.95
            }
            
        case "Phi-2":
            // Enhance conciseness
            if processedContent.count > 300 {
                confidence = 0.7 // Lower confidence for long responses from concise model
            }
            
        default:
            break
        }
        
        return ProcessedResponse(content: processedContent, confidence: confidence)
    }
    
    // MARK: - Performance Tracking
    
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
    
    // MARK: - Adaptive Learning
    
    private func startAdaptiveLearning() {
        Task.detached(priority: .background) {
            while !Task.isCancelled {
                // Learn from routing history every 60 seconds
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self.adaptiveLearningEngine.performPeriodicLearning(self.routingHistory)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // FIXED: Removed memoryRequirement parameter that was causing compilation error
    private func setupModelCapabilities() {
        // Initialize model capabilities database
        for model in modelSpecializations.keys {
            modelCapabilities[model] = ModelCapabilities(
                modelName: model,
                specialties: Array(modelSpecializations[model]?.keys.map { "\($0)" } ?? []),
                averageConfidence: 0.8,
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
    
    private func calculateComplexityAdjustment(_ complexity: ContextComplexity, for model: String) -> Double {
        return complexityAdjustments[model]?[complexity] ?? 0.8
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
            
        case "Phi-2":
            params["temperature"] = 0.8
            params["top_p"] = 0.85
            params["max_tokens"] = 512
            
        case "BGE-Large":
            params["temperature"] = 0.4
            params["top_p"] = 0.9
            params["max_tokens"] = 1536
            
        default:
            params["temperature"] = 0.7
            params["top_p"] = 0.9
            params["max_tokens"] = 1024
        }
        
        return params
    }
    
    private func enhanceCodeFormatting(_ content: String) -> String {
        // Basic code formatting enhancement
        var enhanced = content
        
        // Add syntax highlighting hints if missing
        if enhanced.contains("```") && !enhanced.contains("```swift") && !enhanced.contains("```python") {
            enhanced = enhanced.replacingOccurrences(of: "```", with: "```swift")
        }
        
        return enhanced
    }
    
    private func executeFallbackInference(prompt: String, error: Error) async -> RouterInferenceResult {
        // Fallback to simplest available model
        let fallbackModel = "Phi-2"
        
        do {
            let fallbackResponse = try await proprietaryCore.generateResponse(
                prompt: prompt,
                modelName: fallbackModel,
                context: ConversationContext(),
                parameters: InferenceParameters(maxTokens: 512, temperature: 0.7, topP: 0.9)
            )
            
            return RouterInferenceResult(
                content: fallbackResponse.content,
                confidence: 0.6,
                inferenceTime: 1.0,
                model: fallbackModel,
                metadata: ["fallback": true, "original_error": error.localizedDescription]
            )
        } catch {
            return RouterInferenceResult(
                content: "I'm experiencing technical difficulties. Please try again in a moment.",
                confidence: 0.1,
                inferenceTime: 0.1,
                model: "fallback",
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupModelSpecializations() {
        modelSpecializations = [
            "Mistral-7B": [
                .general: 0.9, .reasoning: 0.85, .conversational: 0.9,
                .analysis: 0.8, .creative: 0.75, .factual: 0.8
            ],
            "CodeLlama-7B": [
                .coding: 0.95, .technical: 0.9, .debugging: 0.9,
                .analysis: 0.7, .general: 0.6
            ],
            "Phi-2": [
                .speed: 0.95, .general: 0.8, .conversational: 0.85,
                .factual: 0.7, .reasoning: 0.75
            ],
            "BGE-Large": [
                .factual: 0.95, .research: 0.9, .analysis: 0.85,
                .embedding: 0.95, .general: 0.7
            ],
            "Llama-2-7B": [
                .creative: 0.9, .conversational: 0.85, .general: 0.8,
                .reasoning: 0.8, .analysis: 0.75
            ]
        ]
    }
    
    private func setupComplexityAdjustments() {
        complexityAdjustments = [
            "Mistral-7B": [.low: 1.0, .medium: 0.9, .high: 0.85],
            "CodeLlama-7B": [.low: 0.8, .medium: 1.0, .high: 1.1],
            "Phi-2": [.low: 1.2, .medium: 0.9, .high: 0.6],
            "BGE-Large": [.low: 0.9, .medium: 1.0, .high: 1.1],
            "Llama-2-7B": [.low: 1.0, .medium: 0.95, .high: 0.9]
        ]
    }
}

// MARK: - Data Models

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

// FIXED: Removed memoryRequirement property that was causing compilation error
struct ModelCapabilities {
    let modelName: String
    let specialties: [String]
    let averageConfidence: Double
    let averageInferenceTime: TimeInterval
    
    init(
        modelName: String,
        specialties: [String],
        averageConfidence: Double,
        averageInferenceTime: TimeInterval
    ) {
        self.modelName = modelName
        self.specialties = specialties
        self.averageConfidence = averageConfidence
        self.averageInferenceTime = averageInferenceTime
    }
}

// MARK: - Supporting Types

struct PromptAnalysis {
    let queryType: QueryType
    let complexity: ContextComplexity
    let workspaceType: WorkspaceManager.WorkspaceType
    let requiredCapabilities: [ModelCapability]
    let promptLength: Int
    let isTimeConstrained: Bool
    let prioritizeAccuracy: Bool
}

struct ConversationContext {
    let messages: [String] = []
    let workspaceType: WorkspaceManager.WorkspaceType = .general
    let userPreferences: [String: Any] = [:]
}

struct InferenceParameters {
    let maxTokens: Int
    let temperature: Double
    let topP: Double
}

enum QueryType {
    case general, coding, analysis, creative, factual, reasoning, technical, debugging, conversational, research, speed, embedding
}

enum ContextComplexity {
    case low, medium, high
}

enum ModelCapability {
    case codeGeneration, syntaxAnalysis, logicalReasoning, dataAnalysis
    case creativeWriting, storytelling, factualAccuracy, knowledgeRetrieval, generalReasoning
}

// MARK: - Adaptive Learning Engine

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
        
        for queryType in [QueryType.coding, .creative, .analysis, .factual, .general] {
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
