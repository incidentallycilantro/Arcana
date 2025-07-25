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
            
            // 7. Generate comprehensive quality score
            let responseQuality = generateQualityScore(
                basicChecks: basicChecks,
                contentQuality: contentQuality,
                uncertaintyFactors: uncertaintyFactors,
                calibratedConfidence: calibratedConfidence,
                factualAccuracy: factualAccuracy,
                consensusScore: consensusScore,
                model: model
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Update metrics
            await MainActor.run {
                validationMetrics.totalValidations += 1
                validationMetrics.averageProcessingTime =
                    (validationMetrics.averageProcessingTime * Double(validationMetrics.totalValidations - 1) + processingTime)
                    / Double(validationMetrics.totalValidations)
            }
            
            logger.info("✅ Validation completed in \(String(format: "%.2f", processingTime))s - Quality: \(String(format: "%.1f", responseQuality.overallScore * 100))%")
            
            return ValidationResult(
                quality: responseQuality,
                passedValidation: responseQuality.overallScore >= confidenceThreshold,
                processingTime: processingTime,
                validationLevel: validationLevel
            )
            
        } catch {
            logger.error("❌ Validation failed: \(error.localizedDescription)")
            
            // Return minimal quality assessment on error
            let fallbackQuality = ResponseQuality.basic(
                overallScore: 0.5,
                confidence: rawConfidence
            )
            
            return ValidationResult(
                quality: fallbackQuality,
                passedValidation: false,
                processingTime: Date().timeIntervalSince(startTime),
                validationLevel: validationLevel,
                error: error
            )
        }
    }
    
    // MARK: - Basic Validation
    
    private func performBasicValidation(content: String) -> BasicValidationChecks {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let characterCount = content.count
        let hasStructure = content.contains("\n") || content.contains(".") || content.contains(":")
        let hasProperEnding = content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(".") ||
                             content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("!") ||
                             content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")
        
        return BasicValidationChecks(
            wordCount: wordCount,
            characterCount: characterCount,
            hasStructure: hasStructure,
            hasProperEnding: hasProperEnding,
            isEmpty: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isTooShort: wordCount < 5,
            isTooLong: wordCount > 2000
        )
    }
    
    // MARK: - Content Quality Assessment
    
    private func assessContentQuality(content: String, prompt: String) async -> ContentQualityAssessment {
        // Implement content quality analysis
        let relevance = calculateRelevance(content: content, prompt: prompt)
        let coherence = assessCoherence(content: content)
        let completeness = assessCompleteness(content: content, prompt: prompt)
        let clarity = assessClarity(content: content)
        
        return ContentQualityAssessment(
            relevance: relevance,
            coherence: coherence,
            completeness: completeness,
            clarity: clarity
        )
    }
    
    private func calculateRelevance(content: String, prompt: String) -> Double {
        // Basic keyword matching approach
        let promptKeywords = extractKeywords(from: prompt)
        let contentKeywords = extractKeywords(from: content)
        
        let matchingKeywords = Set(promptKeywords).intersection(Set(contentKeywords))
        let relevanceScore = Double(matchingKeywords.count) / Double(max(promptKeywords.count, 1))
        
        return min(max(relevanceScore, 0.0), 1.0)
    }
    
    private func assessCoherence(content: String) -> Double {
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if sentences.count < 2 { return 0.5 }
        
        // Basic coherence indicators
        let transitionWords = ["however", "therefore", "moreover", "furthermore", "additionally", "consequently", "meanwhile", "similarly", "in contrast", "for example"]
        let hasTransitions = transitionWords.contains { content.localizedCaseInsensitiveContains($0) }
        
        return hasTransitions ? 0.8 : 0.6
    }
    
    private func assessCompleteness(content: String, prompt: String) -> Double {
        // Basic assessment based on content length relative to prompt complexity
        let promptWords = prompt.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let contentWords = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        let expectedRatio = 3.0 // Expect response to be ~3x longer than prompt
        let actualRatio = Double(contentWords) / Double(max(promptWords, 1))
        
        let completenessScore = min(actualRatio / expectedRatio, 1.0)
        return max(completenessScore, 0.3) // Minimum score of 0.3
    }
    
    private func assessClarity(content: String) -> Double {
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        if sentences.isEmpty { return 0.3 }
        
        let averageWordsPerSentence = Double(words.count) / Double(sentences.count)
        
        // Ideal sentence length is 15-20 words
        let clarityScore = averageWordsPerSentence <= 25 ? 0.8 : 0.6
        
        return clarityScore
    }
    
    private func extractKeywords(from text: String) -> [String] {
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
            .filter { !["that", "this", "with", "from", "they", "have", "been", "said", "each", "which", "their", "time", "will", "about", "what", "make", "when", "many"].contains($0) }
    }
    
    // MARK: - Uncertainty Detection
    
    private func detectUncertainties(content: String, prompt: String, model: String) async -> [UncertaintyFactor] {
        var uncertainties: [UncertaintyFactor] = []
        
        // Detect linguistic uncertainty markers
        let linguisticMarkers = ["might", "could", "perhaps", "possibly", "maybe", "seems", "appears", "probably", "likely", "uncertain", "unclear", "I think", "I believe"]
        
        for marker in linguisticMarkers {
            if content.localizedCaseInsensitiveContains(marker) {
                uncertainties.append(UncertaintyFactor(
                    type: .linguisticMarker,
                    description: "Contains linguistic uncertainty marker: '\(marker)'",
                    severity: 0.3,
                    location: "Throughout text",
                    confidence: 0.8
                ))
            }
        }
        
        // Detect contradictions (basic approach)
        if detectContradictions(in: content) {
            uncertainties.append(UncertaintyFactor(
                type: .contradiction,
                description: "Potential internal contradictions detected",
                severity: 0.8,
                confidence: 0.7
            ))
        }
        
        // Detect insufficient context
        if content.count < 100 && prompt.count > 50 {
            uncertainties.append(UncertaintyFactor(
                type: .insufficientContext,
                description: "Response may be too brief for the complexity of the question",
                severity: 0.5,
                confidence: 0.6
            ))
        }
        
        // Model-specific uncertainty patterns
        uncertainties.append(contentsOf: detectModelSpecificUncertainties(content: content, model: model))
        
        return uncertainties
    }
    
    private func detectContradictions(in content: String) -> Bool {
        // Very basic contradiction detection
        let sentences = content.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let contradictionPairs = [
            ("yes", "no"),
            ("true", "false"),
            ("always", "never"),
            ("all", "none"),
            ("increase", "decrease"),
            ("positive", "negative")
        ]
        
        for (word1, word2) in contradictionPairs {
            if content.localizedCaseInsensitiveContains(word1) && content.localizedCaseInsensitiveContains(word2) {
                return true
            }
        }
        
        return false
    }
    
    private func detectModelSpecificUncertainties(content: String, model: String) -> [UncertaintyFactor] {
        var uncertainties: [UncertaintyFactor] = []
        
        switch model {
        case "Phi-2":
            if content.count < 50 {
                uncertainties.append(UncertaintyFactor(
                    type: .modelLimitation,
                    description: "Phi-2 responses under 50 characters may be truncated",
                    severity: 0.6,
                    confidence: 0.8
                ))
            }
            
        case "CodeLlama-7B":
            if !content.contains("```") && content.localizedCaseInsensitiveContains("code") {
                uncertainties.append(UncertaintyFactor(
                    type: .modelLimitation,
                    description: "CodeLlama may not have provided expected code examples",
                    severity: 0.4,
                    confidence: 0.6
                ))
            }
            
        default:
            break
        }
        
        return uncertainties
    }
    
    // MARK: - Confidence Calibration
    
    private func calibrateConfidence(
        rawConfidence: Double,
        content: String,
        model: String,
        uncertaintyFactors: [UncertaintyFactor]
    ) async -> Double {
        
        var calibratedConfidence = rawConfidence
        
        // Adjust for uncertainty factors
        let totalUncertaintyWeight = uncertaintyFactors.reduce(0) { $0 + $1.weightedSeverity }
        calibratedConfidence *= (1.0 - min(totalUncertaintyWeight, 0.5))
        
        // Model-specific calibration
        calibratedConfidence *= getModelCalibrationFactor(model)
        
        // Content length adjustment
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        if wordCount < 10 {
            calibratedConfidence *= 0.8 // Penalize very short responses
        }
        
        return min(max(calibratedConfidence, 0.0), 1.0)
    }
    
    private func getModelCalibrationFactor(_ model: String) -> Double {
        switch model {
        case "BGE-Large":
            return 0.95 // High reliability for factual content
        case "Mistral-7B":
            return 0.92
        case "CodeLlama-7B":
            return 0.90
        case "Llama-2-7B":
            return 0.88
        case "Phi-2":
            return 0.85
        default:
            return 0.80
        }
    }
    
    // MARK: - Fact Checking
    
    private func performFactChecking(content: String, model: String) async -> Double {
        // If fact checking engine is available, use it
        if let factChecker = factCheckingEngine {
            return await factChecker.verifyFactualAccuracy(content: content)
        }
        
        // Basic heuristic-based fact checking
        return performBasicFactChecking(content: content, model: model)
    }
    
    private func performBasicFactChecking(content: String, model: String) -> Double {
        // Basic fact checking based on model reliability and content patterns
        let baseAccuracy = getModelBaseAccuracy(model)
        
        // Look for fact-assertive language
        let assertivePatterns = ["definitely", "certainly", "always", "never", "all", "none", "exactly", "precisely"]
        let hasAssertiveLanguage = assertivePatterns.contains { content.localizedCaseInsensitiveContains($0) }
        
        // Be more conservative with assertive statements
        return hasAssertiveLanguage ? baseAccuracy * 0.9 : baseAccuracy
    }
    
    private func getModelBaseAccuracy(_ model: String) -> Double {
        switch model {
        case "BGE-Large": return 0.95
        case "Mistral-7B": return 0.89
        case "CodeLlama-7B": return 0.85
        case "Llama-2-7B": return 0.82
        case "Phi-2": return 0.80
        default: return 0.75
        }
    }
    
    // MARK: - Quality Score Generation
    
    private func generateQualityScore(
        basicChecks: BasicValidationChecks,
        contentQuality: ContentQualityAssessment,
        uncertaintyFactors: [UncertaintyFactor],
        calibratedConfidence: Double,
        factualAccuracy: Double,
        consensusScore: Double?,
        model: String
    ) -> ResponseQuality {
        
        // Calculate weighted scores
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
        let uncertaintyScore = min(uncertaintyFactors.reduce(0) { $0 + $1.weightedSeverity }, 1.0)
        
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
            rawConfidence: calibratedConfidence, // Store calibrated as raw for this context
            calibratedConfidence: calibratedConfidence,
            consensusScore: consensusScore,
            uncertaintyFactors: uncertaintyFactors,
            uncertaintyScore: uncertaintyScore,
            validationLevel: validationLevel,
            modelContributions: [model],
            processingTime: 0.0 // Will be set by caller
        )
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
        let status = passedValidation ? "✅ PASSED" : "❌ FAILED"
        return "\(status) - Quality: \(qualityPercent) (\(String(format: "%.2f", processingTime))s)"
    }
}

struct BasicValidationChecks {
    let wordCount: Int
    let characterCount: Int
    let hasStructure: Bool
    let hasProperEnding: Bool
    let isEmpty: Bool
    let isTooShort: Bool
    let isTooLong: Bool
    
    var passedBasicChecks: Bool {
        return !isEmpty && !isTooShort && !isTooLong
    }
}

struct ContentQualityAssessment {
    let relevance: Double
    let coherence: Double
    let completeness: Double
    let clarity: Double
    
    var averageScore: Double {
        return (relevance + coherence + completeness + clarity) / 4.0
    }
}

struct ValidationMetrics {
    var totalValidations: Int = 0
    var averageProcessingTime: TimeInterval = 0.0
    var successRate: Double = 0.0
    var averageQualityScore: Double = 0.0
    
    mutating func updateWithResult(_ result: ValidationResult) {
        totalValidations += 1
        
        // Update average processing time
        averageProcessingTime = (averageProcessingTime * Double(totalValidations - 1) + result.processingTime) / Double(totalValidations)
        
        // Update success rate
        let successCount = result.passedValidation ? 1 : 0
        successRate = (successRate * Double(totalValidations - 1) + Double(successCount)) / Double(totalValidations)
        
        // Update average quality score
        averageQualityScore = (averageQualityScore * Double(totalValidations - 1) + result.quality.overallScore) / Double(totalValidations)
    }
}

// MARK: - Note: FactCheckingEngine is defined in separate FactCheckingEngine.swift file
// Remove the duplicate stub class that was causing compilation errors

// MARK: - Extensions

extension ResponseValidator {
    /// Quick validation for basic use cases
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
    
    /// Validate multiple responses and return the best one
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
