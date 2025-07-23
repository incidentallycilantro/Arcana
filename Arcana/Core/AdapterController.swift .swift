// AdapterController.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

class AdapterController: ObservableObject {
    @Published var availableAdapters: [LoRAAdapter] = []
    
    func loadAdapter(_ adapter: LoRAAdapter) async {
        // TODO: Implement LoRA adapter loading
    }
}

struct LoRAAdapter: Identifiable, Codable {
    let id = UUID()
    var name: String
    var path: String
    var task: String
    var baseModel: String
}
