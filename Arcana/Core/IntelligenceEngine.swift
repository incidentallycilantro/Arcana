// IntelligenceEngine.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class IntelligenceEngine: ObservableObject {
    
    // Performance optimization: debounce real-time analysis
    private var analysisTimer: Timer?
    private let analysisDelay: TimeInterval = 0.5 // Wait 500ms after user stops typing
    private let maxAnalysisLength = 1000 // Don't analyze texts longer than 1000 characters in real-time
    
    // MARK: - Optimized Real-time Input Analysis
    
    func analyzeInputInRealTime(_ text: String, workspaceType: WorkspaceManager.WorkspaceType) {
        // Performance guard: Skip analysis for very long texts
        guard text.count <= maxAnalysisLength else {
            print("⚡ Skipping real-time analysis for large text (\(text.count) chars)")
            return
        }
        
        // Performance guard: Skip analysis for very short texts
        guard text.count > 20 else { return }
        
        // Debounce: Cancel previous timer and start new one
        analysisTimer?.invalidate()
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisDelay, repeats: false) { _ in
            self.performDebouncedAnalysis(text, workspaceType: workspaceType)
        }
    }
    
    private func performDebouncedAnalysis(_ text: String, workspaceType: WorkspaceManager.WorkspaceType) {
        // Lightweight analysis only - no heavy processing
        DispatchQueue.global(qos: .background).async {
            switch workspaceType {
            case .code:
                if self.isCodeContent(text) {
                    // Light analysis for code patterns
                    print("🧠 Code patterns detected in workspace")
                }
            case .creative:
                if text.count > 200 {
                    // Light analysis for long-form writing
                    print("🧠 Long-form writing detected")
                }
            case .research:
                if self.isResearchContent(text) {
                    // Light analysis for research patterns
                    print("🧠 Research content detected")
                }
            case .general:
                break
            }
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
    
    // MARK: - Performance-Optimized Proactive Assistance
    
    func checkForProactiveAssistance(
        userMessage: String,
        workspaceType: WorkspaceManager.WorkspaceType,
        completion: @escaping (String?) -> Void
    ) {
        
        // Performance optimization: Use background queue with shorter delay for large texts
        let delay: TimeInterval = userMessage.count > 500 ? 0.5 : 1.0
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
            var assistance: String? = nil
            
            // Quick pattern detection without heavy processing
            if userMessage.localizedCaseInsensitiveContains("stuck") || userMessage.localizedCaseInsensitiveContains("not sure") {
                assistance = "I notice you might be looking for direction. Would you like me to help break this down into smaller steps?"
            } else if self.isCodeContent(userMessage) && (userMessage.localizedCaseInsensitiveContains("error") || userMessage.localizedCaseInsensitiveContains("bug")) {
                assistance = "I see there might be an issue with this code. Would you like me to analyze it for potential problems?"
            } else if userMessage.count > 300 && workspaceType == .creative {
                assistance = "That's a substantial piece of writing! Would you like me to help refine the tone or structure?"
            } else if self.isResearchContent(userMessage) && userMessage.count > 200 {
                assistance = "I notice you're discussing research. Would you like me to fact-check any of these claims?"
            }
            
            DispatchQueue.main.async {
                completion(assistance)
            }
        }
    }
    
    // MARK: - Optimized File Processing
    
    func generateFileProcessingResponse(
        fileName: String,
        fileExtension: String,
        workspaceType: WorkspaceManager.WorkspaceType
    ) -> String {
        
        let baseMessage = "I've received '\(fileName)'. "
        
        switch fileExtension {
        case "swift", "py", "js", "java", "cpp", "c", "ts", "go", "rs":
            return baseMessage + "I can see this is code. Would you like me to review it for improvements, explain how it works, or help with any specific issues?"
            
        case "pdf", "docx", "doc":
            return baseMessage + "This looks like a document. I can help you summarize it, extract key points, or answer questions about its content."
            
        case "md", "txt":
            return baseMessage + "I've read through this text. What would you like to explore or discuss about it?"
            
        case "csv", "xlsx", "json":
            return baseMessage + "I can see this contains data. Would you like me to analyze patterns, create summaries, or help you understand what the data shows?"
            
        case "png", "jpg", "jpeg", "gif", "svg":
            return baseMessage + "I've received an image. While I can't see the details yet, feel free to describe what you'd like to discuss about it."
            
        default:
            return baseMessage + "I'm ready to help you work with this file. What would you like to do with it?"
        }
    }
    
    // MARK: - Lightweight Content Detection Helpers
    
    private func isCodeContent(_ text: String) -> Bool {
        // Optimized: Check only first 200 characters for performance
        let sample = String(text.prefix(200)).lowercased()
        let codeIndicators = ["func ", "class ", "import ", "def ", "function", "const ", "var ", "let ", "{", "}", "//", "/*"]
        return codeIndicators.contains { sample.contains($0) }
    }
    
    private func isLongFormWriting(_ text: String) -> Bool {
        return text.count > 150 && !isCodeContent(text)
    }
    
    private func isResearchContent(_ text: String) -> Bool {
        // Optimized: Check only first 300 characters for performance
        let sample = String(text.prefix(300)).lowercased()
        let researchIndicators = ["study shows", "research indicates", "according to", "data suggests", "findings", "methodology"]
        return researchIndicators.contains { sample.contains($0) }
    }
    
    // MARK: - Response Generators (Optimized)
    
    private func generateCodeResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        // Quick analysis without heavy processing
        let hasError = message.localizedCaseInsensitiveContains("error") || message.localizedCaseInsensitiveContains("bug")
        let hasFunction = message.localizedCaseInsensitiveContains("function") || message.localizedCaseInsensitiveContains("func")
        
        if hasError {
            return "I can see there's an issue with this code. Let me help you debug it. What specific error are you encountering?"
        } else if hasFunction && message.count > 100 {
            return "This looks like a substantial function. I can help analyze its logic, suggest improvements, or explain how it works. What aspect would you like to focus on?"
        } else {
            return "I can see this is code. Would you like me to review it for optimizations, explain the logic, or help with any specific challenges?"
        }
    }
    
    private func generateWritingResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        let wordCount = message.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        if wordCount > 200 {
            return "That's a substantial piece of writing! The ideas flow well. Would you like me to help refine the tone, check for clarity, or suggest ways to make it more engaging?"
        } else if wordCount > 50 {
            return "I can see you're developing some interesting ideas here. Would you like me to help expand on any particular points or suggest ways to strengthen the narrative?"
        } else {
            return "This is a good start! How can I help you develop these ideas further?"
        }
    }
    
    private func generateResearchResponse(_ message: String, workspaceType: WorkspaceManager.WorkspaceType) -> String {
        if message.count > 300 {
            return "I notice you're discussing substantial research findings. These are interesting points. Would you like me to help verify any claims or suggest additional sources?"
        } else {
            return "I see research references here. Would you like me to help analyze the methodology or suggest ways to strengthen the evidence?"
        }
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
    
    // MARK: - Cleanup
    
    deinit {
        analysisTimer?.invalidate()
    }
}
