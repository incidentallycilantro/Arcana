// IntelligenceEngine+ThreadSupport.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

// MARK: - Thread Support Extension for IntelligenceEngine
extension IntelligenceEngine {
    
    // MARK: - Thread-Safe Context Analysis
    
    func analyzeThreadContext(
        _ messages: [ChatMessage],
        workspaceType: WorkspaceManager.WorkspaceType,
        completion: @escaping (ThreadAnalysis) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let analysis = self.performThreadAnalysis(messages, workspaceType: workspaceType)
            
            DispatchQueue.main.async {
                completion(analysis)
            }
        }
    }
    
    private func performThreadAnalysis(
        _ messages: [ChatMessage],
        workspaceType: WorkspaceManager.WorkspaceType
    ) -> ThreadAnalysis {
        
        let userMessages = messages.filter { $0.role == .user }
        let assistantMessages = messages.filter { $0.role == .assistant }
        
        // Analyze conversation patterns
        let totalWords = userMessages.reduce(0) { total, message in
            total + message.content.components(separatedBy: .whitespacesAndNewlines).count
        }
        
        let avgMessageLength = userMessages.isEmpty ? 0 : totalWords / userMessages.count
        
        // Detect conversation themes
        let themes = detectConversationThemes(messages, workspaceType: workspaceType)
        
        // Calculate engagement score
        let engagementScore = calculateEngagementScore(messages)
        
        return ThreadAnalysis(
            messageCount: messages.count,
            userMessageCount: userMessages.count,
            assistantMessageCount: assistantMessages.count,
            averageMessageLength: avgMessageLength,
            totalWords: totalWords,
            themes: themes,
            engagementScore: engagementScore,
            workspaceType: workspaceType,
            lastActivity: messages.last?.timestamp ?? Date()
        )
    }
    
    // MARK: - Thread Continuation Support
    
    func generateThreadContinuation(
        based messages: [ChatMessage],
        workspaceType: WorkspaceManager.WorkspaceType
    ) -> String {
        
        guard !messages.isEmpty else {
            return generateInitialPrompt(for: workspaceType)
        }
        
        let recentMessages = Array(messages.suffix(3))
        let lastUserMessage = recentMessages.last { $0.role == .user }
        
        if let lastMessage = lastUserMessage {
            return generateContextualContinuation(
                lastMessage: lastMessage,
                workspaceType: workspaceType,
                conversationHistory: messages
            )
        }
        
        return generateGenericContinuation(for: workspaceType)
    }
    
    private func generateInitialPrompt(for workspaceType: WorkspaceManager.WorkspaceType) -> String {
        switch workspaceType {
        case .code:
            return "I'm ready to help with your coding project. What are you working on?"
        case .creative:
            return "I'm here to help with your creative work. What would you like to explore?"
        case .research:
            return "I'm ready to assist with your research. What would you like to investigate?"
        case .general:
            return "I'm here to help with whatever you're working on. How can I assist you?"
        }
    }
    
    private func generateContextualContinuation(
        lastMessage: ChatMessage,
        workspaceType: WorkspaceManager.WorkspaceType,
        conversationHistory: [ChatMessage]
    ) -> String {
        
        let context = lastMessage.content.lowercased()
        
        // Analyze what the user was discussing
        if context.contains("help") || context.contains("stuck") {
            return "I notice you might need some guidance. What specific aspect would you like me to help with?"
        }
        
        if context.contains("code") || context.contains("function") {
            return "I can see you're working with code. Would you like me to review it or help with any specific issues?"
        }
        
        if context.contains("write") || context.contains("draft") {
            return "I see you're working on writing. Would you like me to help refine it or provide feedback?"
        }
        
        // Default contextual response based on workspace type
        switch workspaceType {
        case .code:
            return "I'm ready to continue helping with your development work. What's next?"
        case .creative:
            return "I'm here to keep the creative momentum going. What would you like to work on?"
        case .research:
            return "I'm ready to continue our research discussion. What should we explore next?"
        case .general:
            return "I'm here to continue our conversation. What would you like to discuss?"
        }
    }
    
    private func generateGenericContinuation(for workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let continuations = workspaceType.intelligentPrompts
        return continuations.randomElement() ?? "How can I help you today?"
    }
    
    // MARK: - Thread Pattern Detection
    
    private func detectConversationThemes(
        _ messages: [ChatMessage],
        workspaceType: WorkspaceManager.WorkspaceType
    ) -> [String] {
        
        let allText = messages
            .map { $0.content.lowercased() }
            .joined(separator: " ")
        
        var themes: [String] = []
        
        // Common themes across workspace types
        let themeKeywords: [String: [String]] = [
            "problem-solving": ["help", "issue", "problem", "stuck", "error"],
            "learning": ["explain", "how", "why", "what", "understand"],
            "creation": ["create", "build", "make", "develop", "design"],
            "analysis": ["analyze", "review", "check", "evaluate", "assess"],
            "improvement": ["better", "improve", "optimize", "enhance", "refine"]
        ]
        
        for (theme, keywords) in themeKeywords {
            let matchCount = keywords.filter { allText.contains($0) }.count
            if matchCount >= 2 {
                themes.append(theme)
            }
        }
        
        return themes
    }
    
    private func calculateEngagementScore(_ messages: [ChatMessage]) -> Double {
        guard !messages.isEmpty else { return 0.0 }
        
        let userMessages = messages.filter { $0.role == .user }
        let assistantMessages = messages.filter { $0.role == .assistant }
        
        // Balance between user and assistant participation
        let participationBalance = min(Double(userMessages.count), Double(assistantMessages.count)) / Double(max(userMessages.count, assistantMessages.count, 1))
        
        // Average message length (longer messages typically indicate higher engagement)
        let avgLength = messages.reduce(0) { $0 + $1.content.count } / messages.count
        let lengthScore = min(1.0, Double(avgLength) / 200.0) // Normalize to 0-1
        
        // Recency factor (more recent activity = higher engagement)
        let timeSinceLastMessage = Date().timeIntervalSince(messages.last?.timestamp ?? Date.distantPast)
        let recencyScore = max(0.0, 1.0 - (timeSinceLastMessage / 3600.0)) // Decay over 1 hour
        
        return (participationBalance * 0.4 + lengthScore * 0.3 + recencyScore * 0.3)
    }
}

// MARK: - Supporting Data Structures

struct ThreadAnalysis {
    let messageCount: Int
    let userMessageCount: Int
    let assistantMessageCount: Int
    let averageMessageLength: Int
    let totalWords: Int
    let themes: [String]
    let engagementScore: Double
    let workspaceType: WorkspaceManager.WorkspaceType
    let lastActivity: Date
    
    var isActiveThread: Bool {
        engagementScore > 0.3 && Date().timeIntervalSince(lastActivity) < 3600 // Active if engaged and recent activity within 1 hour
    }
    
    var conversationStyle: ConversationStyle {
        if averageMessageLength > 100 {
            return .detailed
        } else if averageMessageLength > 30 {
            return .conversational
        } else {
            return .brief
        }
    }
}

enum ConversationStyle {
    case brief
    case conversational
    case detailed
    
    var displayName: String {
        switch self {
        case .brief: return "Brief"
        case .conversational: return "Conversational"
        case .detailed: return "Detailed"
        }
    }
}
