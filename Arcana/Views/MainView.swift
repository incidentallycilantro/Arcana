// MainView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct MainView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        // Pure two-pane layout - Sidebar + Chat only
        NavigationSplitView {
            ProjectSidebar(selectedProject: $workspaceManager.selectedWorkspace)
                .frame(minWidth: 250, maxWidth: 350)
        } detail: {
            if let workspace = workspaceManager.selectedWorkspace {
                InvisibleChatView(project: workspace)
            } else {
                WelcomeView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()
                
                Button(action: {
                    workspaceManager.showNewWorkspaceSheet = true
                }) {
                    Image(systemName: "plus.rectangle.on.folder")
                }
                .help("New Workspace")
            }
        }
    }
}

struct WelcomeView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Minimalist welcome
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text("Welcome to Arcana")
                        .font(.largeTitle)
                        .fontWeight(.light)
                    
                    Text("Your invisible AI thinking partner")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(action: {
                workspaceManager.showNewWorkspaceSheet = true
            }) {
                Text("Begin Thinking")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainView()
}
