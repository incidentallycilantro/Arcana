// Project.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var lastModified: Date
    var isPinned: Bool = false
    var assistantProfile: AssistantProfile?
    var preferredModel: String?
    
    init(title: String, description: String = "") {
        self.id = UUID()
        self.title = title
        self.description = description
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    mutating func updateModified() {
        self.lastModified = Date()
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

// Sample data for development
extension Project {
    static let sampleProjects = [
        Project(title: "Personal Assistant", description: "General purpose conversations and tasks"),
        Project(title: "Code Review", description: "Software development and code analysis"),
        Project(title: "Creative Writing", description: "Stories, poems, and creative content")
    ]
}
