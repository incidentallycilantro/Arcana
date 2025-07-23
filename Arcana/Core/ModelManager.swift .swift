// LLMModel.swift (for ModelManager)
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

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

struct LoRAAdapter: Identifiable, Codable {
    let id: UUID
    var name: String
    var path: String
    var task: String
    var baseModel: String
    
    init(name: String, path: String, task: String, baseModel: String) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.task = task
        self.baseModel = baseModel
    }
}
Smart, efficient model for everyday use Learn more

Artifacts

