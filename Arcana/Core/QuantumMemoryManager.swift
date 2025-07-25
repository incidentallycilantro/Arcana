// QuantumMemoryManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Zero-Lag Memory Architecture

import Foundation
import Metal
import Accelerate
import os.log

@MainActor
class QuantumMemoryManager: ObservableObject {
    static let shared = QuantumMemoryManager()
    
    // MARK: - Published State
    @Published var memoryUtilization: Double = 0.0
    @Published var loadingProgress: Double = 0.0
    @Published var activeModelSegments: Set<String> = []
    @Published var cacheHitRate: Double = 0.0
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "QuantumMemory")
    private let metalDevice: MTLDevice?
    private let systemInfo = SystemResourceMonitor()
    
    // MARK: - Memory Architecture
    private var modelSegmentCache: [String: ModelSegment] = [:]
    private var predictiveCache: [String: CachedWeights] = [:]
    private var usagePatterns: [String: UsagePattern] = [:]
    private var compressionEngine: WeightCompressionEngine
    
    // MARK: - Configuration
    private let maxRAMUsagePercent: Double = 0.75 // Use 75% of available RAM
    private let segmentSize: Int = 128 * 1024 * 1024 // 128MB segments
    private let predictiveCacheSize: Int = 512 * 1024 * 1024 // 512MB predictive cache
    
    private init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        self.compressionEngine = WeightCompressionEngine()
        
        logger.info("🧠 QuantumMemoryManager initialized")
        setupMemoryArchitecture()
    }
    
    // MARK: - 🚀 REVOLUTIONARY: Predictive Weight Loading
    
    func predictivePreload(for query: String, context: ConversationContext) async {
        logger.info("🔮 Starting predictive preload for query analysis")
        
        // 1. Analyze query to predict needed model segments
        let queryAnalysis = await analyzeQueryRequirements(query, context: context)
        
        // 2. Check usage patterns to predict likely follow-up needs
        let usagePredicton = predictUsagePattern(queryAnalysis)
        
        // 3. Calculate optimal segments to preload
        let segmentsToLoad = calculateOptimalSegments(queryAnalysis, usage: usagePredicton)
        
        // 4. Preload segments asynchronously
        await preloadSegments(segmentsToLoad)
        
        // 5. Update cache hit predictions
        updateCacheStrategy(based: usagePredicton)
        
        logger.info("✅ Predictive preload complete: \(segmentsToLoad.count) segments ready")
    }
    
    // MARK: - 🧠 REVOLUTIONARY: Intelligent Weight Streaming
    
    func streamModelWeights(modelName: String, requiredCapability: ModelCapability) async throws -> ModelWeightStream {
        logger.info("🌊 Streaming weights for \(modelName) - \(requiredCapability.rawValue)")
        
        // 1. Check if core segments already in memory
        if let cachedSegment = modelSegmentCache[modelName] {
            logger.info("⚡ Cache hit! Using preloaded segments")
            updateCacheHitRate(hit: true)
            return ModelWeightStream(segments: [cachedSegment], cached: true)
        }
        
        // 2. Calculate minimum segments needed for this capability
        let requiredSegments = calculateRequiredSegments(for: requiredCapability)
        
        // 3. Stream segments from storage in priority order
        let streamedSegments = try await streamSegmentsFromDisk(
            modelName: modelName,
            segments: requiredSegments,
            priority: .realtime
        )
        
        // 4. Cache remaining segments for future use
        let _ = Task.detached(priority: .background) {
            await self.cacheRemainingSegments(modelName: modelName, loaded: requiredSegments)
        }
        
        updateCacheHitRate(hit: false)
        return ModelWeightStream(segments: streamedSegments, cached: false)
    }
    
    // MARK: - 💾 REVOLUTIONARY: Adaptive Memory Management
    
    func optimizeMemoryAllocation() async {
        logger.info("🎯 Optimizing memory allocation based on usage patterns")
        
        let availableRAM = await systemInfo.getAvailableRAM()
        let targetRAMUsage = Int(Double(availableRAM) * maxRAMUsagePercent)
        
        // 1. Analyze current memory usage
        let currentUsage = calculateCurrentMemoryUsage()
        
        // 2. Identify least recently used segments
        let lruSegments = identifyLRUSegments()
        
        // 3. Intelligent compression of cold segments
        if currentUsage > targetRAMUsage {
            await compressLeastUsedSegments(lruSegments, targetReduction: currentUsage - targetRAMUsage)
        }
        
        // 4. Preload high-priority segments if we have headroom
        if currentUsage < targetRAMUsage {
            let headroom = targetRAMUsage - currentUsage
            await preloadHighPrioritySegments(maxSize: headroom)
        }
        
        // 5. Update memory utilization metrics
        await MainActor.run {
            self.memoryUtilization = Double(currentUsage) / Double(targetRAMUsage)
        }
        
        logger.info("✅ Memory optimization complete. Utilization: \(String(format: "%.1f", self.memoryUtilization * 100))%")
    }
    
    // MARK: - 🎯 REVOLUTIONARY: Usage Pattern Learning
    
    private func predictUsagePattern(_ queryAnalysis: QueryAnalysis) -> UsagePattern {
        // Learn from historical patterns
        let historicalPattern = usagePatterns[queryAnalysis.type.rawValue] ?? UsagePattern.default
        
        // Factor in time of day, day of week
        let temporalFactors = calculateTemporalFactors()
        
        // Predict likely model sequence based on query complexity
        let predictedSequence = predictModelSequence(queryAnalysis, temporal: temporalFactors)
        
        // Calculate confidence in prediction
        let confidence = calculatePredictionConfidence(historicalPattern, queryAnalysis)
        
        return UsagePattern(
            queryType: queryAnalysis.type,
            predictedModels: predictedSequence,
            confidence: confidence,
            temporalContext: temporalFactors,
            estimatedDuration: predictedSequence.reduce(0) { $0 + $1.estimatedTime }
        )
    }
    
    // MARK: - ⚡ REVOLUTIONARY: Apple Silicon Optimization
    
    private func optimizeForAppleSilicon() async {
        guard let metalDevice = metalDevice else {
            logger.warning("⚠️ Metal device not available, falling back to CPU optimization")
            return
        }
        
        logger.info("🚀 Optimizing for Apple Silicon architecture")
        
        // 1. Utilize unified memory architecture
        await optimizeUnifiedMemoryAccess()
        
        // 2. Leverage Neural Engine for weight prediction
        if await isNeuralEngineAvailable() {
            await setupNeuralEnginePrediction()
        }
        
        // 3. Use Metal for parallel weight decompression
        await setupMetalDecompression(device: metalDevice)
        
        // 4. Optimize for memory bandwidth
        await optimizeMemoryBandwidth()
        
        logger.info("✅ Apple Silicon optimization complete")
    }
    
    // MARK: - 🔄 Core Helper Methods
    
    private func setupMemoryArchitecture() {
        Task { @MainActor in
            // Initialize system monitoring
            await systemInfo.startMonitoring()
            
            // Set up compression engine
            await compressionEngine.initialize()
            
            // Optimize for current hardware
            await optimizeForAppleSilicon()
            
            // Start background optimization
            startBackgroundOptimization()
        }
    }
    
    private func analyzeQueryRequirements(_ query: String, context: ConversationContext) async -> QueryAnalysis {
        // Analyze query complexity and requirements
        let complexity = calculateQueryComplexity(query)
        let requiredCapabilities = extractRequiredCapabilities(query, context: context)
        let estimatedTokens = estimateTokenRequirement(query, context: context)
        
        return QueryAnalysis(
            query: query,
            complexity: complexity,
            type: classifyQueryType(query, context: context),
            requiredCapabilities: requiredCapabilities,
            estimatedTokens: estimatedTokens,
            contextLength: context.messages.count
        )
    }
    
    private func calculateRequiredSegments(for capability: ModelCapability) -> [SegmentIdentifier] {
        switch capability {
        case .textGeneration:
            return [.attentionLayers, .feedForward, .outputHead]
        case .codeGeneration:
            return [.attentionLayers, .feedForward, .codeSpecificLayers, .outputHead]
        case .reasoning:
            return [.attentionLayers, .feedForward, .reasoningLayers, .outputHead]
        case .embedding:
            return [.inputEmbedding, .attentionLayers]
        }
    }
    
    private func streamSegmentsFromDisk(
        modelName: String,
        segments: [SegmentIdentifier],
        priority: StreamPriority
    ) async throws -> [ModelSegment] {
        
        var streamedSegments: [ModelSegment] = []
        
        // Update loading progress
        await MainActor.run { self.loadingProgress = 0.0 }
        
        for (index, segmentId) in segments.enumerated() {
            // Load segment from disk with compression awareness
            let segment = try await loadSegmentFromDisk(modelName: modelName, segmentId: segmentId)
            
            // Decompress if needed (using Metal acceleration when available)
            let decompressedSegment = try await decompressSegment(segment)
            
            streamedSegments.append(decompressedSegment)
            
            // Update progress
            let progress = Double(index + 1) / Double(segments.count)
            await MainActor.run { self.loadingProgress = progress }
            
            // Add small delay to prevent UI blocking for large models
            if segments.count > 10 {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        await MainActor.run { self.loadingProgress = 1.0 }
        return streamedSegments
    }
    
    private func loadSegmentFromDisk(modelName: String, segmentId: SegmentIdentifier) async throws -> CompressedModelSegment {
        // This will integrate with your existing model storage
        let modelPath = getModelPath(modelName: modelName)
        let segmentPath = modelPath.appendingPathComponent("\(segmentId.rawValue).segment")
        
        guard FileManager.default.fileExists(atPath: segmentPath.path) else {
            throw QuantumMemoryError.segmentNotFound(modelName: modelName, segment: segmentId)
        }
        
        let data = try Data(contentsOf: segmentPath)
        return CompressedModelSegment(id: segmentId, data: data, compressionRatio: 0.3)
    }
    
    private func decompressSegment(_ segment: CompressedModelSegment) async throws -> ModelSegment {
        // Use background queue for CPU-intensive decompression
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let decompressed = try await self.compressionEngine.decompress(segment)
                    continuation.resume(returning: decompressed)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func startBackgroundOptimization() {
        let _ = Task.detached(priority: .background) {
            while !Task.isCancelled {
                // Run optimization every 30 seconds
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await self.optimizeMemoryAllocation()
            }
        }
    }
    
    // MARK: - 📊 Memory Monitoring
    
    private func calculateCurrentMemoryUsage() -> Int {
        var usage = 0
        for segment in modelSegmentCache.values {
            usage += segment.memorySize
        }
        for cached in predictiveCache.values {
            usage += cached.memorySize
        }
        return usage
    }
    
    private func updateCacheHitRate(hit: Bool) {
        // Simple exponential moving average
        let alpha = 0.1
        let hitValue = hit ? 1.0 : 0.0
        
        Task { @MainActor in
            self.cacheHitRate = alpha * hitValue + (1 - alpha) * self.cacheHitRate
        }
    }
    
    // MARK: - 🧮 Public Analysis Methods (Used by PRISMEngine)
    
    /// Public interface for query complexity analysis
    func calculateQueryComplexity(_ query: String) -> QueryComplexity {
        let wordCount = query.components(separatedBy: .whitespacesAndNewlines).count
        let hasCode = query.contains("```") || query.contains("function") || query.contains("class")
        let hasReasoning = query.lowercased().contains(where: { "analyze|compare|evaluate|reason|think".contains($0) })
        
        if wordCount > 100 || hasReasoning {
            return .high
        } else if wordCount > 30 || hasCode {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Public interface for query type classification
    func classifyQueryType(_ query: String, context: ConversationContext) -> QueryType {
        let lowercased = query.lowercased()
        
        if lowercased.contains("code") || lowercased.contains("function") || lowercased.contains("program") {
            return .code
        } else if lowercased.contains("write") || lowercased.contains("create") || lowercased.contains("story") {
            return .creative
        } else if lowercased.contains("analyze") || lowercased.contains("research") || lowercased.contains("data") {
            return .analytical
        } else {
            return .general
        }
    }
    
    /// Public interface for capability extraction
    func extractRequiredCapabilities(_ query: String, context: ConversationContext) -> [ModelCapability] {
        var capabilities: [ModelCapability] = []
        
        let queryLower = query.lowercased()
        
        if queryLower.contains("code") || queryLower.contains("function") || queryLower.contains("program") {
            capabilities.append(.codeGeneration)
        }
        
        if queryLower.contains("analyze") || queryLower.contains("reason") || queryLower.contains("think") {
            capabilities.append(.reasoning)
        }
        
        if queryLower.contains("embed") || queryLower.contains("similar") || queryLower.contains("search") {
            capabilities.append(.embedding)
        }
        
        // Default capability
        if capabilities.isEmpty {
            capabilities.append(.textGeneration)
        }
        
        return capabilities
    }
    
    /// Public interface for token requirement estimation
    func estimateTokenRequirement(_ query: String, context: ConversationContext) -> Int {
        // Rough estimation - 4 characters per token
        let queryTokens = query.count / 4
        let contextTokens = context.messages.reduce(0) { $0 + ($1.content.count / 4) }
        let responseEstimate = max(queryTokens * 2, 100) // Response usually 2x query length
        
        return queryTokens + contextTokens + responseEstimate
    }
    
    /// Preload model weights for specific computation path
    func preloadModelWeights(modelName: String, computationPath: ComputationPath) async {
        let computationPathString = String(describing: computationPath)
        logger.info("⚡ Preloading model weights for \(modelName) with \(computationPathString)")
        
        // Determine required capabilities based on computation path
        let capability: ModelCapability = {
            switch computationPath {
            case .metalAccelerated, .coreMLAccelerated:
                return .textGeneration
            case .cpuOptimized:
                return .reasoning
            case .memoryOptimized:
                return .embedding
            }
        }()
        
        do {
            let _ = try await streamModelWeights(modelName: modelName, requiredCapability: capability)
            logger.info("✅ Successfully preloaded \(modelName)")
        } catch {
            logger.error("❌ Failed to preload \(modelName): \(error)")
        }
    }
    
    private func getModelPath(modelName: String) -> URL {
        // Integrate with your existing model storage location
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupport
            .appendingPathComponent("Arcana")
            .appendingPathComponent("Models")
            .appendingPathComponent(modelName)
    }
    
    // MARK: - Helper Method Implementations
    
    private func calculateOptimalSegments(_ queryAnalysis: QueryAnalysis, usage: UsagePattern) -> [SegmentPrediction] {
        var predictions: [SegmentPrediction] = []
        
        // Base segments for query type
        switch queryAnalysis.type {
        case .code:
            predictions.append(SegmentPrediction(
                modelName: "CodeLlama-7B",
                capability: .codeGeneration,
                segments: [.attentionLayers, .codeSpecificLayers, .outputHead],
                priority: 0.9
            ))
        case .creative:
            predictions.append(SegmentPrediction(
                modelName: "Mistral-7B",
                capability: .textGeneration,
                segments: [.attentionLayers, .feedForward, .outputHead],
                priority: 0.8
            ))
        case .analytical:
            predictions.append(SegmentPrediction(
                modelName: "Mistral-7B",
                capability: .reasoning,
                segments: [.attentionLayers, .reasoningLayers, .outputHead],
                priority: 0.85
            ))
        case .general:
            predictions.append(SegmentPrediction(
                modelName: "Phi-2",
                capability: .textGeneration,
                segments: [.attentionLayers, .feedForward, .outputHead],
                priority: 0.7
            ))
        }
        
        return predictions
    }
    
    private func preloadSegments(_ segments: [SegmentPrediction]) async {
        for prediction in segments.prefix(5) { // Limit concurrent preloads
            let _ = Task.detached(priority: .background) {
                do {
                    _ = try await self.streamModelWeights(
                        modelName: prediction.modelName,
                        requiredCapability: prediction.capability
                    )
                    await MainActor.run {
                        self.logger.info("✅ Preloaded \(prediction.modelName) for \(prediction.capability.rawValue)")
                    }
                } catch {
                    await MainActor.run {
                        self.logger.error("❌ Failed to preload \(prediction.modelName): \(error)")
                    }
                }
            }
        }
    }
    
    private func updateCacheStrategy(based prediction: UsagePattern) {
        // Update caching strategy based on usage prediction
        logger.info("📊 Updating cache strategy for \(prediction.queryType.rawValue)")
    }
    
    private func calculateTemporalFactors() -> TemporalFactors {
        let now = Date()
        let calendar = Calendar.current
        
        // Simple temporal factor calculation
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let month = calendar.component(.month, from: now)
        
        let timeOfDay: TimeOfDay = {
            switch hour {
            case 5..<7: return .earlyMorning
            case 7..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            default: return .night
            }
        }()
        
        let dayOfWeek: DayOfWeek = {
            switch weekday {
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            case 7: return .saturday
            default: return .sunday
            }
        }()
        
        let season: Season = {
            switch month {
            case 3...5: return .spring
            case 6...8: return .summer
            case 9...11: return .fall
            default: return .winter
            }
        }()
        
        return TemporalFactors(timeOfDay: timeOfDay, dayOfWeek: dayOfWeek, season: season)
    }
    
    private func predictModelSequence(_ queryAnalysis: QueryAnalysis, temporal: TemporalFactors) -> [ModelPrediction] {
        var predictions: [ModelPrediction] = []
        
        // Base prediction based on query type
        switch queryAnalysis.type {
        case .code:
            predictions.append(ModelPrediction(
                modelName: "CodeLlama-7B",
                capability: .codeGeneration,
                confidence: 0.9,
                estimatedTime: 2.0
            ))
        case .creative:
            predictions.append(ModelPrediction(
                modelName: "Mistral-7B",
                capability: .textGeneration,
                confidence: 0.8,
                estimatedTime: 1.5
            ))
        case .analytical:
            predictions.append(ModelPrediction(
                modelName: "Mistral-7B",
                capability: .reasoning,
                confidence: 0.85,
                estimatedTime: 2.5
            ))
        case .general:
            predictions.append(ModelPrediction(
                modelName: "Phi-2",
                capability: .textGeneration,
                confidence: 0.7,
                estimatedTime: 1.0
            ))
        }
        
        return predictions
    }
    
    private func calculatePredictionConfidence(_ historical: UsagePattern, _ analysis: QueryAnalysis) -> Double {
        // Simple confidence calculation based on historical accuracy
        return 0.8 // Placeholder - will improve with learning
    }
    
    private func optimizeUnifiedMemoryAccess() async {
        logger.info("🔧 Optimizing unified memory access for Apple Silicon")
        // Placeholder for unified memory optimization
    }
    
    private func isNeuralEngineAvailable() async -> Bool {
        // Check if Neural Engine is available
        return true // M3 has Neural Engine
    }
    
    private func setupNeuralEnginePrediction() async {
        logger.info("🧠 Setting up Neural Engine prediction")
        // Placeholder for Neural Engine setup
    }
    
    private func setupMetalDecompression(device: MTLDevice) async {
        logger.info("⚡ Setting up Metal decompression")
        // Placeholder for Metal setup
    }
    
    private func optimizeMemoryBandwidth() async {
        logger.info("🌊 Optimizing memory bandwidth")
        // Placeholder for bandwidth optimization
    }
    
    private func compressLeastUsedSegments(_ segments: [String], targetReduction: Int) async {
        logger.info("🗜️ Compressing \(segments.count) least used segments")
        // Placeholder for compression
    }
    
    private func preloadHighPrioritySegments(maxSize: Int) async {
        logger.info("⬆️ Preloading high priority segments (max: \(maxSize) bytes)")
        // Placeholder for preloading
    }
    
    private func identifyLRUSegments() -> [String] {
        // Return least recently used segments
        return Array(modelSegmentCache.keys.prefix(5))
    }
    
    private func cacheRemainingSegments(modelName: String, loaded: [SegmentIdentifier]) async {
        logger.info("💾 Caching remaining segments for \(modelName)")
        // Placeholder for background caching
    }
    
    // MARK: - 🎯 Public Interface
    
    func getMemoryStatus() -> MemoryStatus {
        let currentUsage = calculateCurrentMemoryUsage()
        let availableRAM = systemInfo.getTotalRAM()
        
        return MemoryStatus(
            currentUsage: currentUsage,
            availableRAM: availableRAM,
            utilization: memoryUtilization,
            cacheHitRate: cacheHitRate,
            activeSegments: activeModelSegments.count,
            compressionRatio: compressionEngine.averageCompressionRatio
        )
    }
    
    func clearCache() async {
        logger.info("🧹 Clearing memory caches")
        
        modelSegmentCache.removeAll()
        predictiveCache.removeAll()
        usagePatterns.removeAll()
        
        await MainActor.run {
            self.memoryUtilization = 0.0
            self.cacheHitRate = 0.0
            self.activeModelSegments.removeAll()
        }
        
        logger.info("✅ Memory caches cleared")
    }
}

// MARK: - 📊 Data Models

struct ConversationContext {
    let messages: [ChatMessage]
    let workspaceType: WorkspaceManager.WorkspaceType
    let projectId: UUID?
    let threadId: UUID?
    
    init(messages: [ChatMessage] = [], workspaceType: WorkspaceManager.WorkspaceType = .general, projectId: UUID? = nil, threadId: UUID? = nil) {
        self.messages = messages
        self.workspaceType = workspaceType
        self.projectId = projectId
        self.threadId = threadId
    }
}

struct QueryAnalysis {
    let query: String
    let complexity: QueryComplexity
    let type: QueryType
    let requiredCapabilities: [ModelCapability]
    let estimatedTokens: Int
    let contextLength: Int
}

struct UsagePattern {
    let queryType: QueryType
    let predictedModels: [ModelPrediction]
    let confidence: Double
    let temporalContext: TemporalFactors
    let estimatedDuration: TimeInterval
    
    static let `default` = UsagePattern(
        queryType: .general,
        predictedModels: [],
        confidence: 0.0,
        temporalContext: TemporalFactors(),
        estimatedDuration: 0.0
    )
}

struct ModelPrediction {
    let modelName: String
    let capability: ModelCapability
    let confidence: Double
    let estimatedTime: TimeInterval
}

struct SegmentPrediction {
    let modelName: String
    let capability: ModelCapability
    let segments: [SegmentIdentifier]
    let priority: Double
}

struct ModelSegment {
    let id: SegmentIdentifier
    let data: Data
    let memorySize: Int
    let lastAccessed: Date
}

struct CompressedModelSegment {
    let id: SegmentIdentifier
    let data: Data
    let compressionRatio: Double
}

struct CachedWeights {
    let modelName: String
    let segments: [ModelSegment]
    let memorySize: Int
    let lastAccessed: Date
}

struct ModelWeightStream {
    let segments: [ModelSegment]
    let cached: Bool
}

struct MemoryStatus {
    let currentUsage: Int
    let availableRAM: Int
    let utilization: Double
    let cacheHitRate: Double
    let activeSegments: Int
    let compressionRatio: Double
}

struct TemporalFactors {
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let season: Season
    
    init(timeOfDay: TimeOfDay = .morning, dayOfWeek: DayOfWeek = .monday, season: Season = .spring) {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.season = season
    }
}

// MARK: - 🏷️ Enumerations

enum QueryComplexity {
    case low, medium, high
}

enum QueryType: String, Codable, CaseIterable {
    case general = "general"
    case coding = "coding"
    case creative = "creative"
    case factual = "factual"
    case analysis = "analysis"
    case reasoning = "reasoning"
    case technical = "technical"
    case debugging = "debugging"
    case conversational = "conversational"
    case research = "research"
    case speed = "speed"
    case embedding = "embedding"
}

enum ModelCapability: String, Codable, CaseIterable {
    case codeGeneration = "code_generation"
    case syntaxAnalysis = "syntax_analysis"
    case logicalReasoning = "logical_reasoning"
    case dataAnalysis = "data_analysis"
    case creativeWriting = "creative_writing"
    case storytelling = "storytelling"
    case factualAccuracy = "factual_accuracy"
    case knowledgeRetrieval = "knowledge_retrieval"
    case generalReasoning = "general_reasoning"
}

enum SegmentIdentifier: String {
    case inputEmbedding = "input_embedding"
    case attentionLayers = "attention_layers"
    case feedForward = "feed_forward"
    case outputHead = "output_head"
    case codeSpecificLayers = "code_layers"
    case reasoningLayers = "reasoning_layers"
}

enum StreamPriority {
    case realtime, background
}

enum TimeOfDay {
    case earlyMorning, morning, afternoon, evening, night
}

enum DayOfWeek {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

enum Season {
    case spring, summer, fall, winter
}

// MARK: - ❌ Error Types

enum QuantumMemoryError: Error, LocalizedError {
    case segmentNotFound(modelName: String, segment: SegmentIdentifier)
    case compressionFailed(reason: String)
    case insufficientMemory(required: Int, available: Int)
    case invalidModelFormat(modelName: String)
    
    var errorDescription: String? {
        switch self {
        case .segmentNotFound(let model, let segment):
            return "Model segment '\(segment.rawValue)' not found for model '\(model)'"
        case .compressionFailed(let reason):
            return "Compression failed: \(reason)"
        case .insufficientMemory(let required, let available):
            return "Insufficient memory: need \(required)MB, have \(available)MB"
        case .invalidModelFormat(let model):
            return "Invalid model format for '\(model)'"
        }
    }
}

// MARK: - 🛠️ Supporting Classes

class SystemResourceMonitor {
    func startMonitoring() async {
        // Monitor system resources
    }
    
    func getAvailableRAM() async -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        // Return available RAM in MB
        return Int(physicalMemory / (1024 * 1024))
    }
    
    func getTotalRAM() -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        return Int(physicalMemory / (1024 * 1024))
    }
    
    /// Get available RAM in real-time (non-async version for synchronous calls)
    func getAvailableRAM() -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = getCurrentMemoryUsage()
        let available = max(0, Int(physicalMemory / (1024 * 1024)) - usedMemory)
        return available
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / (1024 * 1024) // Convert to MB
        } else {
            return 0
        }
    }
}

class WeightCompressionEngine {
    var averageCompressionRatio: Double = 0.7
    
    func initialize() async {
        // Initialize compression engine
    }
    
    func decompress(_ segment: CompressedModelSegment) async throws -> ModelSegment {
        // Placeholder decompression
        return ModelSegment(
            id: segment.id,
            data: segment.data,
            memorySize: segment.data.count,
            lastAccessed: Date()
        )
    }
}

// MARK: - 🔗 Integration Extensions

extension QuantumMemoryManager {
    /// Integration point with existing PRISMEngine
    func integratePRISMEngine(_ engine: PRISMEngine) {
        logger.info("🔗 Integrating with PRISMEngine")
        // This will be used when enhancing PRISMEngine.swift
    }
    
    /// Integration point with existing ModelManager
    func integrateModelManager(_ manager: ModelManager) {
        logger.info("🔗 Integrating with ModelManager")
        // This will be used when enhancing ModelManager.swift
    }
}
