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
    
    // Intelligence Settings
    @Published var enableIntelligentModelSelection: Bool {
        didSet { UserDefaults.standard.set(enableIntelligentModelSelection, forKey: "enableIntelligentModelSelection") }
    }
    
    @Published var enableWorkspaceOptimization: Bool {
        didSet { UserDefaults.standard.set(enableWorkspaceOptimization, forKey: "enableWorkspaceOptimization") }
    }
    
    // Privacy Settings
    @Published var enableLocalEncryption: Bool {
        didSet { UserDefaults.standard.set(enableLocalEncryption, forKey: "enableLocalEncryption") }
    }
    
    @Published var autoDeleteSensitiveData: Bool {
        didSet { UserDefaults.standard.set(autoDeleteSensitiveData, forKey: "autoDeleteSensitiveData") }
    }
    
    // Performance Settings
    @Published var maxMemoryUsage: Double {
        didSet { UserDefaults.standard.set(maxMemoryUsage, forKey: "maxMemoryUsage") }
    }
    
    @Published var enableBackgroundOptimization: Bool {
        didSet { UserDefaults.standard.set(enableBackgroundOptimization, forKey: "enableBackgroundOptimization") }
    }
    
    private init() {
        // Load saved settings or use defaults
        self.showModelAttribution = UserDefaults.standard.object(forKey: "showModelAttribution") as? Bool ?? true
        self.showPerformanceMetrics = UserDefaults.standard.object(forKey: "showPerformanceMetrics") as? Bool ?? false
        self.enableIntelligentModelSelection = UserDefaults.standard.object(forKey: "enableIntelligentModelSelection") as? Bool ?? true
        self.enableWorkspaceOptimization = UserDefaults.standard.object(forKey: "enableWorkspaceOptimization") as? Bool ?? true
        self.enableLocalEncryption = UserDefaults.standard.object(forKey: "enableLocalEncryption") as? Bool ?? true
        self.autoDeleteSensitiveData = UserDefaults.standard.object(forKey: "autoDeleteSensitiveData") as? Bool ?? false
        self.maxMemoryUsage = UserDefaults.standard.object(forKey: "maxMemoryUsage") as? Double ?? 75.0
        self.enableBackgroundOptimization = UserDefaults.standard.object(forKey: "enableBackgroundOptimization") as? Bool ?? true
    }
    
    func resetToDefaults() {
        showModelAttribution = true
        showPerformanceMetrics = false
        enableIntelligentModelSelection = true
        enableWorkspaceOptimization = true
        enableLocalEncryption = true
        autoDeleteSensitiveData = false
        maxMemoryUsage = 75.0
        enableBackgroundOptimization = true
    }
}
