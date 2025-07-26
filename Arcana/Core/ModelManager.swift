// ModelManager.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, WorkspaceManager.swift

import Foundation

class ModelManager: ObservableObject {
    @Published var models: [LLMModel] = []
    
    init() {
        // Model management will be implemented in Phase 2
    }
    
    func loadAvailableModels() {
        // TODO: Implement model discovery
    }
    
    func getAvailableModels() async -> [String] {
        // Return list of available models
        return ["Mistral-7B", "CodeLlama-7B", "Phi-2", "TinyLlama-1B"]
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
