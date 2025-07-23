// ChatMessage.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var role: MessageRole
    var timestamp: Date
    var projectId: UUID
    var isStreaming: Bool = false
    var metadata: MessageMetadata?
    
    init(content: String, role: MessageRole, projectId: UUID) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.projectId = projectId
        self.timestamp = Date()
    }
    
    enum MessageRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "Arcana"
            case .system: return "System"
            }
        }
    }
}

struct MessageMetadata: Codable, Hashable {
    var modelUsed: String?
    var tokensGenerated: Int?
    var responseTime: TimeInterval?
    var wasSpeculative: Bool?
    var attachedFiles: [String]?
}

// Sample data for development
extension ChatMessage {
    static func sampleMessages(for projectId: UUID) -> [ChatMessage] {
        [
            ChatMessage(
                content: "Hello! I'd like help organizing my thoughts for a presentation.",
                role: .user,
                projectId: projectId
            ),
            ChatMessage(
                content: "I'd be happy to help you organize your presentation! What's the topic and who's your audience? This will help me suggest the best structure and key points to focus on.",
                role: .assistant,
                projectId: projectId
            ),
            ChatMessage(
                content: "It's about the future of AI in education, for a conference of teachers and administrators.",
                role: .user,
                projectId: projectId
            )
        ]
    }
}
