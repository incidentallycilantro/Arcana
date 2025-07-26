// AssistantProfile.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift

import Foundation

struct AssistantProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var systemPrompt: String
    var preferredModel: String?
    var temperature: Double = 0.7
    var maxTokens: Int = 2048
    var personality: AssistantPersonality
    
    enum AssistantPersonality: String, Codable, CaseIterable {
        case helpful = "helpful"
        case creative = "creative"
        case analytical = "analytical"
        case casual = "casual"
        case professional = "professional"
        
        var displayName: String {
            switch self {
            case .helpful: return "Helpful"
            case .creative: return "Creative"
            case .analytical: return "Analytical"
            case .casual: return "Casual"
            case .professional: return "Professional"
            }
        }
    }
    
    init(name: String, systemPrompt: String, personality: AssistantPersonality = .helpful) {
        self.id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.personality = personality
    }
}

// Sample assistant profiles
extension AssistantProfile {
    static let defaultProfiles = [
        AssistantProfile(
            name: "General Assistant",
            systemPrompt: "You are a helpful, knowledgeable assistant.",
            personality: .helpful
        ),
        AssistantProfile(
            name: "Creative Writer",
            systemPrompt: "You are a creative writing assistant, helping with stories, poems, and imaginative content.",
            personality: .creative
        ),
        AssistantProfile(
            name: "Code Reviewer",
            systemPrompt: "You are a senior software engineer helping with code review, architecture, and best practices.",
            personality: .analytical
        )
    ]
}
