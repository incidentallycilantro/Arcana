// MemoryGraph.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

class MemoryGraph: ObservableObject {
    private var nodes: [MemoryNode] = []
    private var edges: [MemoryEdge] = []
    
    func addMemory(_ content: String, context: String) {
        // TODO: Implement memory graph storage
    }
    
    func searchMemory(_ query: String) -> [MemoryNode] {
        // TODO: Implement semantic search
        return []
    }
}

struct MemoryNode: Identifiable, Codable {
    let id: UUID
    var content: String
    var embedding: [Float]?
    var timestamp: Date
    var importance: Double
    var projectId: UUID
    
    // Fix for Codable - explicit initializer
    init(content: String, embedding: [Float]? = nil, timestamp: Date = Date(), importance: Double = 0.0, projectId: UUID) {
        self.id = UUID()
        self.content = content
        self.embedding = embedding
        self.timestamp = timestamp
        self.importance = importance
        self.projectId = projectId
    }
}

struct MemoryEdge: Identifiable, Codable {
    let id: UUID
    var sourceId: UUID
    var targetId: UUID
    var relationship: String
    var strength: Double
    
    // Fix for Codable - explicit initializer
    init(sourceId: UUID, targetId: UUID, relationship: String, strength: Double) {
        self.id = UUID()
        self.sourceId = sourceId
        self.targetId = targetId
        self.relationship = relationship
        self.strength = strength
    }
}
