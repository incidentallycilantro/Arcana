// UserSettings.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    // Display Settings
    @Published var showModelAttribution: Bool {
        didSet { UserDefaults.standard.set(showModelAttribution, forKey: "showModelAttribution") }
    }
    
    @Published var showPerformanceMetrics: Bool {
        didSet { UserDefaults.standard.set(showPerformanceMetrics, forKey: "showPerformanceMetrics") }
    }
    
    // AI Settings
    @Published var enableIntelligentModelSelection: Bool {
        didSet { UserDefaults.standard.set(enableIntelligentModelSelection, forKey: "enableIntelligentModelSelection") }
    }
    
    @Published var enableWorkspaceAutoOptimization: Bool {
        didSet { UserDefaults.standard.set(enableWorkspaceAutoOptimization, forKey: "enableWorkspaceAutoOptimization") }
    }
    
    private init() {
        // Load settings from UserDefaults with sensible defaults
        self.showModelAttribution = UserDefaults.standard.object(forKey: "showModelAttribution") as? Bool ?? true
        self.showPerformanceMetrics = UserDefaults.standard.object(forKey: "showPerformanceMetrics") as? Bool ?? false
        self.enableIntelligentModelSelection = UserDefaults.standard.object(forKey: "enableIntelligentModelSelection") as? Bool ?? true
        self.enableWorkspaceAutoOptimization = UserDefaults.standard.object(forKey: "enableWorkspaceAutoOptimization") as? Bool ?? true
    }
}
