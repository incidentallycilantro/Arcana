//
// IntelligenceEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, WorkspaceManager.swift
//

import Foundation
import SwiftUI
import OSLog

@MainActor
class IntelligenceEngine: ObservableObject {
    // MARK: - Singleton Pattern
    static let shared = IntelligenceEngine()
    
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
        let analysisResult = await analyzePromptIntelligence(prompt, context: context)
        
        // 2. Generate appropriate response based on workspace type
        let response = await generateIntelligentResponse(
            prompt: prompt,
            context: context,
            detectedType: analysisResult.detectedType,
            confidence: analysisResult.confidence
        )
        
        // 3. Update state
        lastGeneratedResponse = response
        confidenceScore = analysisResult.confidence
        currentWorkspaceType = analysisResult.detectedType
        
        return response
    }
    
    // MARK: - Workspace Type Detection
    
    func detectWorkspaceType(from content: String) async -> WorkspaceManager.WorkspaceType {
        logger.info("🔍 Detecting workspace type from content")
        
        guard content.count >= minimumContextLength else {
            return .general
        }
        
        let contentLower = content.lowercased()
        
        // Code detection patterns
        let codePatterns = [
            "function", "class", "import", "export", "const", "let", "var",
            "return", "if", "else", "for", "while", "switch", "case",
            "def", "class", "import", "from", "return", "if", "elif", "else",
            "public", "private", "static", "async", "await", "try", "catch",
            "git", "commit", "merge", "pull", "push", "branch", "repository",
            "api", "endpoint", "request", "response", "http", "https",
            "database", "sql", "query", "table", "column", "index"
        ]
        
        // Creative detection patterns
        let creativePatterns = [
            "story", "character", "plot", "narrative", "dialogue", "scene",
            "chapter", "draft", "write", "writing", "creative", "fiction",
            "poetry", "poem", "verse", "rhyme", "metaphor", "imagery",
            "design", "color", "font", "layout", "visual", "aesthetic",
            "brand", "logo", "marketing", "campaign", "content", "copy"
        ]
        
        // Research detection patterns
        let researchPatterns = [
            "research", "study", "analysis", "data", "findings", "hypothesis",
            "methodology", "experiment", "survey", "interview", "observation",
            "literature", "review", "citation", "reference", "bibliography",
            "thesis", "dissertation", "paper", "publication", "journal",
            "statistics", "correlation", "causation", "significant", "p-value"
        ]
        
        let codeScore = calculatePatternScore(content: contentLower, patterns: codePatterns)
        let creativeScore = calculatePatternScore(content: contentLower, patterns: creativePatterns)
        let researchScore = calculatePatternScore(content: contentLower, patterns: researchPatterns)
        
        let maxScore = max(codeScore, creativeScore, researchScore)
        
        if maxScore < workspaceTypeThreshold {
            return .general
        }
        
        switch maxScore {
        case codeScore:
            return .code
        case creativeScore:
            return .creative
        case researchScore:
            return .research
        default:
            return .general
        }
    }
    
    // MARK: - Intelligent Content Generation
    
    func generateIntelligentWorkspaceTitle(from content: String) async -> String {
        logger.info("📝 Generating intelligent workspace title")
        
        let keywords = await extractKeywords(from: content)
        let topKeywords = Array(keywords.prefix(3))
        
        if topKeywords.isEmpty {
            return "New Workspace"
        }
        
        // Create a meaningful title from keywords
        let title = topKeywords.joined(separator: " & ").capitalized
        return title.count > 50 ? String(title.prefix(47)) + "..." : title
    }
    
    func generateIntelligentWorkspaceDescription(from messages: [ChatMessage]) async -> String {
        logger.info("📋 Generating intelligent workspace description")
        
        guard !messages.isEmpty else {
            return "A new workspace for organizing your conversations and ideas."
        }
        
        let userMessages = messages.filter { $0.isFromUser }
        let allContent = userMessages.map { $0.content }.joined(separator: " ")
        
        if allContent.count > 200 {
            return String(allContent.prefix(197)) + "..."
        }
        
        return allContent.isEmpty ? "A new workspace for organizing your conversations and ideas." : allContent
    }
    
    func generateConversationSummary(from messages: [ChatMessage]) async -> String {
        logger.info("📊 Generating conversation summary")
        
        guard !messages.isEmpty else {
            return "No conversation to summarize."
        }
        
        let messageCount = messages.count
        let userMessageCount = messages.filter { $0.isFromUser }.count
        let assistantMessageCount = messageCount - userMessageCount
        
        let lastUserMessage = messages.last { $0.isFromUser }?.content ?? "No user messages"
        let preview = lastUserMessage.count > 100 ? String(lastUserMessage.prefix(97)) + "..." : lastUserMessage
        
        return """
        Conversation with \(messageCount) messages (\(userMessageCount) from user, \(assistantMessageCount) from assistant).
        Latest topic: \(preview)
        """
    }
    
    func extractKeywords(from content: String) async -> [String] {
        logger.info("🔑 Extracting keywords from content")
        
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 3 }
            .map { $0.lowercased() }
        
        // Filter out common words
        let commonWords = Set([
            "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy", "did", "man", "men", "oil", "sit", "way", "what", "when", "with", "this", "that", "have", "from", "they", "know", "want", "been", "good", "much", "some", "time", "very", "when", "come", "here", "just", "like", "long", "make", "many", "over", "such", "take", "than", "them", "well", "were"
        ])
        
        let keywords = words.filter { !commonWords.contains($0) }
        
        // Return top keywords by frequency
        let frequency = Dictionary(grouping: keywords, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(frequency.prefix(10).map { $0.key })
    }
    
    // MARK: - Private Helper Methods
    
    private func analyzePromptIntelligence(_ prompt: String, context: [ChatMessage]) async -> AnalysisResult {
        let detectedType = await detectWorkspaceType(from: prompt)
        let confidence = calculateConfidence(for: prompt, context: context)
        
        return AnalysisResult(
            detectedType: detectedType,
            confidence: confidence,
            keywords: await extractKeywords(from: prompt)
        )
    }
    
    private func generateIntelligentResponse(
        prompt: String,
        context: [ChatMessage],
        detectedType: WorkspaceManager.WorkspaceType,
        confidence: Double
    ) async -> String {
        
        // This is a placeholder for the actual AI response generation
        // In the real implementation, this would integrate with the PRISM engine
        switch detectedType {
        case .code:
            return generateCodeResponse(for: prompt, context: context)
        case .creative:
            return generateCreativeResponse(for: prompt, context: context)
        case .research:
            return generateResearchResponse(for: prompt, context: context)
        case .general:
            return generateGeneralResponse(for: prompt, context: context)
        }
    }
    
    private func calculatePatternScore(content: String, patterns: [String]) -> Double {
        let matches = patterns.filter { content.contains($0) }.count
        return Double(matches) / Double(patterns.count)
    }
    
    private func calculateConfidence(for prompt: String, context: [ChatMessage]) -> Double {
        // Simple confidence calculation based on prompt length and context
        let promptScore = min(Double(prompt.count) / 100.0, 1.0)
        let contextScore = min(Double(context.count) / 10.0, 1.0)
        return (promptScore + contextScore) / 2.0
    }
    
    // MARK: - Response Generation by Type
    
    private func generateCodeResponse(for prompt: String, context: [ChatMessage]) -> String {
        return "I'll help you with that code-related question. Let me analyze the requirements and provide a solution..."
    }
    
    private func generateCreativeResponse(for prompt: String, context: [ChatMessage]) -> String {
        return "That's an interesting creative challenge! Let me help you explore some ideas and possibilities..."
    }
    
    private func generateResearchResponse(for prompt: String, context: [ChatMessage]) -> String {
        return "Great research question! Let me help you approach this systematically and find reliable information..."
    }
    
    private func generateGeneralResponse(for prompt: String, context: [ChatMessage]) -> String {
        return "I understand what you're asking. Let me provide you with a helpful and comprehensive response..."
    }
}

// MARK: - Supporting Types

private struct AnalysisResult {
    let detectedType: WorkspaceManager.WorkspaceType
    let confidence: Double
    let keywords: [String]
}
