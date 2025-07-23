// IntelligenceEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class IntelligenceEngine: ObservableObject {
    
    // MARK: - Real-time Input Analysis
    
    func analyzeInputInRealTime(_ text: String, workspaceType: WorkspaceManager.WorkspaceType) {
        // Invisible intelligence - no UI feedback, just background analysis
        guard text.count > 50 else { return }
        
        switch workspaceType {
        case .code:
            if text.contains("func ") || text.contains("class ") || text.contains("import ") {
                // Code detected - prepare for formatting suggestions
            }
        case .creative:
            if text.count > 200 {
                // Long form writing - prepare tone analysis
            }
        case .research:
            if text.contains("study") || text.contains("research") || text.contains("according to") {
                // Research claims detected - prepare fact checking
            }
        case .general:
            break
        }
    }
    
    // MARK: - Contextual Response Generation
    
    func generateContextualResponse(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        conversationHistory: [ChatMessage]
    ) -> String {
        
        // Detect content type and respond intelligently
        if isCodeContent(userMessage) {
            return generateCodeResponse(userMessage, workspaceType: workspaceType)
        } else if isLongFormWriting(userMessage) {
            return generateWritingResponse(userMessage, workspaceType: workspaceType)
        } else if isResearchContent(userMessage) {
            return generateResearchResponse(userMessage, workspaceType: workspaceType)
        } else {
            return generateGeneralResponse(userMessage, workspaceType: workspaceType)
        }
    }
    
    // MARK: - Proactive Assistance
    
    func checkForProactiveAssistance(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        completion: @escaping (String?) -> Void
    ) {
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            var assistance: String? = nil
            
            // Detect patterns that suggest user might need help
            if userMessage.contains("I'm stuck") || userMessage.contains("not sure") {
                assistance = "I notice you might be looking for direction. Would you like me to help break this down into smaller steps?"
            } else if self.isCodeContent(userMessage) && userMessage.contains("error") {
                assistance = "I see there might be an issue with this code. Would you like me to analyze it for potential problems?"
            } else if userMessage.count > 300 && workspaceType == .creative {
                assistance = "That's a substantial piece of writing! Would you like me to help refine the tone or structure?"
            } else if self.isResearchContent(userMessage) {
                assistance = "I notice you're discussing research. Would you like me to fact-check any of these claims?"
            }
            
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
        
        let baseMessage = "I've received '\(fileName)'. "
        
        switch fileExtension {
        case "swift", "py", "js", "java", "cpp", "c":
            return baseMessage + "I can see this is code. Would you like me to review it for improvements, explain how it works, or help with any specific issues?"
            
        case "pdf", "docx", "doc":
            return baseMessage + "This looks like a document. I can help you summarize it, extract key points, or answer questions about its content."
            
        case "md", "txt":
            return baseMessage + "I've read through this text. What would you like to explore or discuss about it?"
            
        case "csv", "xlsx":
            return baseMessage + "I can see this contains data. Would you like me to analyze patterns, create summaries, or help you understand what the data shows?"
            
        case "png", "jpg", "jpeg":
            return baseMessage + "I've received an image. While I can't see the details yet, feel free to describe what you'd like to discuss about it."
            
        default:
            return baseMessage + "I'm ready to help you work with this file. What would you like to do with it?"
        }
    }
    
    // MARK: - Content Detection Helpers
    
    private func isCodeContent(_ text: String) -> Bool {
        let codeIndicators = ["func ", "class ", "import ", "def ", "function", "const ", "var ", "let ", "{", "}", "//", "/*", "*/", "#include", "public ", "private "]
        return codeIndicators.contains { text.contains($0) }
    }
    
    private func isLongFormWriting(_ text: String) -> Bool {
        return text.count > 150 && !isCodeContent(text)
    }
    
    private func isResearchContent(_ text: String) -> Bool {
        let researchIndicators = ["study shows", "research indicates", "according to", "data suggests", "findings", "methodology", "hypothesis", "correlation", "statistically"]
        return researchIndicators.contains { text.localizedCaseInsensitiveContains($0) }
    }
    
    // MARK: - Response Generators
    
    private func generateCodeResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let responses = [
            "I can see this is code. Looking at the structure, there are a few things that could be improved. Would you like me to suggest some optimizations?",
            "This code looks well-structured! I notice some patterns here - would you like me to explain how it works or suggest any enhancements?",
            "I've analyzed this code. There are some interesting approaches here. Should we discuss the logic or focus on potential improvements?"
        ]
        return responses.randomElement() ?? "I can help you with this code. What specific aspect would you like to focus on?"
    }
    
    private func generateWritingResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let wordCount = message.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        if wordCount > 200 {
            return "That's a substantial piece of writing! The ideas flow well. Would you like me to help refine the tone, check for clarity, or suggest ways to make it more engaging?"
        } else {
            return "I can see you're developing some interesting ideas here. Would you like me to help expand on any particular points or suggest ways to strengthen the argument?"
        }
    }
    
    private func generateResearchResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let responses = [
            "I notice you're discussing research findings. These are interesting points. Would you like me to help verify any of these claims or suggest additional sources?",
            "This research content looks substantial. I can help fact-check specific claims or assist with organizing the information. What would be most helpful?",
            "I see several research references here. Would you like me to help analyze the methodology or suggest ways to strengthen the evidence?"
        ]
        return responses.randomElement() ?? "I can help you work with this research content. What aspect would you like to focus on?"
    }
    
    private func generateGeneralResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let responses = [
            "I understand what you're working on. How can I help you think through this further?",
            "That's an interesting perspective. Would you like me to help you explore this idea from different angles?",
            "I can see where you're heading with this. What aspect would you like to dive deeper into?",
            "Those are good points. Should we build on this or would you like me to help organize these thoughts differently?"
        ]
        return responses.randomElement() ?? "I'm here to help you think through this. What would be most useful?"
    }
}
