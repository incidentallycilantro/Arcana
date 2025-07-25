//
// IntelligenceEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//

import Foundation
import SwiftUI
import OSLog

@MainActor
class IntelligenceEngine: ObservableObject {
    // MARK: - Singleton Pattern
    static let shared = IntelligenceEngine.shared
    
    // MARK: - Published State
    @Published var isProcessing = false
    @Published var currentWorkspaceType: WorkspaceManager.WorkspaceType = .general
    @Published var lastGeneratedResponse: String = ""
    @Published var confidenceScore: Double = 0.0
    
    // MARK: - Core Components
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "IntelligenceEngine")
    private let workspaceManager = WorkspaceManager.shared
    
    // MARK: - Intelligence Configuration
    private let minimumContextLength = 50
    private let workspaceTypeThreshold = 0.7
    private let responseConfidenceThreshold = 0.8
    
    private init() {
        logger.info("🧠 IntelligenceEngine initialized")
    }
    
    // MARK: - Main Intelligence Interface
    
    func generateContextualResponse(
        for prompt: String,
        context: [ChatMessage] = [],
        workspaceType: WorkspaceManager.WorkspaceType = .general
    ) async -> String {
        
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("🎯 Generating contextual response for workspace type: \(workspaceType.rawValue)")
        
        // 1. Analyze prompt and context
        let analysisResult = analyzePromptIntelligence(prompt, context: context)
        
        // 2. Generate appropriate response based on workspace type
        let response = generateIntelligentResponse(
            prompt: prompt,
            context: context,
            detectedType: analysisResult.detectedType,
            confidence: analysisResult.confidence
        )
        
        // 3. Update state
        currentWorkspaceType = analysisResult.detectedType
        confidenceScore = analysisResult.confidence
        lastGeneratedResponse = response
        
        return response
    }
    
    // MARK: - Workspace Type Detection
    
    func detectWorkspaceType(from content: String) -> WorkspaceManager.WorkspaceType {
        let analysisResult = analyzePromptIntelligence(content, context: [])
        return analysisResult.detectedType
    }
    
    func analyzePromptIntelligence(
        _ prompt: String,
        context: [ChatMessage] = []
    ) -> PromptAnalysisResult {
        
        let combinedContent = ([prompt] + context.map { $0.content }).joined(separator: " ")
        
        // Detect workspace type using keyword analysis
        let detectedType = performWorkspaceTypeDetection(combinedContent)
        
        // Calculate confidence based on content analysis
        let confidence = calculateAnalysisConfidence(combinedContent, detectedType: detectedType)
        
        return PromptAnalysisResult(
            detectedType: detectedType,
            confidence: confidence,
            keywords: extractKeywords(from: combinedContent),
            primaryContext: extractPrimaryContext(from: combinedContent)
        )
    }
    
    private func performWorkspaceTypeDetection(_ content: String) -> WorkspaceManager.WorkspaceType {
        let lowercaseContent = content.lowercased()
        
        // Code-related patterns
        let codePatterns = [
            "function", "class", "method", "variable", "array", "object",
            "api", "endpoint", "rest", "graphql", "database", "sql",
            "javascript", "python", "swift", "react", "node", "express",
            "authentication", "authorization", "jwt", "oauth",
            "frontend", "backend", "server", "client", "web development",
            "mobile app", "ios", "android", "xcode", "git", "github",
            "bug", "debug", "testing", "deployment", "devops"
        ]
        
        // Research-related patterns
        let researchPatterns = [
            "research", "study", "analysis", "data", "statistics",
            "experiment", "hypothesis", "methodology", "findings",
            "literature review", "academic", "paper", "journal",
            "survey", "interview", "qualitative", "quantitative",
            "correlation", "trend", "pattern", "insight"
        ]
        
        // Creative-related patterns
        let creativePatterns = [
            "story", "narrative", "character", "plot", "creative writing",
            "blog post", "article", "content", "marketing", "campaign",
            "brand", "design", "visual", "creative", "brainstorm",
            "idea", "concept", "inspiration", "artistic", "creative brief"
        ]
        
        // Business-related patterns
        let businessPatterns = [
            "business", "strategy", "market", "customer", "revenue",
            "profit", "sales", "marketing", "competition", "analysis",
            "plan", "proposal", "meeting", "presentation", "report",
            "kpi", "metrics", "roi", "budget", "financial"
        ]
        
        // Calculate scores for each type
        let codeScore = calculatePatternScore(content: lowercaseContent, patterns: codePatterns)
        let researchScore = calculatePatternScore(content: lowercaseContent, patterns: researchPatterns)
        let creativeScore = calculatePatternScore(content: lowercaseContent, patterns: creativePatterns)
        let businessScore = calculatePatternScore(content: lowercaseContent, patterns: businessPatterns)
        
        // Determine the highest scoring type
        let scores = [
            (WorkspaceManager.WorkspaceType.code, codeScore),
            (WorkspaceManager.WorkspaceType.research, researchScore),
            (WorkspaceManager.WorkspaceType.creative, creativeScore),
            (WorkspaceManager.WorkspaceType.business, businessScore)
        ]
        
        let bestMatch = scores.max { $0.1 < $1.1 }
        
        // Return detected type if confidence is high enough, otherwise general
        if let match = bestMatch, match.1 >= workspaceTypeThreshold {
            return match.0
        } else {
            return .general
        }
    }
    
    private func calculatePatternScore(content: String, patterns: [String]) -> Double {
        let matchingPatterns = patterns.filter { pattern in
            content.contains(pattern)
        }
        
        return Double(matchingPatterns.count) / Double(patterns.count)
    }
    
    private func calculateAnalysisConfidence(
        _ content: String,
        detectedType: WorkspaceManager.WorkspaceType
    ) -> Double {
        
        // Base confidence on content length and structure
        let lengthScore = min(Double(content.count) / 200.0, 1.0)
        let structureScore = content.contains(" ") && content.count > minimumContextLength ? 0.8 : 0.4
        
        // Adjust for workspace-specific patterns
        let typeSpecificScore = calculateTypeSpecificConfidence(content, type: detectedType)
        
        return (lengthScore + structureScore + typeSpecificScore) / 3.0
    }
    
    private func calculateTypeSpecificConfidence(
        _ content: String,
        type: WorkspaceManager.WorkspaceType
    ) -> Double {
        
        switch type {
        case .code:
            let codeIndicators = ["function", "class", "api", "database", "javascript", "python", "swift"]
            let matches = codeIndicators.filter { content.lowercased().contains($0) }
            return Double(matches.count) / Double(codeIndicators.count)
            
        case .research:
            let researchIndicators = ["research", "study", "analysis", "data", "findings", "methodology"]
            let matches = researchIndicators.filter { content.lowercased().contains($0) }
            return Double(matches.count) / Double(researchIndicators.count)
            
        case .creative:
            let creativeIndicators = ["story", "creative", "content", "brand", "campaign", "design"]
            let matches = creativeIndicators.filter { content.lowercased().contains($0) }
            return Double(matches.count) / Double(creativeIndicators.count)
            
        case .business:
            let businessIndicators = ["business", "strategy", "market", "revenue", "plan", "analysis"]
            let matches = businessIndicators.filter { content.lowercased().contains($0) }
            return Double(matches.count) / Double(businessIndicators.count)
            
        case .general:
            return 0.6 // Moderate confidence for general type
        }
    }
    
    // MARK: - Response Generation
    
    private func generateIntelligentResponse(
        prompt: String,
        context: [ChatMessage],
        detectedType: WorkspaceManager.WorkspaceType,
        confidence: Double
    ) -> String {
        
        // This is a placeholder implementation
        // In the full PRISM system, this would integrate with the ensemble orchestrator
        
        let contextualPrompt = buildContextualPrompt(
            prompt: prompt,
            type: detectedType,
            context: context
        )
        
        // For now, return a contextually appropriate response template
        return generateResponseTemplate(
            prompt: contextualPrompt,
            type: detectedType,
            confidence: confidence
        )
    }
    
    private func buildContextualPrompt(
        prompt: String,
        type: WorkspaceManager.WorkspaceType,
        context: [ChatMessage]
    ) -> String {
        
        let typeContext = getWorkspaceTypeContext(type)
        let conversationContext = context.suffix(5).map { $0.content }.joined(separator: "\n")
        
        var contextualPrompt = ""
        
        if !conversationContext.isEmpty {
            contextualPrompt += "Previous conversation:\n\(conversationContext)\n\n"
        }
        
        contextualPrompt += "Context: \(typeContext)\n\nUser request: \(prompt)"
        
        return contextualPrompt
    }
    
    private func getWorkspaceTypeContext(_ type: WorkspaceManager.WorkspaceType) -> String {
        switch type {
        case .code:
            return "Software development and coding assistance"
        case .research:
            return "Research analysis and academic work"
        case .creative:
            return "Creative writing and content development"
        case .business:
            return "Business strategy and professional analysis"
        case .general:
            return "General conversation and assistance"
        }
    }
    
    private func generateResponseTemplate(
        prompt: String,
        type: WorkspaceManager.WorkspaceType,
        confidence: Double
    ) -> String {
        
        // This is a placeholder that would be replaced with actual PRISM inference
        let confidenceIndicator = confidence > responseConfidenceThreshold ? "High confidence" : "Moderate confidence"
        
        return """
        [PRISM Response Template - \(type.rawValue)]
        Confidence: \(confidenceIndicator) (\(String(format: "%.1f", confidence * 100))%)
        
        Based on your \(type.rawValue) workspace context, I understand you're asking about:
        \(prompt)
        
        [This is a placeholder response that would be generated by the full PRISM ensemble system]
        
        Key insights:
        • Contextual understanding: ✓
        • Workspace type detected: \(type.rawValue)
        • Analysis confidence: \(String(format: "%.1f", confidence * 100))%
        
        [In the full implementation, this would be replaced with actual model inference]
        """
    }
    
    // MARK: - Utility Methods
    
    func extractKeywords(from content: String) -> [String] {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                return cleaned.count > 3 && !isStopWord(cleaned) ? cleaned.capitalized : nil
            }
        
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return wordCounts.prefix(5).map { $0.key }
    }
    
    func extractPrimaryContext(from content: String) -> String? {
        let contextPatterns = [
            "API (\\w+)",
            "(\\w+) authentication",
            "(\\w+) database",
            "(React|Vue|Angular) (\\w+)",
            "(iOS|Android|mobile) (\\w+)",
            "(\\w+) story",
            "(\\w+) article",
            "(\\w+) campaign",
            "(\\w+) brand",
            "(\\w+) research",
            "(\\w+) analysis",
            "(\\w+) study",
            "(\\w+) project",
            "(\\w+) system",
            "(\\w+) platform"
        ]
        
        for pattern in contextPatterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: range) {
                let matchRange = Range(match.range, in: content)!
                let matchedText = String(content[matchRange])
                return matchedText
                    .components(separatedBy: .whitespacesAndNewlines)
                    .first { !isStopWord($0.lowercased()) }
            }
        }
        
        return nil
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set([
            "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
            "from", "up", "about", "into", "through", "during", "before", "after", "above",
            "below", "between", "among", "this", "that", "these", "those", "i", "you", "he",
            "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his",
            "her", "its", "our", "their", "myself", "yourself", "himself", "herself", "itself",
            "ourselves", "yourselves", "themselves", "what", "which", "who", "whom", "whose",
            "where", "when", "why", "how", "all", "any", "both", "each", "few", "more", "most",
            "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than",
            "too", "very", "can", "will", "just", "should", "now"
        ])
        
        return stopWords.contains(word.lowercased())
    }
}

// MARK: - Supporting Types

struct PromptAnalysisResult {
    let detectedType: WorkspaceManager.WorkspaceType
    let confidence: Double
    let keywords: [String]
    let primaryContext: String?
}

// MARK: - Workspace Type Extension

extension WorkspaceManager.WorkspaceType {
    var displayName: String {
        switch self {
        case .code:
            return "Development"
        case .research:
            return "Research"
        case .creative:
            return "Creative"
        case .business:
            return "Business"
        case .general:
            return "General"
        }
    }
    
    var emoji: String {
        switch self {
        case .code:
            return "💻"
        case .research:
            return "🔬"
        case .creative:
            return "🎨"
        case .business:
            return "📊"
        case .general:
            return "💬"
        }
    }
    
    var description: String {
        switch self {
        case .code:
            return "Software development, programming, and technical projects"
        case .research:
            return "Research analysis, academic work, and data investigation"
        case .creative:
            return "Creative writing, content development, and artistic projects"
        case .business:
            return "Business strategy, professional analysis, and corporate planning"
        case .general:
            return "General conversations and multi-purpose discussions"
        }
    }
}
