// IntelligenceEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class IntelligenceEngine: ObservableObject {
    
    @Published var isProcessing = false
    @Published var currentTask: String?
    
    init() {
        // Initialize intelligence engine
    }
    
    // MARK: - Core Intelligence Functions
    
    func analyzeInputInRealTime(_ input: String, workspaceType: WorkspaceManager.WorkspaceType) {
        // Real-time input analysis for smart suggestions
        guard !input.isEmpty else { return }
        
        // Provide contextual feedback based on workspace type and input
        detectIntent(from: input, workspaceType: workspaceType)
    }
    
    func generateContextualResponse(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        conversationHistory: [ChatMessage]
    ) -> String {
        // Generate intelligent contextual responses
        return generateResponseForType(workspaceType, message: userMessage, history: conversationHistory)
    }
    
    func generateContextualResponse(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        conversationHistory: [ChatMessage],
        completion: @escaping (String) -> Void
    ) {
        // Async version for background processing
        DispatchQueue.global(qos: .userInitiated).async {
            let response = self.generateResponseForType(workspaceType, message: userMessage, history: conversationHistory)
            
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
    
    func checkForProactiveAssistance(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        completion: @escaping (String?) -> Void
    ) {
        // Check if proactive help should be offered
        DispatchQueue.global(qos: .background).async {
            let assistance = self.evaluateProactiveHelp(message: userMessage, type: workspaceType)
            
            DispatchQueue.main.async {
                completion(assistance)
            }
        }
    }
    
    // MARK: - File Processing
    
    func generateFileProcessingResponse(
        fileName: String,
        fileExtension: String,
        workspaceType: WorkspaceManager.WorkspaceType
    ) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "I've analyzed the PDF '\(fileName)'. What would you like to know about its contents?"
        case "docx", "doc":
            return "I've processed the document '\(fileName)'. I can summarize, extract key points, or analyze the content."
        case "swift", "py", "js", "java", "cpp", "c":
            return "I've reviewed the code file '\(fileName)'. I can help with analysis, documentation, or improvements."
        case "md", "txt":
            return "I've read '\(fileName)'. How can I help you work with this content?"
        case "csv", "xlsx":
            return "I've processed the data file '\(fileName)'. I can help analyze patterns or extract insights."
        case "json":
            return "I've parsed the JSON file '\(fileName)'. What would you like me to help you with?"
        default:
            return "I've processed '\(fileName)'. What would you like me to help you with?"
        }
    }
    
    // MARK: - Thread Management
    
    func generateThreadTitle(from content: String) -> String {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(6)
        
        if words.count > 3 {
            return Array(words.prefix(3)).joined(separator: " ") + "..."
        } else {
            return words.joined(separator: " ")
        }
    }
    
    // MARK: - Workspace Type Detection
    
    func detectWorkspaceType(from content: String) -> WorkspaceManager.WorkspaceType {
        let lowercaseContent = content.lowercased()
        
        // Enhanced keyword detection with scoring
        let codeKeywords = ["code", "programming", "development", "swift", "python", "javascript", "api", "debug", "software", "algorithm", "framework", "repository", "github", "coding", "technical", "architecture", "database", "backend", "frontend", "mobile", "web", "ios", "android", "react", "node", "java", "c++", "html", "css", "sql"]
        
        let creativeKeywords = ["creative", "writing", "story", "novel", "poem", "poetry", "art", "design", "music", "screenplay", "character", "plot", "narrative", "fiction", "blog", "content", "marketing", "copy", "brand", "artistic", "illustration", "graphics", "video", "animation", "photography", "brainstorm", "idea", "concept", "vision", "imagination", "inspiration"]
        
        let researchKeywords = ["research", "analysis", "study", "report", "data", "market", "survey", "academic", "paper", "thesis", "investigation", "findings", "statistics", "trends", "insights", "analytics", "business", "strategy", "competitive", "industry", "economics", "finance", "science", "methodology", "hypothesis", "experiment", "evidence", "documentation", "review", "evaluation"]
        
        let codeScore = calculateTypeScore(lowercaseContent, keywords: codeKeywords)
        let creativeScore = calculateTypeScore(lowercaseContent, keywords: creativeKeywords)
        let researchScore = calculateTypeScore(lowercaseContent, keywords: researchKeywords)
        
        let maxScore = max(codeScore, creativeScore, researchScore)
        
        if maxScore < 1 {
            return .general
        } else if codeScore == maxScore {
            return .code
        } else if creativeScore == maxScore {
            return .creative
        } else {
            return .research
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func detectIntent(from input: String, workspaceType: WorkspaceManager.WorkspaceType) {
        // Analyze user intent for real-time suggestions
        let intent = classifyIntent(input, workspaceType: workspaceType)
        
        // Update current task for UI feedback
        DispatchQueue.main.async {
            self.currentTask = intent
        }
    }
    
    private func classifyIntent(_ input: String, workspaceType: WorkspaceManager.WorkspaceType) -> String? {
        let lowercaseInput = input.lowercased()
        
        // Intent classification based on workspace type
        switch workspaceType {
        case .code:
            if lowercaseInput.contains("review") || lowercaseInput.contains("check") {
                return "Code review detected"
            } else if lowercaseInput.contains("debug") || lowercaseInput.contains("error") {
                return "Debugging assistance needed"
            } else if lowercaseInput.contains("explain") || lowercaseInput.contains("how") {
                return "Code explanation requested"
            }
        case .creative:
            if lowercaseInput.contains("write") || lowercaseInput.contains("draft") {
                return "Writing assistance requested"
            } else if lowercaseInput.contains("idea") || lowercaseInput.contains("brainstorm") {
                return "Creative ideation needed"
            }
        case .research:
            if lowercaseInput.contains("analyze") || lowercaseInput.contains("research") {
                return "Research analysis requested"
            } else if lowercaseInput.contains("fact") || lowercaseInput.contains("verify") {
                return "Fact-checking needed"
            }
        case .general:
            break
        }
        
        return nil
    }
    
    private func generateResponseForType(
        _ workspaceType: WorkspaceManager.WorkspaceType,
        message: String,
        history: [ChatMessage]
    ) -> String {
        switch workspaceType {
        case .code:
            return generateCodeResponse(message: message, history: history)
        case .creative:
            return generateCreativeResponse(message: message, history: history)
        case .research:
            return generateResearchResponse(message: message, history: history)
        case .general:
            return generateGeneralResponse(message: message, history: history)
        }
    }
    
    private func generateCodeResponse(message: String, history: [ChatMessage]) -> String {
        let responses = [
            "I can help you analyze this code. Would you like me to check for optimizations?",
            "Let me review the code structure and suggest improvements.",
            "I notice this is code-related. I can help with debugging, documentation, or testing.",
            "I see you're working on a technical solution. Let me help you think through this.",
            "This looks like a development challenge. I can assist with architecture and best practices."
        ]
        return responses.randomElement() ?? "I'm ready to help with your coding project."
    }
    
    private func generateCreativeResponse(message: String, history: [ChatMessage]) -> String {
        let responses = [
            "That's an interesting creative direction! Let me help you develop this further.",
            "I can help refine the tone and style of your work.",
            "Great creative thinking! Would you like me to analyze the structure or flow?",
            "I love the creative energy here. Let's explore this concept deeper.",
            "This has great potential. I can help you polish and expand on these ideas."
        ]
        return responses.randomElement() ?? "I'm here to help with your creative work."
    }
    
    private func generateResearchResponse(message: String, history: [ChatMessage]) -> String {
        let responses = [
            "I can help verify those claims and find supporting evidence.",
            "Let me analyze the data and provide insights on the research.",
            "I notice this involves research. I can help with fact-checking and analysis.",
            "Interesting research direction. I can help you organize and evaluate the findings.",
            "I can assist with methodology and help structure your research approach."
        ]
        return responses.randomElement() ?? "I'm ready to help with your research."
    }
    
    private func generateGeneralResponse(message: String, history: [ChatMessage]) -> String {
        let responses = [
            "I understand! Let me help you with that.",
            "That's a great question. Here's what I think...",
            "Based on what you've shared, I'd suggest...",
            "I can definitely help you explore this further.",
            "Let's work through this together step by step."
        ]
        return responses.randomElement() ?? "How can I help you with this?"
    }
    
    private func evaluateProactiveHelp(message: String, type: WorkspaceManager.WorkspaceType) -> String? {
        let lowercaseMessage = message.lowercased()
        
        // Evaluate if proactive assistance should be offered
        switch type {
        case .code:
            if lowercaseMessage.contains("stuck") || lowercaseMessage.contains("error") {
                return "I notice you might be facing a challenge. Would you like me to help debug this step by step?"
            }
        case .creative:
            if lowercaseMessage.count > 200 && lowercaseMessage.contains("write") {
                return "I see you're working on substantial content. Would you like feedback on structure or tone?"
            }
        case .research:
            if lowercaseMessage.contains("finding") || lowercaseMessage.contains("conclusion") {
                return "I can help organize your findings or suggest additional research directions if helpful."
            }
        case .general:
            break
        }
        
        return nil
    }
    
    private func calculateTypeScore(_ text: String, keywords: [String]) -> Double {
        var score = 0.0
        
        for keyword in keywords {
            if text.contains(keyword) {
                // Weight keywords by length (longer = more specific)
                let weight = Double(keyword.count) / 5.0
                score += weight
                
                // Bonus for exact word matches
                if text.components(separatedBy: .whitespacesAndNewlines).contains(keyword) {
                    score += weight * 0.5
                }
            }
        }
        
        return score
    }
}
