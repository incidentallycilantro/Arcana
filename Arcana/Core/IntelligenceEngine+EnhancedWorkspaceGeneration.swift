//
// IntelligenceEngine+EnhancedWorkspaceGeneration.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//

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
            .filter { $0.isFromUser }
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
    
    // MARK: - Enhanced Content Analysis (Non-duplicate methods)
    
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
                relatedWords.contains { keyword.lowercased().contains($0) || $0.contains(keyword.lowercased()) }
            }
            if matches.count >= 2 {
                detectedTopics.append(topic)
            }
        }
        
        return detectedTopics.isEmpty ? Array(keywords.prefix(3)) : detectedTopics
    }
    
    func generateConversationSummary(from messages: [ChatMessage]) -> String {
        let userMessages = messages.filter { $0.isFromUser }
        guard !userMessages.isEmpty else { return "" }
        
        let combinedContent = userMessages.map { $0.content }.joined(separator: " ")
        let keywords = extractKeywords(from: combinedContent)
        
        if let primaryKeyword = keywords.first {
            return "discussion about \(primaryKeyword.lowercased())"
        } else {
            return "general conversation"
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractAPIContext(from content: String) -> String {
        // Extract API-related context
        let patterns = ["REST", "GraphQL", "JSON", "HTTP", "POST", "GET", "PUT", "DELETE"]
        
        for pattern in patterns {
            if content.localizedCaseInsensitiveContains(pattern) {
                return pattern
            }
        }
        
        return "Web"
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
        }
    }
    
    private func extractConceptualTerms(from content: String) -> [String] {
        let conceptualPatterns = [
            "design", "architecture", "pattern", "framework", "methodology",
            "strategy", "approach", "solution", "implementation", "optimization",
            "analysis", "evaluation", "assessment", "planning", "development"
        ]
        
        return conceptualPatterns.filter {
            content.localizedCaseInsensitiveContains($0)
        }
    }
    
    // MARK: - Workspace Type Specific Enhancements
    
    func enhanceForCodeWorkspace(content: String) -> [String] {
        let codeIndicators = extractTechnicalTerms(from: content)
        let languages = ["Swift", "JavaScript", "Python", "Java", "C++", "Go", "Rust"]
        let detectedLanguages = languages.filter { content.localizedCaseInsensitiveContains($0) }
        
        return codeIndicators + detectedLanguages
    }
    
    func enhanceForCreativeWorkspace(content: String) -> [String] {
        let creativeIndicators = ["story", "narrative", "character", "plot", "design", "brand", "campaign", "content", "writing"]
        return creativeIndicators.filter { content.localizedCaseInsensitiveContains($0) }
    }
    
    func enhanceForResearchWorkspace(content: String) -> [String] {
        let researchIndicators = ["study", "analysis", "data", "findings", "methodology", "hypothesis", "experiment", "survey"]
        return researchIndicators.filter { content.localizedCaseInsensitiveContains($0) }
    }
    
    func enhanceForBusinessWorkspace(content: String) -> [String] {
        let businessIndicators = ["strategy", "market", "revenue", "customer", "growth", "planning", "metrics", "ROI"]
        return businessIndicators.filter { content.localizedCaseInsensitiveContains($0) }
    }
}

// MARK: - Workspace Enhancement Utilities

extension IntelligenceEngine {
    
    /// Generate smart suggestions for workspace organization
    func generateWorkspaceOrganizationSuggestions(
        for workspace: Project,
        based messages: [ChatMessage]
    ) -> [WorkspaceOrganizationSuggestion] {
        
        let workspaceType = detectWorkspaceType(from: workspace.description)
        let conversationPatterns = analyzeConversationPatterns(messages)
        
        var suggestions: [WorkspaceOrganizationSuggestion] = []
        
        // Suggest thread organization
        if messages.count > 20 {
            suggestions.append(WorkspaceOrganizationSuggestion(
                type: .threadOrganization,
                title: "Consider organizing into sub-threads",
                description: "Your conversation has grown quite long. Consider breaking it into focused sub-threads.",
                priority: .medium
            ))
        }
        
        // Suggest related workspace creation
        if conversationPatterns.topicDiversity > 0.7 {
            suggestions.append(WorkspaceOrganizationSuggestion(
                type: .relatedWorkspace,
                title: "Multiple topics detected",
                description: "Consider creating separate workspaces for different discussion topics.",
                priority: .high
            ))
        }
        
        // Type-specific suggestions
        switch workspaceType {
        case .code:
            if conversationPatterns.hasCodeBlocks {
                suggestions.append(WorkspaceOrganizationSuggestion(
                    type: .codeOrganization,
                    title: "Code snippet organization",
                    description: "Consider creating a code reference section for easy access to discussed solutions.",
                    priority: .medium
                ))
            }
        case .research:
            if conversationPatterns.hasExternalReferences {
                suggestions.append(WorkspaceOrganizationSuggestion(
                    type: .referenceOrganization,
                    title: "Reference management",
                    description: "Consider organizing external references and sources for easy citation.",
                    priority: .medium
                ))
            }
        default:
            break
        }
        
        return suggestions
    }
    
    private func analyzeConversationPatterns(_ messages: [ChatMessage]) -> ConversationPatterns {
        let topics = extractMainTopics(from: messages.map { $0.content }.joined(separator: " "))
        let uniqueTopics = Set(topics)
        let topicDiversity = Double(uniqueTopics.count) / max(Double(topics.count), 1.0)
        
        let allContent = messages.map { $0.content }.joined(separator: " ")
        let hasCodeBlocks = allContent.contains("```") || allContent.contains("func ") || allContent.contains("class ")
        let hasExternalReferences = allContent.contains("http") || allContent.contains("www") || allContent.contains(".com")
        
        return ConversationPatterns(
            topicDiversity: topicDiversity,
            hasCodeBlocks: hasCodeBlocks,
            hasExternalReferences: hasExternalReferences
        )
    }
}

// MARK: - Supporting Types

struct WorkspaceOrganizationSuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Priority
    
    enum SuggestionType {
        case threadOrganization
        case relatedWorkspace
        case codeOrganization
        case referenceOrganization
    }
    
    enum Priority {
        case low, medium, high
    }
}

struct ConversationPatterns {
    let topicDiversity: Double
    let hasCodeBlocks: Bool
    let hasExternalReferences: Bool
}
