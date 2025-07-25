//
// IntelligenceEngine+EnhancedWorkspaceGeneration.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

extension IntelligenceEngine {
    
    // MARK: - Intelligent Workspace Title Generation
    
    func generateIntelligentWorkspaceTitle(from conversationContent: String) -> String {
        let keywords = extractKeywords(from: conversationContent)
        let primaryContext = extractPrimaryContext(from: conversationContent)
        // Use the existing detectWorkspaceType method from IntelligenceEngine
        let detectedType = detectWorkspaceType(from: conversationContent)
        
        if let context = primaryContext {
            return generateContextualTitle(context: context, type: detectedType, keywords: keywords)
        } else if let primaryKeyword = keywords.first {
            return generateKeywordBasedTitle(keyword: primaryKeyword, type: detectedType)
        } else {
            return generateFallbackTitle(type: detectedType)
        }
    }
    
    private func generateContextualTitle(context: String, type: WorkspaceManager.WorkspaceType, keywords: [String]) -> String {
        let cleanContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch type {
        case .code:
            if cleanContext.localizedCaseInsensitiveContains("API") {
                return "\(extractAPIContext(from: cleanContext)) API"
            } else if cleanContext.localizedCaseInsensitiveContains("authentication") || cleanContext.localizedCaseInsensitiveContains("auth") {
                return "Authentication System"
            } else if cleanContext.localizedCaseInsensitiveContains("database") || cleanContext.localizedCaseInsensitiveContains("DB") {
                return "Database Development"
            } else {
                return "\(cleanContext.capitalized) Development"
            }
        case .creative:
            return "\(cleanContext.capitalized) Creative Project"
        case .research:
            return "\(cleanContext.capitalized) Research"
        case .general:
            return "\(cleanContext.capitalized) Discussion"
        }
    }
    
    private func generateKeywordBasedTitle(keyword: String, type: WorkspaceManager.WorkspaceType) -> String {
        switch type {
        case .code:
            return "\(keyword.capitalized) Development"
        case .creative:
            return "\(keyword.capitalized) Creative Work"
        case .research:
            return "\(keyword.capitalized) Research"
        case .general:
            return "\(keyword.capitalized) Project"
        }
    }
    
    private func generateFallbackTitle(type: WorkspaceManager.WorkspaceType) -> String {
        switch type {
        case .code:
            return "Development Project"
        case .creative:
            return "Creative Project"
        case .research:
            return "Research Project"
        case .general:
            return "General Project"
        }
    }
    
    // MARK: - Intelligent Workspace Description Generation
    
    func generateIntelligentWorkspaceDescription(from messages: [ChatMessage]) -> String {
        let userContent = messages
            .filter { $0.isFromUser }  // Fixed: Use isFromUser instead of role
            .map { $0.content }
            .joined(separator: " ")
        
        let summary = generateConversationSummary(from: messages)
        let mainTopics = extractMainTopics(from: userContent)
        // Use the existing detectWorkspaceType method from IntelligenceEngine
        let detectedType = detectWorkspaceType(from: userContent)
        
        let purposeStatement = generatePurposeStatement(type: detectedType, topics: mainTopics)
        
        if !summary.isEmpty && !mainTopics.isEmpty {
            return "Workspace for \(summary.lowercased()). \(purposeStatement) Key focus areas: \(mainTopics.joined(separator: ", "))."
        } else if !summary.isEmpty {
            return "Workspace for \(summary.lowercased()). \(purposeStatement)"
        } else {
            return purposeStatement
        }
    }
    
    private func generatePurposeStatement(type: WorkspaceManager.WorkspaceType, topics: [String]) -> String {
        switch type {
        case .code:
            return "Ideal for tracking technical solutions, code reviews, and development discussions."
        case .creative:
            return "Perfect for brainstorming, content creation, and creative collaboration."
        case .research:
            return "Designed for organizing findings, analysis, and research documentation."
        case .general:
            return "Organized space for ongoing discussions and collaborative thinking."
        }
    }
    
    // MARK: - Enhanced Content Analysis
    
    func extractKeywords(from content: String) -> [String] {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .compactMap { word in
                let cleaned = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                return cleaned.count > 3 && !isStopWord(cleaned) ? cleaned : nil
            }
        
        return Array(Set(words)).sorted { word1, word2 in
            content.lowercased().components(separatedBy: word1).count >
            content.lowercased().components(separatedBy: word2).count
        }.prefix(10).map { $0 }
    }
    
    func extractMainTopics(from content: String) -> [String] {
        let keywords = extractKeywords(from: content)
        let topicGroups = [
            "Technology": ["swift", "code", "programming", "development", "app", "ios", "web", "api", "database"],
            "Creative": ["writing", "design", "creative", "story", "content", "art", "music", "video"],
            "Business": ["business", "strategy", "marketing", "sales", "finance", "management", "planning"],
            "Research": ["research", "analysis", "study", "data", "science", "investigation", "report"]
        ]
        
        var detectedTopics: [String] = []
        
        for (topic, relatedWords) in topicGroups {
            let matches = keywords.filter { keyword in
                relatedWords.contains { keyword.contains($0) || $0.contains(keyword) }
            }
            if matches.count >= 2 {
                detectedTopics.append(topic)
            }
        }
        
        return detectedTopics.isEmpty ? Array(keywords.prefix(3)) : detectedTopics
    }
    
    func generateConversationSummary(from messages: [ChatMessage]) -> String {
        let userMessages = messages.filter { $0.isFromUser }  // Fixed: Use isFromUser
        guard !userMessages.isEmpty else { return "" }
        
        let combinedContent = userMessages.map { $0.content }.joined(separator: " ")
        let keywords = extractKeywords(from: combinedContent)
        
        if let primaryKeyword = keywords.first {
            return "discussion about \(primaryKeyword)"
        } else {
            return "general conversation"
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractPrimaryContext(from content: String) -> String? {
        let sentences = content.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 10 }
        
        return sentences.first
    }
    
    private func extractAPIContext(from content: String) -> String {
        let patterns = ["REST API", "GraphQL", "API", "endpoint", "service"]
        for pattern in patterns {
            if content.localizedCaseInsensitiveContains(pattern) {
                return pattern
            }
        }
        return "API"
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = Set([
            "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
            "from", "up", "about", "into", "through", "during", "before", "after", "above",
            "below", "between", "among", "throughout", "despite", "towards", "upon", "concerning",
            "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they",
            "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their",
            "myself", "yourself", "himself", "herself", "itself", "ourselves", "yourselves", "themselves",
            "what", "which", "who", "whom", "whose", "where", "when", "why", "how",
            "all", "any", "both", "each", "few", "more", "most", "other", "some", "such",
            "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very",
            "can", "will", "just", "should", "now", "said", "get", "made", "go", "see"
        ])
        return stopWords.contains(word.lowercased())
    }
}
