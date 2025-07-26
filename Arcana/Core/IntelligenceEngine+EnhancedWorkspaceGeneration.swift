//
// IntelligenceEngine+EnhancedWorkspaceGeneration.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, WorkspaceManager.swift, IntelligenceEngine.swift

import Foundation

extension IntelligenceEngine {
    
    // MARK: - Intelligent Workspace Title Generation
    
    func generateIntelligentWorkspaceTitle(from conversationContent: String) async -> String {
        let keywords = await extractKeywords(from: conversationContent)
        let primaryContext = extractPrimaryContext(from: conversationContent)
        let detectedType = await detectWorkspaceType(from: conversationContent)
        
        if let context = primaryContext {
            return generateContextualTitle(context: context, type: detectedType, keywords: keywords)
        } else if let primaryKeyword = keywords.first {
            return generateKeywordBasedTitle(keyword: primaryKeyword, type: detectedType)
        } else {
            return generateFallbackTitle(type: detectedType)
        }
    }
    
    // MARK: - Missing Method Implementations
    
    func extractPrimaryContext(from content: String) -> String? {
        // Extract the primary context from conversational content
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 10 }
        
        // Look for sentences that contain key context indicators
        let contextIndicators = [
            "working on", "building", "creating", "developing", "designing",
            "need help", "trying to", "want to", "planning", "researching"
        ]
        
        for sentence in sentences {
            for indicator in contextIndicators {
                if sentence.localizedCaseInsensitiveContains(indicator) {
                    // Extract the context after the indicator
                    if let range = sentence.range(of: indicator, options: .caseInsensitive) {
                        let context = String(sentence[range.upperBound...])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if context.count > 5 {
                            return context
                        }
                    }
                }
            }
        }
        
        // If no specific context found, return the first substantial sentence
        return sentences.first
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
            return "\(keyword.capitalized) Discussion"
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
            return "General Discussion"
        }
    }
    
    // MARK: - Enhanced Workspace Description Generation
    
    func generateIntelligentWorkspaceDescription(from messages: [ChatMessage]) async -> String {
        guard !messages.isEmpty else {
            return "A new workspace for organizing your conversations and ideas."
        }
        
        let userContent = messages
            .filter { $0.role == .user }
            .map { $0.content }
            .joined(separator: " ")
        
        let detectedType = await detectWorkspaceType(from: userContent)
        let topics = await extractMainTopics(from: userContent)
        
        return generatePurposeStatement(type: detectedType, topics: topics)
    }
    
    private func generatePurposeStatement(type: WorkspaceManager.WorkspaceType, topics: [String]) -> String {
        let topicsText = topics.isEmpty ? "" : " focused on \(topics.joined(separator: ", "))"
        
        switch type {
        case .code:
            return "Development workspace for coding projects and technical discussions\(topicsText)."
        case .creative:
            return "Creative workspace for brainstorming, content creation, and artistic collaboration\(topicsText)."
        case .research:
            return "Research workspace for organizing findings, analysis, and documentation\(topicsText)."
        case .general:
            return "General workspace for ongoing discussions and collaborative thinking\(topicsText)."
        }
    }
    
    // MARK: - Enhanced Content Analysis
    
    func extractMainTopics(from content: String) async -> [String] {
        let keywords = await extractKeywords(from: content)
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
    
    func generateConversationSummary(from messages: [ChatMessage]) async -> String {
        let userMessages = messages.filter { $0.role == .user }
        guard !userMessages.isEmpty else { return "Empty conversation" }
        
        let combinedContent = userMessages.map { $0.content }.joined(separator: " ")
        let keywords = await extractKeywords(from: combinedContent)
        
        if let primaryKeyword = keywords.first {
            return "Discussion about \(primaryKeyword.lowercased())"
        } else {
            return "General conversation"
        }
    }
    
    // MARK: - Workspace Organization Intelligence
    
    func generateWorkspaceOrganizationSuggestions(
        for workspaces: [Project],
        based conversationPattern: String
    ) async -> [WorkspaceOrganizationSuggestion] {
        
        var suggestions: [WorkspaceOrganizationSuggestion] = []
        
        for workspace in workspaces {
            let workspaceType = await detectWorkspaceType(from: workspace.description)
            
            // Suggest consolidation for similar workspaces
            let similarWorkspaces = workspaces.filter { otherWorkspace in
                otherWorkspace.id != workspace.id &&
                await areSimilarWorkspaces(workspace, otherWorkspace)
            }
            
            if similarWorkspaces.count >= 2 {
                suggestions.append(WorkspaceOrganizationSuggestion(
                    type: .consolidation,
                    title: "Consolidate Similar Workspaces",
                    description: "Consider merging \(workspace.title) with \(similarWorkspaces.count) similar workspaces",
                    workspaces: [workspace] + similarWorkspaces,
                    priority: .medium
                ))
            }
            
            // Suggest workspace splitting for overly broad workspaces
            if workspace.description.count > 500 {
                suggestions.append(WorkspaceOrganizationSuggestion(
                    type: .splitting,
                    title: "Split Broad Workspace",
                    description: "Consider splitting '\(workspace.title)' into more focused workspaces",
                    workspaces: [workspace],
                    priority: .low
                ))
            }
        }
        
        return suggestions
    }
    
    private func areSimilarWorkspaces(_ workspace1: Project, _ workspace2: Project) async -> Bool {
        let content1 = "\(workspace1.title) \(workspace1.description)"
        let content2 = "\(workspace2.title) \(workspace2.description)"
        
        let keywords1 = Set(await extractKeywords(from: content1))
        let keywords2 = Set(await extractKeywords(from: content2))
        
        let commonKeywords = keywords1.intersection(keywords2)
        let totalKeywords = keywords1.union(keywords2)
        
        guard !totalKeywords.isEmpty else { return false }
        
        let similarity = Double(commonKeywords.count) / Double(totalKeywords.count)
        return similarity > 0.4
    }
    
    // MARK: - Helper Methods
    
    private func extractAPIContext(from content: String) -> String {
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
            "frontend", "backend", "database", "server", "client"
        ]
        
        return technicalPatterns.filter { term in
            content.localizedCaseInsensitiveContains(term)
        }
    }
    
    // MARK: - Quality Assessment Integration
    
    func assessWorkspaceQuality(_ workspace: Project) async -> WorkspaceQualityAssessment {
        let contentDepth = calculateWorkspaceContentDepth(workspace)
        let organizationScore = calculateOrganizationScore(workspace)
        let usageFrequency = calculateUsageFrequency(workspace)
        
        return WorkspaceQualityAssessment(
            workspaceId: workspace.id,
            contentDepth: contentDepth,
            organizationScore: organizationScore,
            usageFrequency: usageFrequency,
            overallScore: (contentDepth + organizationScore + usageFrequency) / 3.0,
            recommendations: generateQualityRecommendations(
                depth: contentDepth,
                organization: organizationScore,
                usage: usageFrequency
            )
        )
    }
    
    private func calculateWorkspaceContentDepth(_ workspace: Project) -> Double {
        let totalLength = workspace.title.count + workspace.description.count
        return min(Double(totalLength) / 500.0, 1.0)
    }
    
    private func calculateOrganizationScore(_ workspace: Project) -> Double {
        var score = 0.0
        
        // Title quality
        if !workspace.title.isEmpty && workspace.title.count > 5 {
            score += 0.3
        }
        
        // Description quality
        if !workspace.description.isEmpty && workspace.description.count > 20 {
            score += 0.4
        }
        
        // Specific workspace type indicator
        if workspace.isPinned {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func calculateUsageFrequency(_ workspace: Project) -> Double {
        let daysSinceModified = Date().timeIntervalSince(workspace.lastModified) / (24 * 60 * 60)
        
        if daysSinceModified < 1 {
            return 1.0
        } else if daysSinceModified < 7 {
            return 0.8
        } else if daysSinceModified < 30 {
            return 0.5
        } else {
            return 0.2
        }
    }
    
    private func generateQualityRecommendations(depth: Double, organization: Double, usage: Double) -> [String] {
        var recommendations: [String] = []
        
        if depth < 0.5 {
            recommendations.append("Add more detailed description to improve workspace context")
        }
        
        if organization < 0.6 {
            recommendations.append("Consider pinning this workspace if it's frequently used")
        }
        
        if usage < 0.3 {
            recommendations.append("This workspace hasn't been used recently - consider archiving or updating")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Data Structures

struct WorkspaceOrganizationSuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let workspaces: [Project]
    let priority: Priority
    
    enum SuggestionType {
        case consolidation
        case splitting
        case reorganization
        case archiving
    }
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct WorkspaceQualityAssessment {
    let workspaceId: UUID
    let contentDepth: Double
    let organizationScore: Double
    let usageFrequency: Double
    let overallScore: Double
    let recommendations: [String]
    
    var qualityTier: QualityTier {
        switch overallScore {
        case 0.9...1.0: return .exceptional
        case 0.8..<0.9: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .acceptable
        default: return .poor
        }
    }
}
