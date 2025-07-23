// ArcanaApp.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

@main
struct ArcanaApp: App {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(userSettings)
                .environmentObject(workspaceManager)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Workspace") {
                    workspaceManager.showNewWorkspaceSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .newItem) {
                Button("Import Workspace...") {
                    // TODO: Implement import
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Export Workspace...") {
                    // TODO: Implement export
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Inspector") {
                    // This will be handled by the MainView
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
            
            // AI-specific menu
            CommandMenu("AI") {
                Button("Regenerate Response") {
                    // TODO: Implement regenerate
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Button("Clear Conversation") {
                    // TODO: Implement clear
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Divider()
                
                Menu("Switch Model") {
                    Button("Mistral-7B") {
                        // TODO: Implement model switching
                    }
                    Button("CodeLlama-7B") {
                        // TODO: Implement model switching
                    }
                    Button("Phi-2") {
                        // TODO: Implement model switching
                    }
                }
                
                Divider()
                
                Button("Performance Monitor") {
                    // TODO: Show performance window
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            ModelsSettingsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "lock")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show model attribution", isOn: $userSettings.showModelAttribution)
                    .help("Display which model generated each response")
                
                Toggle("Show performance metrics", isOn: $userSettings.showPerformanceMetrics)
                    .help("Show token count, response time, and other metrics")
            }
            
            Section("Intelligence") {
                Toggle("Intelligent model selection", isOn: $userSettings.enableIntelligentModelSelection)
                    .help("Automatically choose the best model based on task complexity")
                
                Toggle("Workspace optimization", isOn: $userSettings.enableWorkspaceOptimization)
                    .help("Automatically detect workspace types and optimize settings")
            }
            
            Section("Updates") {
                Toggle("Background optimization", isOn: $userSettings.enableBackgroundOptimization)
                    .help("Allow background processing to improve performance")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelsSettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    @State private var selectedModel = "mistral-7b"
    
    var body: some View {
        Form {
            Section("Performance") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Maximum memory usage:")
                        Spacer()
                        Text("\(Int(userSettings.maxMemoryUsage))%")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $userSettings.maxMemoryUsage, in: 25...90, step: 5)
                        .help("Limit how much system memory Arcana can use")
                }
            }
            
            Section("Default Model") {
                Picker("Default model:", selection: $selectedModel) {
                    Text("Mistral-7B").tag("mistral-7b")
                    Text("CodeLlama-7B").tag("codellama-7b")
                    Text("Phi-2").tag("phi-2")
                }
                .pickerStyle(.menu)
                .help("Choose the default model for new workspaces")
            }
            
            Section("Model Management") {
                HStack {
                    Button("Install New Model...") {
                        // TODO: Implement model installation
                    }
                    
                    Spacer()
                    
                    Button("Manage Models...") {
                        // TODO: Open model manager
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PrivacySettingsView: View {
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Form {
            Section("Data Protection") {
                Toggle("Enable local encryption", isOn: $userSettings.enableLocalEncryption)
                    .help("Encrypt all conversation data stored on your device")
                
                Toggle("Auto-delete sensitive data", isOn: $userSettings.autoDeleteSensitiveData)
                    .help("Automatically remove sensitive information after conversations")
            }
            
            Section("Data Management") {
                HStack {
                    Button("Clear All Data") {
                        // TODO: Implement data clearing
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Export Data...") {
                        // TODO: Implement data export
                    }
                }
            }
            
            Section("Privacy Policy") {
                Text("Arcana processes all data locally on your device. No data is sent to external servers without your explicit consent.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button("View Privacy Policy") {
                        // TODO: Open privacy policy
                    }
                    
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AdvancedSettingsView: View {
    @State private var debugMode = false
    @State private var experimentalFeatures = false
    
    var body: some View {
        Form {
            Section("Developer Options") {
                Toggle("Debug mode", isOn: $debugMode)
                    .help("Enable detailed logging and debug information")
                
                Toggle("Experimental features", isOn: $experimentalFeatures)
                    .help("Enable experimental and preview features")
            }
            
            Section("Performance") {
                HStack {
                    Button("Reset Performance Settings") {
                        UserSettings.shared.resetToDefaults()
                    }
                    
                    Spacer()
                    
                    Button("Run Performance Test") {
                        // TODO: Implement performance test
                    }
                }
            }
            
            Section("System Information") {
                HStack {
                    Text("Arcana Version:")
                    Spacer()
                    Text("1.0.0 (Beta)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("PRISM Engine:")
                    Spacer()
                    Text("Ready")
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Text("System:")
                    Spacer()
                    Text("macOS 14.0+")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
