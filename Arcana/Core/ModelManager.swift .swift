// ModelManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

class ModelManager: ObservableObject {
    @Published var models: [LLMModel] = []
    
    init() {
        // Model management will be implemented in Phase 2
    }
    
    func loadAvailableModels() {
        // TODO: Implement model discovery
    }
}

struct LLMModel: Identifiable, Codable {
    let id: UUID
    var name: String
    var path: String
    var size: Int64
    var quantization: String
    var capabilities: [String]
    
    init(name: String, path: String, size: Int64, quantization: String, capabilities: [String] = []) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.size = size
        self.quantization = quantization
        self.capabilities = capabilities
    }
}
