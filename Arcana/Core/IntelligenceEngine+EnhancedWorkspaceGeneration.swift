// IntelligenceEngine+EnhancedWorkspaceGeneration.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

extension IntelligenceEngine {
    
    // MARK: - Intelligent Workspace Title Generation
    
    func generateIntelligentWorkspaceTitle(from conversationContent: String) -> String {
        let keywords = extractKeywords(from: conversationContent)
        let primaryContext = extractPrimaryContext(from: conversationContent)
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
            } else if cleanContext.localizedCaseInsensitiveContains("react") {
                return "React Development"
            } else if cleanContext.localizedCaseInsensitiveContains("mobile") || cleanContext.localizedCaseInsensitiveContains("iOS") || cleanContext.localizedCaseInsensitiveContains("Android") {
                return "Mobile App Development"
            } else {
                return "\(cleanContext.capitalized) Development"
            }
            
        case .creative:
            if cleanContext.localizedCaseInsensitiveContains("story") || cleanContext.localizedCaseInsensitiveContains("narrative") {
                return "\(cleanContext.capitalized) Story"
            } else if cleanContext.localizedCaseInsensitiveContains("article") || cleanContext.localizedCaseInsensitiveContains("blog") {
                return "\(cleanContext.capitalized) Writing"
            } else if cleanContext.localizedCaseInsensitiveContains("marketing") || cleanContext.localizedCaseInsensitiveContains("campaign") {
                return "\(cleanContext.capitalized) Campaign"
            } else {
                return "\(cleanContext.capitalized) Creative Project"
            }
            
        case .research:
            if cleanContext.localizedCaseInsensitiveContains("market") {
                return "\(cleanContext.capitalized) Market Research"
            } else if cleanContext.localizedCaseInsensitiveContains("user") || cleanContext.localizedCaseInsensitiveContains("customer") {
                return "\(cleanContext.capitalized) User Research"
            } else {
                return "\(cleanContext.capitalized) Research"
            }
            
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
            .filter { $0.role == .user }
            .map { $0.content }
            .joined(separator: " ")
        
        let summary = generateConversationSummary(from: messages)
        let mainTopics = extractMainTopics(from: userContent)
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
            if let match = content.firstMatch(of: regex),
               let range = match.range(in: content) {
                let matchedText = String(content[range])
                return matchedText
                    .components(separatedBy: .whitespacesAndNewlines)
                    .first { !isStopWord($0.lowercased()) }
            }
        }
        
        return nil
    }
    
    func extractMainTopics(from content: String) -> [String] {
        let keywords = extractKeywords(from: content)
        let technicalTerms = extractTechnicalTerms(from: content)
        let conceptualTerms = extractConceptualTerms(from: content)
        
        let allTerms = Set(keywords + technicalTerms + conceptualTerms)
        return Array(allTerms).prefix(4).map { String($0) }
    }
    
    private func extractTechnicalTerms(from content: String) -> [String] {
        let technicalPatterns = [
            "API", "REST", "GraphQL", "JWT", "OAuth", "SQL", "NoSQL",
            "React", "Vue", "Angular", "Node", "Express", "MongoDB",
            "authentication", "authorization", "encryption", "security",
            "frontend", "backend", "database", "server", "client",
            "iOS", "Android", "mobile", "responsive", "performance"
        ]
        
        return technicalPatterns.filter {
            content.localizedCaseInsensitiveContains($0)
        }.map { $0.capitalized }
    }
    
    private func extractConceptualTerms(from content: String) -> [String] {
        let conceptualPatterns = [
            "user experience", "user interface", "workflow", "process",
            "strategy", "planning", "optimization", "integration",
            "scalability", "maintainability", "accessibility", "usability",
            "branding", "marketing", "content", "storytelling",
            "research", "analysis", "insights", "findings"
        ]
        
        return conceptualPatterns.filter {
            content.localizedCaseInsensitiveContains($0)
        }.map { $0.capitalized }
    }
    
    func generateConversationSummary(from messages: [ChatMessage]) -> String {
        let userMessages = messages.filter { $0.role == .user }
        guard !userMessages.isEmpty else { return "" }
        
        let allContent = userMessages.map { $0.content }.joined(separator: " ")
        let mainTopics = extractMainTopics(from: allContent)
        
        if mainTopics.count >= 2 {
            return "discussing \(mainTopics[0].lowercased()) and \(mainTopics[1].lowercased())"
        } else if let firstTopic = mainTopics.first {
            return "working on \(firstTopic.lowercased())"
        } else {
            return "collaborative problem-solving"
        }
    }
    
    private func extractAPIContext(from content: String) -> String {
        if content.localizedCaseInsensitiveContains("authentication") {
            return "Authentication"
        } else if content.localizedCaseInsensitiveContains("payment") {
            return "Payment"
        } else if content.localizedCaseInsensitiveContains("user") {
            return "User"
        } else if content.localizedCaseInsensitiveContains("data") {
            return "Data"
        } else {
            return "Service"
        }
    }
    
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "and", "for", "are", "but", "not", "you", "all", "can", "had",
            "her", "was", "one", "our", "out", "day", "get", "has", "him", "his",
            "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy",
            "did", "what", "with", "have", "this", "will", "been", "from", "they",
            "she", "when", "where", "why", "some", "that", "there", "their", "would",
            "like", "into", "time", "very", "only", "just", "then", "than", "also",
            "back", "after", "first", "well", "way", "even", "want", "because",
            "these", "give", "most", "us"
        ]
        return stopWords.contains(word.lowercased())
    }
}

// MARK: - Regex Helpers

extension String {
    func firstMatch(of regex: NSRegularExpression) -> NSTextCheckingResult? {
        regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
    }
}

extension NSTextCheckingResult {
    func range(in string: String) -> Range<String.Index>? {
        Range(self.range, in: string)
    }
}
