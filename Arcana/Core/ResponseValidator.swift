//
// ResponseValidator.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Research-Grade Response Validation System
//

import Foundation
import OSLog

class ResponseValidator: ObservableObject {
    
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ResponseValidator")
    
    // MARK: - Configuration
    private let validationLevel: ValidationLevel
    private let confidenceThreshold: Double
    private let uncertaintyThreshold: Double
    private let factCheckingEngine: FactCheckingEngine?
    
    // MARK: - Validation Metrics
    @Published var validationMetrics = ValidationMetrics()
    
    init(
        validationLevel: ValidationLevel = .standard,
        confidenceThreshold: Double = 0.8,
        uncertaintyThreshold: Double = 0.3,
        factCheckingEngine: FactCheckingEngine? = nil
    ) {
        self.validationLevel = validationLevel
        self.confidenceThreshold = confidenceThreshold
        self.uncertaintyThreshold = uncertaintyThreshold
        self.factCheckingEngine = factCheckingEngine
        
        logger.info("🔍 ResponseValidator initialized with level: \(validationLevel.rawValue)")
    }
    
    // MARK: - Main Validation Function
    
    /// Validate a response and return comprehensive quality assessment
    func validateResponse(
        content: String,
        prompt: String,
        model: String,
        rawConfidence: Double,
        ensembleInfo: EnsembleInfo? = nil
    ) async -> ValidationResult {
        
        let startTime = Date()
        logger.info("🔍 Starting validation for \(model) response")
        
        do {
            // 1. Basic validation checks
            let basicChecks = performBasicValidation(content: content)
            
            // 2. Content quality assessment
            let contentQuality = await assessContentQuality(
                content: content,
                prompt: prompt
            )
            
            // 3. Uncertainty detection
            let uncertaintyFactors = await detectUncertainties(
                content: content,
                prompt: prompt,
                model: model
            )
            
            // 4. Confidence calibration
            let calibratedConfidence = await calibrateConfidence(
                rawConfidence: rawConfidence,
                content: content,
                model: model,
                uncertaintyFactors: uncertaintyFactors
            )
            
            // 5. Fact checking (if available and enabled)
            let factualAccuracy = await performFactChecking(
                content: content,
                model: model
            )
            
            // 6. Ensemble consensus (if applicable)
            let consensusScore = ensembleInfo?.consensusScore
            
            // 7. Generate comprehensive quality assessment
            let responseQuality = await generateQualityAssessment(
                content: content,
                basicChecks: basicChecks,
                contentQuality: contentQuality,
                factualAccuracy: factualAccuracy,
                calibratedConfidence: calibratedConfidence,
                uncertaintyFactors: uncertaintyFactors,
                consensusScore: consensusScore,
                model: model,
                validationLevel: validationLevel
            )
            
            // 8. Determine if validation passed
            let passedValidation = responseQuality.overallScore >= confidenceThreshold &&
                                 uncertaintyFactors.count <= 3 &&
                                 factualAccuracy >= 0.7
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // 9. Update metrics
            await updateValidationMetrics(
                result: responseQuality,
                success: passedValidation,
                processingTime: processingTime
            )
            
            logger.info("✅ Validation completed: \(String(format: "%.2f", responseQuality.overallScore * 100))% quality")
            
            return ValidationResult(
                quality: responseQuality,
                passedValidation: passedValidation,
                processingTime: processingTime,
                validationLevel: validationLevel
            )
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            logger.error("❌ Validation failed: \(error.localizedDescription)")
            
            // Return failed validation result
            let failedQuality = ResponseQuality.failed(error: error.localizedDescription)
            
            return ValidationResult(
                quality: failedQuality,
                passedValidation: false,
                processingTime: processingTime,
                validationLevel: validationLevel,
                error: error
            )
        }
    }
    
    // MARK: - Validation Components
    
    private func performBasicValidation(content: String) -> BasicValidationChecks {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        return BasicValidationChecks(
            isEmpty: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isTooShort: wordCount < 5,
            isTooLong: wordCount > 2000,
            hasStructure: content.contains(".") || content.contains("?") || content.contains("!"),
            wordCount: wordCount
        )
    }
    
    private func assessContentQuality(
        content: String,
        prompt: String
    ) async -> ContentQuality {
        
        // Analyze various quality dimensions
        let relevance = await analyzeRelevance(content: content, prompt: prompt)
        let coherence = await analyzeCoherence(content: content)
        let completeness = await analyzeCompleteness(content: content, prompt: prompt)
        let clarity = await analyzeClarity(content: content)
        
        return ContentQuality(
            relevance: relevance,
            coherence: coherence,
            completeness: completeness,
            clarity: clarity,
            overallScore: (relevance + coherence + completeness + clarity) / 4.0
        )
    }
    
    private func detectUncertainties(
        content: String,
        prompt: String,
        model: String
    ) async -> [UncertaintyFactor] {
        
        var uncertainties: [UncertaintyFactor] = []
        
        // Detect uncertainty phrases
        let uncertaintyPhrases = [
            "I think", "maybe", "possibly", "might be", "could be",
            "I'm not sure", "uncertain", "unclear", "I don't know"
        ]
        
        for phrase in uncertaintyPhrases {
            if content.lowercased().contains(phrase) {
                uncertainties.append(UncertaintyFactor(
                    type: .linguisticMarker,
                    description: "Contains uncertainty phrase: '\(phrase)'",
                    severity: 0.3,
                    location: nil,
                    detectedAt: Date(),
                    confidence: 0.8
                ))
            }
        }
        
        // Detect contradictions
        if await detectContradictions(content: content) {
            uncertainties.append(UncertaintyFactor(
                type: .contradiction,
                description: "Contains potentially contradictory statements",
                severity: 0.7,
                location: nil,
                detectedAt: Date(),
                confidence: 0.7
            ))
        }
        
        return uncertainties
    }
    
    private func calibrateConfidence(
        rawConfidence: Double,
        content: String,
        model: String,
        uncertaintyFactors: [UncertaintyFactor]
    ) async -> Double {
        
        var calibratedConfidence = rawConfidence
        
        // Adjust for uncertainty factors
        let uncertaintyPenalty = uncertaintyFactors.reduce(into: 0.0) { result, factor in
            result += factor.weightedSeverity * 0.1
        }
        
        calibratedConfidence = max(0.0, calibratedConfidence - uncertaintyPenalty)
        
        // Model-specific calibration (placeholder)
        if model.contains("gpt") {
            calibratedConfidence *= 0.95 // Slight adjustment for GPT models
        }
        
        return min(1.0, calibratedConfidence)
    }
    
    private func performFactChecking(
        content: String,
        model: String
    ) async -> Double {
        
        guard let factChecker = factCheckingEngine else {
            return 0.8 // Default score when fact checking unavailable
        }
        
        return await factChecker.verifyFactualAccuracy(content: content)
    }
    
    private func generateQualityAssessment(
        content: String,
        basicChecks: BasicValidationChecks,
        contentQuality: ContentQuality,
        factualAccuracy: Double,
        calibratedConfidence: Double,
        uncertaintyFactors: [UncertaintyFactor],
        consensusScore: Double?,
        model: String,
        validationLevel: ValidationLevel
    ) async -> ResponseQuality {
        
        // Calculate weighted content score
        let contentScore = (contentQuality.relevance * 0.3 +
                           contentQuality.coherence * 0.25 +
                           contentQuality.completeness * 0.25 +
                           contentQuality.clarity * 0.2)
        
        // Adjust for basic validation failures
        var adjustedContentScore = contentScore
        if basicChecks.isEmpty || basicChecks.isTooShort {
            adjustedContentScore *= 0.5
        }
        if basicChecks.isTooLong {
            adjustedContentScore *= 0.8
        }
        if !basicChecks.hasStructure {
            adjustedContentScore *= 0.9
        }
        
        // Calculate uncertainty impact
        let uncertaintyScore = min(uncertaintyFactors.reduce(into: 0.0) { result, factor in
            result += factor.weightedSeverity
        }, 1.0)
        
        // Generate overall score
        let overallScore = (adjustedContentScore * 0.4 +
                           factualAccuracy * 0.3 +
                           calibratedConfidence * 0.2 +
                           (1.0 - uncertaintyScore) * 0.1)
        
        return ResponseQuality(
            overallScore: overallScore,
            contentQuality: adjustedContentScore,
            factualAccuracy: factualAccuracy,
            relevance: contentQuality.relevance,
            coherence: contentQuality.coherence,
            completeness: contentQuality.completeness,
            clarity: contentQuality.clarity,
            rawConfidence: calibratedConfidence,
            calibratedConfidence: calibratedConfidence,
            consensusScore: consensusScore,
            uncertaintyFactors: uncertaintyFactors,
            uncertaintyScore: uncertaintyScore,
            validationLevel: validationLevel,
            modelContributions: [model],
            processingTime: 0.0
        )
    }
    
    // MARK: - Helper Methods
    
    private func analyzeRelevance(content: String, prompt: String) async -> Double {
        let promptWords = Set(prompt.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let contentWords = Set(content.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = promptWords.intersection(contentWords)
        let relevanceScore = Double(intersection.count) / Double(max(promptWords.count, 1))
        
        return min(1.0, relevanceScore * 2.0)
    }
    
    private func analyzeCoherence(content: String) async -> Double {
        let sentences = content.components(separatedBy: ". ").filter { !$0.isEmpty }
        guard sentences.count > 1 else { return 0.8 }
        
        var coherenceScore = 0.8
        let sentenceLengths = sentences.map { $0.count }
        let avgLength = sentenceLengths.reduce(0, +) / sentenceLengths.count
        let variance = sentenceLengths.map { pow(Double($0 - avgLength), 2) }.reduce(0, +) / Double(sentenceLengths.count)
        
        if variance > 100 && variance < 1000 {
            coherenceScore += 0.1
        }
        
        return min(1.0, coherenceScore)
    }
    
    private func analyzeCompleteness(content: String, prompt: String) async -> Double {
        let promptComponents = extractPromptComponents(prompt)
        var addressedComponents = 0
        
        for component in promptComponents {
            if content.lowercased().contains(component.lowercased()) {
                addressedComponents += 1
            }
        }
        
        guard promptComponents.count > 0 else { return 0.8 }
        return Double(addressedComponents) / Double(promptComponents.count)
    }
    
    private func analyzeClarity(content: String) async -> Double {
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let avgWordLength = Double(words.map { $0.count }.reduce(0, +)) / Double(max(words.count, 1))
        
        let clarityScore = 1.0 - abs(avgWordLength - 5.0) / 10.0
        return max(0.3, min(1.0, clarityScore))
    }
    
    private func detectContradictions(content: String) async -> Bool {
        let contradictionPairs = [
            ("yes", "no"), ("true", "false"), ("always", "never"),
            ("all", "none"), ("possible", "impossible")
        ]
        
        let lowercasedContent = content.lowercased()
        
        for (word1, word2) in contradictionPairs {
            if lowercasedContent.contains(word1) && lowercasedContent.contains(word2) {
                return true
            }
        }
        
        return false
    }
    
    private func extractPromptComponents(_ prompt: String) -> [String] {
        let questionWords = ["what", "how", "why", "when", "where", "who", "which"]
        let actionWords = ["explain", "describe", "analyze", "compare", "summarize"]
        
        var components: [String] = []
        let words = prompt.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for word in words {
            if questionWords.contains(word) || actionWords.contains(word) {
                components.append(word)
            }
        }
        
        return components.isEmpty ? ["general"] : components
    }
    
    private func updateValidationMetrics(
        result: ResponseQuality,
        success: Bool,
        processingTime: TimeInterval
    ) async {
        
        let successCount = success ? 1 : 0
        validationMetrics.totalValidations += 1
        validationMetrics.successfulValidations += successCount
        
        let totalValidations = validationMetrics.totalValidations
        validationMetrics.successRate = totalValidations > 1 ?
            (validationMetrics.successRate * Double(totalValidations - 1) + Double(successCount)) / Double(totalValidations) :
            Double(successCount)
        
        validationMetrics.averageQualityScore = totalValidations > 1 ?
            (validationMetrics.averageQualityScore * Double(totalValidations - 1) + result.overallScore) / Double(totalValidations) :
            result.overallScore
    }
}

// MARK: - Supporting Structures

struct EnsembleInfo {
    let models: [String]
    let strategy: String
    let consensusScore: Double
}

struct ValidationResult {
    let quality: ResponseQuality
    let passedValidation: Bool
    let processingTime: TimeInterval
    let validationLevel: ValidationLevel
    let error: Error?
    
    init(
        quality: ResponseQuality,
        passedValidation: Bool,
        processingTime: TimeInterval,
        validationLevel: ValidationLevel,
        error: Error? = nil
    ) {
        self.quality = quality
        self.passedValidation = passedValidation
        self.processingTime = processingTime
        self.validationLevel = validationLevel
        self.error = error
    }
    
    var isSuccessful: Bool {
        return error == nil && passedValidation
    }
    
    var summary: String {
        let qualityPercent = String(format: "%.0f%%", quality.overallScore * 100)
        let status = passedValidation ? "✅ Passed" : "❌ Failed"
        return "\(status) - \(qualityPercent) quality"
    }
}

struct BasicValidationChecks {
    let isEmpty: Bool
    let isTooShort: Bool
    let isTooLong: Bool
    let hasStructure: Bool
    let wordCount: Int
}

struct ContentQuality {
    let relevance: Double
    let coherence: Double
    let completeness: Double
    let clarity: Double
    let overallScore: Double
}

struct ValidationMetrics {
    var totalValidations: Int = 0
    var successfulValidations: Int = 0
    var successRate: Double = 0.0
    var averageQualityScore: Double = 0.0
}

// MARK: - Extensions

extension ResponseValidator {
    func quickValidate(content: String, confidence: Double) async -> ValidationResult {
        let basicQuality = ResponseQuality.basic(
            overallScore: confidence,
            confidence: confidence
        )
        
        return ValidationResult(
            quality: basicQuality,
            passedValidation: confidence >= confidenceThreshold,
            processingTime: 0.1,
            validationLevel: .basic
        )
    }
    
    func validateAndSelectBest(
        responses: [(content: String, model: String, confidence: Double)],
        prompt: String
    ) async -> (best: ValidationResult, allResults: [ValidationResult]) {
        
        var results: [ValidationResult] = []
        
        for response in responses {
            let result = await validateResponse(
                content: response.content,
                prompt: prompt,
                model: response.model,
                rawConfidence: response.confidence
            )
            results.append(result)
        }
        
        let bestResult = results.max { a, b in
            a.quality.overallScore < b.quality.overallScore
        } ?? results.first!
        
        return (best: bestResult, allResults: results)
    }
}

// MARK: - Error Types

enum ValidationError: Error, LocalizedError {
    case invalidInput(String)
    case processingFailed(String)
    case timeoutExceeded
    case resourceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .processingFailed(let details):
            return "Processing failed: \(details)"
        case .timeoutExceeded:
            return "Validation timeout exceeded"
        case .resourceUnavailable:
            return "Required validation resources unavailable"
        }
    }
}

// REMOVED: Duplicate FactCheckingEngine class - use the actual implementation from FactCheckingEngine.swift
