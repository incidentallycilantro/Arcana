// MainView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct MainView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var showingInspector = false  // Default to closed
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showingNewProjectSheet = false
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            ProjectSidebar()
                .environmentObject(workspaceManager)
                .frame(minWidth: 250, maxWidth: 350)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
        } content: {
            if let workspace = workspaceManager.selectedWorkspace {
                ChatView(project: workspace)
                    .frame(minWidth: 400)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600)
            } else {
                WelcomeView()
                    .environmentObject(workspaceManager)
                    .frame(minWidth: 400)
                    .navigationSplitViewColumnWidth(min: 400, ideal: 600)
            }
        } detail: {
            if showingInspector, let workspace = workspaceManager.selectedWorkspace {
                InspectorView(project: workspace)
                    .frame(minWidth: 250, maxWidth: 300)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 300)
            } else {
                // Always provide a detail view, but make it invisible when not needed
                Color.clear
                    .frame(width: 0)
                    .navigationSplitViewColumnWidth(0)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Always show New Workspace button
                Button(action: { showingNewProjectSheet = true }) {
                    Image(systemName: "plus.rectangle.on.folder")
                }
                .help("New Workspace")
                
                // Only show these when a workspace is selected
                if workspaceManager.selectedWorkspace != nil {
                    Button(action: toggleInspector) {
                        Image(systemName: "sidebar.right")
                            .foregroundStyle(showingInspector ? .blue : .primary)
                    }
                    .help("Toggle Inspector")
                    
                    Button(action: newChat) {
                        Image(systemName: "plus.bubble")
                    }
                    .help("New Thread")
                }
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet { newProject in
                workspaceManager.createWorkspace(title: newProject.title, description: newProject.description)
            }
        }
        .focusedSceneObject(appState)
        .onChange(of: appState.shouldShowNewProject) { _, shouldShow in
            if shouldShow {
                showingNewProjectSheet = true
                appState.shouldShowNewProject = false
            }
        }
        .onChange(of: appState.shouldToggleSidebar) { _, shouldToggle in
            if shouldToggle {
                toggleSidebar()
                appState.shouldToggleSidebar = false
            }
        }
        .onChange(of: appState.shouldToggleInspector) { _, shouldToggle in
            if shouldToggle {
                toggleInspector()
                appState.shouldToggleInspector = false
            }
        }
    }
    
    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.25)) {
            sidebarVisibility = sidebarVisibility == .detailOnly ? .automatic : .detailOnly
        }
    }
    
    private func toggleInspector() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showingInspector.toggle()
        }
    }
    
    private func newProject() {
        showingNewProjectSheet = true
    }
    
    private func newChat() {
        // TODO: Implement new chat functionality in current workspace
        print("New thread in workspace: \(workspaceManager.selectedWorkspace?.title ?? "Unknown")")
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @State private var showingNewWorkspaceSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon/Logo Area
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 8) {
                    Text("Welcome to Arcana")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                    
                    Text("Your privacy-first AI assistant")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Quick Actions
            VStack(spacing: 12) {
                Button(action: { showingNewWorkspaceSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Workspace")
                    }
                    .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: { showingNewWorkspaceSheet = true }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Import Workspace")
                    }
                    .frame(maxWidth: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            // Recent Projects Preview (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Workspaces")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Your recent workspaces will appear here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
        .sheet(isPresented: $showingNewWorkspaceSheet) {
            NewProjectSheet { newProject in
                workspaceManager.createWorkspace(title: newProject.title, description: newProject.description)
            }
        }
    }
}

struct InspectorView: View {
    let project: Project
    @State private var selectedTab: InspectorTab = .projectInfo
    
    enum InspectorTab: String, CaseIterable {
        case projectInfo = "Project"
        case assistant = "Assistant"
        case performance = "Performance"
        
        var icon: String {
            switch self {
            case .projectInfo: return "info.circle"
            case .assistant: return "brain.head.profile"
            case .performance: return "speedometer"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Inspector Header
            HStack {
                Text("Inspector")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            
            // Tab Picker
            Picker("Inspector Tab", selection: $selectedTab) {
                ForEach(InspectorTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
                .padding(.top, 8)
            
            // Tab Content
            ScrollView {
                switch selectedTab {
                case .projectInfo:
                    ProjectInfoView(project: project)
                case .assistant:
                    AssistantConfigView(project: project)
                case .performance:
                    PerformanceView(project: project)
                }
            }
        }
    }
}

struct ProjectInfoView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Project Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Details")
                    .font(.headline)
                
                LabeledContent("Name", value: project.title)
                LabeledContent("Description", value: project.description.isEmpty ? "No description" : project.description)
                LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Modified", value: project.lastModified.formatted(date: .abbreviated, time: .shortened))
            }
            
            Divider()
            
            // Statistics (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)
                
                LabeledContent("Messages", value: "12")
                LabeledContent("Files", value: "3")
                LabeledContent("Total Tokens", value: "2,847")
            }
            
            Divider()
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Actions")
                    .font(.headline)
                
                Button("Export Project") {
                    // TODO: Implement export
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Duplicate Project") {
                    // TODO: Implement duplicate
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

struct AssistantConfigView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assistant Configuration")
                .font(.headline)
            
            // Model Selection (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Model")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Mistral-7B-Instruct-v0.1 (Q4_K_M)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            
            Divider()
            
            // Performance Metrics (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LabeledContent("Avg Response Time", value: "1.2s")
                LabeledContent("Tokens/Second", value: "24.7")
                LabeledContent("Memory Usage", value: "2.1 GB")
            }
        }
        .padding()
    }
}

struct PerformanceView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
            
            // System Resources
            VStack(alignment: .leading, spacing: 8) {
                Text("System Resources")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 4) {
                    HStack {
                        Text("RAM Usage")
                        Spacer()
                        Text("2.1 GB / 8 GB")
                    }
                    .font(.caption)
                    
                    ProgressView(value: 0.26)
                        .progressViewStyle(.linear)
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("CPU Usage")
                        Spacer()
                        Text("12%")
                    }
                    .font(.caption)
                    
                    ProgressView(value: 0.12)
                        .progressViewStyle(.linear)
                }
            }
            
            Divider()
            
            // Model Performance
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LabeledContent("Inference Speed", value: "24.7 tok/s")
                LabeledContent("Cache Hit Rate", value: "78%")
                LabeledContent("Speculative Accuracy", value: "65%")
            }
        }
        .padding()
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 800)
}
