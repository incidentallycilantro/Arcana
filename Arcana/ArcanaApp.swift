// ArcanaApp.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

@main
struct ArcanaApp: App {
    @StateObject private var prismEngine = PRISMEngine.shared
    @StateObject private var appState = AppState()
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(prismEngine)
                .environmentObject(appState)
                .environmentObject(userSettings)
                .task {
                    await prismEngine.initialize()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            ArcanaMenuCommands()
        }
        
        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(userSettings)
        }
    }
}

// App state management
class AppState: ObservableObject {
    @Published var shouldShowNewProject = false
    @Published var shouldToggleSidebar = false
    @Published var shouldToggleInspector = false
}

struct ArcanaMenuCommands: Commands {
    @FocusedObject private var appState: AppState?
    
    var body: some Commands {
        // File Menu Additions
        CommandGroup(after: .newItem) {
            Button("New Project...") {
                appState?.shouldShowNewProject = true
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Button("Import Project...") {
                // TODO: Implement import project action
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Export Project...") {
                // TODO: Implement export project action
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
        
        // Edit Menu Additions
        CommandGroup(after: .pasteboard) {
            Divider()
            
            Button("Clear Conversation") {
                // TODO: Implement clear conversation action
            }
            .keyboardShortcut("k", modifiers: [.command])
            
            Button("Fork Conversation") {
                // TODO: Implement fork conversation action
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
        
        // View Menu
        CommandMenu("View") {
            Button("Toggle Sidebar") {
                appState?.shouldToggleSidebar = true
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
            
            Button("Toggle Inspector") {
                appState?.shouldToggleInspector = true
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            
            Divider()
            
            Button("Zoom In") {
                // TODO: Implement zoom in action
            }
            .keyboardShortcut("+", modifiers: [.command])
            
            Button("Zoom Out") {
                // TODO: Implement zoom out action
            }
            .keyboardShortcut("-", modifiers: [.command])
            
            Button("Actual Size") {
                // TODO: Implement actual size action
            }
            .keyboardShortcut("0", modifiers: [.command])
        }
        
        // AI Menu (Custom)
        CommandMenu("AI") {
            Button("Switch Model...") {
                // TODO: Implement model switching
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            
            Button("Regenerate Response") {
                // TODO: Implement regenerate response
            }
            .keyboardShortcut("r", modifiers: [.command])
            
            Divider()
            
            Button("Performance Monitor") {
                // TODO: Open performance monitor
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
            
            Button("Model Manager...") {
                // TODO: Open model manager
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
        }
        
        // Help Menu Additions
        CommandGroup(after: .help) {
            Button("Arcana User Guide") {
                // TODO: Open user guide
            }
            
            Button("Keyboard Shortcuts") {
                // TODO: Show keyboard shortcuts
            }
            .keyboardShortcut("/", modifiers: [.command])
            
            Divider()
            
            Button("Privacy Policy") {
                // TODO: Open privacy policy
            }
            
            Button("Report Issue") {
                // TODO: Open issue reporting
            }
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case models = "Models"
        case privacy = "Privacy"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .models: return "brain.head.profile"
            case .privacy: return "lock.shield"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                }
                .tag(SettingsTab.general)
            
            ModelSettingsView()
                .tabItem {
                    Label(SettingsTab.models.rawValue, systemImage: SettingsTab.models.icon)
                }
                .tag(SettingsTab.models)
            
            PrivacySettingsView()
                .tabItem {
                    Label(SettingsTab.privacy.rawValue, systemImage: SettingsTab.privacy.icon)
                }
                .tag(SettingsTab.privacy)
            
            AdvancedSettingsView()
                .tabItem {
                    Label(SettingsTab.advanced.rawValue, systemImage: SettingsTab.advanced.icon)
                }
                .tag(SettingsTab.advanced)
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var launchAtLogin = false
    @State private var showInMenuBar = true
    @State private var defaultTheme = "System"
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $defaultTheme) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                .pickerStyle(.menu)
            }
            
            Section("Message Display") {
                Toggle("Show model attribution", isOn: $userSettings.showModelAttribution)
                Text("Display which AI model generated each response")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Toggle("Show performance metrics", isOn: $userSettings.showPerformanceMetrics)
                Text("Display token count and response time for each message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in menu bar", isOn: $showInMenuBar)
            }
            
            Section("Updates") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Check for updates automatically")
                        Text("Get notified when new versions are available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check Now") {
                        // TODO: Implement update check
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var defaultModel = "Mistral-7B"
    @State private var maxMemoryUsage = 4.0
    
    var body: some View {
        Form {
            Section("Default Model") {
                Picker("Primary Model", selection: $defaultModel) {
                    Text("Mistral-7B-Instruct").tag("Mistral-7B")
                    Text("CodeLlama-7B").tag("CodeLlama-7B")
                    Text("Phi-2").tag("Phi-2")
                }
                .pickerStyle(.menu)
                
                Text("This model will be used for new workspaces by default")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Intelligent Features") {
                Toggle("Enable intelligent model selection", isOn: $userSettings.enableIntelligentModelSelection)
                Text("Automatically choose optimal models based on workspace context")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Toggle("Enable workspace optimization", isOn: $userSettings.enableWorkspaceAutoOptimization)
                Text("Automatically optimize settings for detected workspace types")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Performance") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Max Memory Usage")
                        Spacer()
                        Text("\(maxMemoryUsage, specifier: "%.1f") GB")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $maxMemoryUsage, in: 1.0...8.0, step: 0.5)
                }
            }
            
            Section("Model Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Installed Models")
                        Text("Manage your local AI models")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Manage...") {
                        // TODO: Open model manager
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PrivacySettingsView: View {
    @State private var encryptData = true
    @State private var deleteDataOnExit = false
    @State private var allowTelemetry = false
    
    var body: some View {
        Form {
            Section("Data Protection") {
                Toggle("Encrypt local data", isOn: $encryptData)
                Toggle("Delete conversation data on exit", isOn: $deleteDataOnExit)
                
                Text("All data is stored locally and never sent to external servers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Analytics") {
                Toggle("Send anonymous usage data", isOn: $allowTelemetry)
                
                Text("Helps improve Arcana without compromising your privacy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Data Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Export All Data")
                        Text("Create a backup of all your projects and settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Export...") {
                        // TODO: Implement data export
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Clear All Data")
                        Text("Permanently delete all projects and conversations")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Button("Clear...") {
                        // TODO: Implement data clearing
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AdvancedSettingsView: View {
    @State private var enableDebugMode = false
    @State private var logLevel = "Info"
    @State private var customModelPath = ""
    
    var body: some View {
        Form {
            Section("Debugging") {
                Toggle("Enable debug mode", isOn: $enableDebugMode)
                
                Picker("Log Level", selection: $logLevel) {
                    Text("Error").tag("Error")
                    Text("Warning").tag("Warning")
                    Text("Info").tag("Info")
                    Text("Debug").tag("Debug")
                }
                .pickerStyle(.menu)
                .disabled(!enableDebugMode)
            }
            
            Section("Advanced Model Settings") {
                HStack {
                    Text("Custom Model Directory")
                    Spacer()
                    TextField("Path", text: $customModelPath)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    Button("Browse") {
                        // TODO: Implement directory picker
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("Experimental Features") {
                VStack(alignment: .leading) {
                    Text("⚠️ Experimental features may be unstable")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    // Placeholder for future experimental features
                    Text("No experimental features available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
