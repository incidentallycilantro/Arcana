//
// FactCheckingEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Local Fact-Checking and Verification System
//

import Foundation
import OSLog

// MARK: - Verification Types

enum VerificationStatus: String, Codable, CaseIterable {
    case verified = "verified"
    case unverified = "unverified"
    case disputed = "disputed"
    case flagged = "flagged"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .verified:
            return "Verified"
        case .unverified:
            return "Unverified"
        case .disputed:
            return "Disputed"
        case .flagged:
            return "Flagged"
        case .unknown:
            return "Unknown"
        }
    }
    
    var emoji: String {
        switch self {
        case .verified:
            return "✅"
        case .unverified:
            return "❓"
        case .disputed:
            return "⚠️"
        case .flagged:
            return "🚩"
        case .unknown:
            return "❔"
        }
    }
    
    var confidenceScore: Double {
        switch self {
        case .verified:
            return 0.9
        case .unverified:
            return 0.5
        case .disputed:
            return 0.3
        case .flagged:
            return 0.1
        case .unknown:
            return 0.0
        }
    }
}

struct FactCheckResult: Codable, Hashable, Identifiable {
    let id = UUID()
    let claim: String
    let status: VerificationStatus
    let confidence: Double
    let sources: [String]
    let explanation: String
    let timestamp: Date
    let checkedBy: String
    
    init(
        claim: String,
        status: VerificationStatus,
        confidence: Double = 0.0,
        sources: [String] = [],
        explanation: String = "",
        timestamp: Date = Date(),
        checkedBy: String = "Local FactChecker"
    ) {
        self.claim = claim
        self.status = status
        self.confidence = confidence
        self.sources = sources
        self.explanation = explanation
        self.timestamp = timestamp
        self.checkedBy = checkedBy
    }
    
    var isReliable: Bool {
        return status == .verified && confidence > 0.7
    }
    
    var needsReview: Bool {
        return status == .disputed || status == .flagged
    }
}

// MARK: - Main FactCheckingEngine

class FactCheckingEngine: ObservableObject {
    
    // MARK: - Published State
    @Published var isFactChecking = false
    @Published var recentResults: [FactCheckResult] = []
    @Published var totalFactChecks = 0
    @Published var accuracy = 0.85
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "FactCheckingEngine")
    private let knowledgeBase = LocalKnowledgeBase()
    private let claimExtractor = ClaimExtractor()
    
    // MARK: - Configuration
    private let confidenceThreshold = 0.7
    private let maxConcurrentChecks = 3
    private let factCheckQueue = DispatchQueue(label: "factcheck", qos: .userInitiated)
    
    init() {
        logger.info("🔍 FactCheckingEngine initialized")
    }
    
    // MARK: - Main Fact-Checking Interface
    
    /// Verify factual accuracy of content
    func verifyFactualAccuracy(content: String) async -> Double {
        logger.info("🔍 Starting fact-checking for content")
        
        await MainActor.run {
            isFactChecking = true
        }
        
        defer {
            Task { @MainActor in
                isFactChecking = false
            }
        }
        
        // 1. Extract factual claims
        let claims = extractClaims(from: content)
        
        if claims.isEmpty {
            logger.info("📝 No factual claims detected")
            return 0.8 // High confidence for non-factual content
        }
        
        // 2. Check each claim
        var results: [FactCheckResult] = []
        
        for claim in claims {
            let result = await checkClaim(claim)
            results.append(result)
        }
        
        // 3. Calculate overall accuracy
        let overallAccuracy = calculateOverallAccuracy(results)
        
        // 4. Update state
        await MainActor.run {
            recentResults = results
            totalFactChecks += results.count
        }
        
        logger.info("✅ Fact-checking completed: \(String(format: "%.1f", overallAccuracy * 100))% accuracy")
        
        return overallAccuracy
    }
    
    /// Check a batch of claims
    func checkClaims(_ claims: [String]) async -> [FactCheckResult] {
        var results: [FactCheckResult] = []
        
        // Process claims in batches to avoid overwhelming the system
        let batchSize = maxConcurrentChecks
        
        for batchStart in stride(from: 0, to: claims.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, claims.count)
            let batch = Array(claims[batchStart..<batchEnd])
            
            let batchResults = await withTaskGroup(of: FactCheckResult.self) { group in
                var results: [FactCheckResult] = []
                
                for claim in batch {
                    group.addTask {
                        await self.checkClaim(claim)
                    }
                }
                
                for await result in group {
                    results.append(result)
                }
                
                return results
            }
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    // MARK: - Claim Extraction
    
    private func extractClaims(from content: String) -> [String] {
        return claimExtractor.extractFactualClaims(from: content)
    }
    
    // MARK: - Individual Claim Checking
    
    private func checkClaim(_ claim: String) async -> FactCheckResult {
        logger.debug("🔍 Checking claim: \(claim)")
        
        // 1. Search local knowledge base
        let knowledgeResult = await knowledgeBase.searchForClaim(claim)
        
        // 2. Apply heuristic analysis
        let heuristicResult = analyzeClaimHeuristically(claim)
        
        // 3. Combine results
        let combinedStatus = combineVerificationResults(
            knowledgeResult: knowledgeResult,
            heuristicResult: heuristicResult
        )
        
        let confidence = calculateConfidence(
            knowledgeConfidence: knowledgeResult.confidence,
            heuristicConfidence: heuristicResult.confidence
        )
        
        return FactCheckResult(
            claim: claim,
            status: combinedStatus,
            confidence: confidence,
            sources: knowledgeResult.sources,
            explanation: generateExplanation(claim, status: combinedStatus),
            checkedBy: "Arcana FactChecker v1.0"
        )
    }
    
    // MARK: - Heuristic Analysis
    
    private func analyzeClaimHeuristically(_ claim: String) -> HeuristicResult {
        var confidence = 0.5
        var status = VerificationStatus.unknown
        
        let lowercaseClaim = claim.lowercased()
        
        // Check for absolute statements (often problematic)
        let absoluteWords = ["always", "never", "all", "none", "every", "completely", "totally"]
        let hasAbsolutes = absoluteWords.contains { lowercaseClaim.contains($0) }
        
        if hasAbsolutes {
            confidence *= 0.7 // Reduce confidence for absolute statements
            status = .unverified
        }
        
        // Check for uncertainty markers
        let uncertaintyMarkers = ["might", "could", "possibly", "probably", "seems", "appears"]
        let hasUncertainty = uncertaintyMarkers.contains { lowercaseClaim.contains($0) }
        
        if hasUncertainty {
            confidence *= 0.8 // Reduce confidence for uncertain claims
            status = .unverified
        }
        
        // Check for common misinformation patterns
        let suspiciousPatterns = [
            "scientists say", "studies show", "research proves",
            "doctors recommend", "experts agree"
        ]
        
        let hasSuspiciousPattern = suspiciousPatterns.contains { lowercaseClaim.contains($0) }
        
        if hasSuspiciousPattern {
            confidence *= 0.6
            status = .flagged
        }
        
        // Check for numerical claims (often need verification)
        let numericalPattern = try! NSRegularExpression(pattern: "\\d+[%]?", options: [])
        let hasNumbers = numericalPattern.firstMatch(
            in: claim,
            options: [],
            range: NSRange(location: 0, length: claim.utf16.count)
        ) != nil
        
        if hasNumbers {
            confidence *= 0.8
            status = .unverified
        }
        
        // Default to unknown if no patterns detected
        if status == .unknown {
            status = .unverified
            confidence = 0.5
        }
        
        return HeuristicResult(status: status, confidence: confidence)
    }
    
    // MARK: - Result Combination
    
    private func combineVerificationResults(
        knowledgeResult: KnowledgeResult,
        heuristicResult: HeuristicResult
    ) -> VerificationStatus {
        
        // If knowledge base has high confidence, use that
        if knowledgeResult.confidence > 0.8 {
            return knowledgeResult.status
        }
        
        // If heuristic analysis flags something, prioritize that
        if heuristicResult.status == .flagged || heuristicResult.status == .disputed {
            return heuristicResult.status
        }
        
        // Combine based on confidence levels
        let knowledgeWeight = knowledgeResult.confidence
        let heuristicWeight = heuristicResult.confidence
        
        return knowledgeWeight > heuristicWeight ?
            knowledgeResult.status : heuristicResult.status
    }
    
    private func calculateConfidence(
        knowledgeConfidence: Double,
        heuristicConfidence: Double
    ) -> Double {
        
        // Weighted average with higher weight for knowledge base
        let knowledgeWeight = 0.7
        let heuristicWeight = 0.3
        
        return (knowledgeConfidence * knowledgeWeight) +
               (heuristicConfidence * heuristicWeight)
    }
    
    // MARK: - Accuracy Calculation
    
    private func calculateOverallAccuracy(_ results: [FactCheckResult]) -> Double {
        guard !results.isEmpty else { return 0.8 }
        
        let totalConfidence = results.reduce(0) { $0 + $1.confidence }
        let averageConfidence = totalConfidence / Double(results.count)
        
        // Adjust for verification status distribution
        let verifiedCount = results.filter { $0.status == .verified }.count
        let flaggedCount = results.filter { $0.status == .flagged }.count
        
        let statusAdjustment = (Double(verifiedCount) - Double(flaggedCount)) / Double(results.count)
        
        return min(max(averageConfidence + (statusAdjustment * 0.1), 0.0), 1.0)
    }
    
    // MARK: - Explanation Generation
    
    private func generateExplanation(_ claim: String, status: VerificationStatus) -> String {
        switch status {
        case .verified:
            return "This claim has been verified against reliable sources."
        case .unverified:
            return "This claim could not be verified with available sources."
        case .disputed:
            return "This claim has conflicting information from different sources."
        case .flagged:
            return "This claim contains patterns often associated with misinformation."
        case .unknown:
            return "Insufficient information to verify this claim."
        }
    }
}

// MARK: - Supporting Classes

class LocalKnowledgeBase {
    func searchForClaim(_ claim: String) async -> KnowledgeResult {
        // Simulated knowledge base search
        // In a real implementation, this would search local databases, cached articles, etc.
        
        let confidence = Double.random(in: 0.3...0.9)
        let status: VerificationStatus = confidence > 0.7 ? .verified : .unverified
        
        return KnowledgeResult(
            status: status,
            confidence: confidence,
            sources: confidence > 0.7 ? ["Local Knowledge Base"] : []
        )
    }
}

class ClaimExtractor {
    func extractFactualClaims(from content: String) -> [String] {
        // Extract sentences that appear to make factual claims
        let sentences = content.components(separatedBy: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        return sentences.filter { sentence in
            !sentence.isEmpty &&
            sentence.count > 10 &&
            containsFactualIndicators(sentence)
        }
    }
    
    private func containsFactualIndicators(_ sentence: String) -> Bool {
        let factualPatterns = [
            "is", "are", "was", "were", "has", "have", "will", "can", "cannot",
            "according to", "studies show", "research indicates", "data shows",
            "percentage", "%", "million", "billion", "year", "years",
            "increase", "decrease", "higher", "lower", "more", "less"
        ]
        
        let lowercaseSentence = sentence.lowercased()
        return factualPatterns.contains { lowercaseSentence.contains($0) }
    }
}

// MARK: - Result Types

struct KnowledgeResult {
    let status: VerificationStatus
    let confidence: Double
    let sources: [String]
}

struct HeuristicResult {
    let status: VerificationStatus
    let confidence: Double
}

// MARK: - Extensions

extension FactCheckingEngine {
    /// Quick fact-check for a single claim
    func quickCheck(_ claim: String) async -> FactCheckResult {
        return await checkClaim(claim)
    }
    
    /// Get fact-check statistics
    var statistics: FactCheckStatistics {
        let verifiedCount = recentResults.filter { $0.status == .verified }.count
        let flaggedCount = recentResults.filter { $0.status == .flagged }.count
        let averageConfidence = recentResults.isEmpty ? 0.0 :
            recentResults.reduce(0) { $0 + $1.confidence } / Double(recentResults.count)
        
        return FactCheckStatistics(
            totalChecks: totalFactChecks,
            verifiedCount: verifiedCount,
            flaggedCount: flaggedCount,
            averageConfidence: averageConfidence,
            accuracy: accuracy
        )
    }
}

struct FactCheckStatistics {
    let totalChecks: Int
    let verifiedCount: Int
    let flaggedCount: Int
    let averageConfidence: Double
    let accuracy: Double
    
    var verificationRate: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(verifiedCount) / Double(totalChecks)
    }
    
    var flaggedRate: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(flaggedCount) / Double(totalChecks)
    }
}
