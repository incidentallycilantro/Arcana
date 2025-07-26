//
// AdapterController.swift
// Arcana - LoRA adapter management
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
//

import Foundation

@MainActor
class AdapterController: ObservableObject {
    @Published var availableAdapters: [LoRAAdapter] = []
    @Published var activeAdapter: LoRAAdapter? = nil
    @Published var loadingStatus: LoadingStatus = .idle
    
    enum LoadingStatus {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    init() {
        Task {
            await loadAvailableAdapters()
        }
    }
    
    func loadAvailableAdapters() async {
        loadingStatus = .loading
        
        // Simulate loading adapters from filesystem or configuration
        let sampleAdapters = [
            LoRAAdapter(
                name: "Code Assistant",
                path: "/path/to/code_adapter.safetensors",
                task: "code_generation",
                baseModel: "llama2-7b"
            ),
            LoRAAdapter(
                name: "Creative Writer",
                path: "/path/to/creative_adapter.safetensors",
                task: "creative_writing",
                baseModel: "llama2-7b"
            ),
            LoRAAdapter(
                name: "Research Assistant",
                path: "/path/to/research_adapter.safetensors",
                task: "research_analysis",
                baseModel: "llama2-7b"
            )
        ]
        
        await MainActor.run {
            availableAdapters = sampleAdapters
            loadingStatus = .loaded
        }
    }
    
    func loadAdapter(_ adapter: LoRAAdapter) async {
        loadingStatus = .loading
        
        do {
            // Simulate adapter loading process
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            await MainActor.run {
                activeAdapter = adapter
                loadingStatus = .loaded
            }
            
            print("✅ Loaded LoRA adapter: \(adapter.name)")
        } catch {
            await MainActor.run {
                loadingStatus = .error("Failed to load adapter: \(error.localizedDescription)")
            }
            print("❌ Failed to load adapter: \(adapter.name)")
        }
    }
    
    func unloadAdapter() async {
        loadingStatus = .loading
        
        // Simulate unloading process
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        await MainActor.run {
            activeAdapter = nil
            loadingStatus = .idle
        }
        
        print("📤 Unloaded LoRA adapter")
    }
    
    func getAdapterForTask(_ task: String) -> LoRAAdapter? {
        return availableAdapters.first { $0.task == task }
    }
    
    func getAdapterForWorkspaceType(_ workspaceType: WorkspaceManager.WorkspaceType) -> LoRAAdapter? {
        switch workspaceType {
        case .code:
            return getAdapterForTask("code_generation")
        case .creative:
            return getAdapterForTask("creative_writing")
        case .research:
            return getAdapterForTask("research_analysis")
        case .general:
            return nil // Use base model for general tasks
        }
    }
}

struct LoRAAdapter: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var task: String
    var baseModel: String
    var isLoaded: Bool = false
    var loadedAt: Date?
    
    init(name: String, path: String, task: String, baseModel: String) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.task = task
        self.baseModel = baseModel
    }
    
    var displayTask: String {
        switch task {
        case "code_generation":
            return "Code Generation"
        case "creative_writing":
            return "Creative Writing"
        case "research_analysis":
            return "Research Analysis"
        default:
            return task.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var icon: String {
        switch task {
        case "code_generation":
            return "chevron.left.forwardslash.chevron.right"
        case "creative_writing":
            return "paintbrush"
        case "research_analysis":
            return "doc.text.magnifyingglass"
        default:
            return "cpu"
        }
    }
}
