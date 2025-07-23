// MainView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct MainView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingInspector = false
    @State private var showingSmartGutter = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Chat Area
            NavigationSplitView {
                ProjectSidebar(selectedProject: $workspaceManager.selectedWorkspace)
                    .frame(minWidth: 250, maxWidth: 350)
            } detail: {
                if let workspace = workspaceManager.selectedWorkspace {
                    ChatView(project: workspace)
                } else {
                    WelcomeView()
                }
            }
            
            // Smart Gutter (contextual tools)
            if showingSmartGutter && workspaceManager.selectedWorkspace != nil {
                SmartGutterView(workspace: workspaceManager.selectedWorkspace!)
                    .frame(width: 60)
                    .transition(.move(edge: .trailing))
            }
            
            // Inspector Panel
            if showingInspector && workspaceManager.selectedWorkspace != nil {
                InspectorView(workspace: workspaceManager.selectedWorkspace!)
                    .frame(minWidth: 250, maxWidth: 300)
                    .transition(.move(edge: .trailing))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if workspaceManager.selectedWorkspace != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingInspector.toggle()
                        }
                    }) {
                        Image(systemName: showingInspector ? "sidebar.right" : "sidebar.right")
                            .foregroundColor(showingInspector ? .blue : .primary)
                    }
                    .help("Toggle Inspector")
                    
                    Button(action: { createNewThread() }) {
                        Image(systemName: "plus.bubble")
                    }
                    .help("New Thread")
                }
                
                Button(action: { showNewWorkspaceSheet() }) {
                    Image(systemName: "plus.rectangle.on.folder")
                }
                .help("New Workspace")
            }
        }
        .onChange(of: workspaceManager.selectedWorkspace) { _ in
            updateSmartGutter()
        }
        .onAppear {
            updateSmartGutter()
        }
    }
    
    private func createNewThread() {
        // TODO: Implement new thread creation in current workspace
        print("Creating new thread in current workspace")
    }
    
    private func showNewWorkspaceSheet() {
        workspaceManager.showNewWorkspaceSheet = true
    }
    
    private func updateSmartGutter() {
        guard let workspace = workspaceManager.selectedWorkspace else {
            showingSmartGutter = false
            return
        }
        
        let workspaceType = workspaceManager.getWorkspaceType(for: workspace)
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSmartGutter = workspaceType != .general
        }
    }
}

struct WelcomeView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Arcana")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                Text("Design a dedicated space for focused AI collaboration")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    workspaceManager.showNewWorkspaceSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your First Workspace")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    // TODO: Open getting started guide
                }) {
                    Text("Learn More")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct InspectorView: View {
    let workspace: Project
    @State private var selectedTab = 0
    
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
            
            Divider()
            
            // Tab Selector
            Picker("Inspector Tab", selection: $selectedTab) {
                Text("Info").tag(0)
                Text("Assistant").tag(1)
                Text("Performance").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tab Content
            ScrollView {
                Group {
                    switch selectedTab {
                    case 0:
                        ProjectInfoView(workspace: workspace)
                    case 1:
                        AssistantConfigView(workspace: workspace)
                    case 2:
                        PerformanceView()
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ProjectInfoView: View {
    let workspace: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Workspace Details")
                    .font(.headline)
                
                Group {
                    HStack {
                        Text("Created:")
                        Spacer()
                        Text(workspace.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Modified:")
                        Spacer()
                        Text(workspace.lastModified, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Threads:")
                        Spacer()
                        Text("1") // TODO: Count actual threads
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.headline)
                
                Button("Export Workspace") {
                    // TODO: Implement export
                }
                .buttonStyle(.bordered)
                
                Button("Duplicate Workspace") {
                    // TODO: Implement duplicate
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
}

struct AssistantConfigView: View {
    let workspace: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Configuration")
                    .font(.headline)
                
                HStack {
                    Text("Current Model:")
                    Spacer()
                    Text("Mistral-7B")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Performance:")
                    Spacer()
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Optimal")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Assistant Behavior")
                    .font(.headline)
                
                // TODO: Add assistant configuration options
                Text("Configuration options will appear here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PerformanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("System Performance")
                    .font(.headline)
                
                HStack {
                    Text("Memory Usage:")
                    Spacer()
                    Text("2.1 GB")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                
                HStack {
                    Text("Response Time:")
                    Spacer()
                    Text("0.8s avg")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            
            Spacer()
        }
    }
}

#Preview {
    MainView()
}
