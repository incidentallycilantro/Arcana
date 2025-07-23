// MainView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct MainView: View {
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationSplitView {
            ProjectSidebar(selectedProject: $selectedProject)
                .frame(minWidth: 250)
        } detail: {
            if let project = selectedProject {
                ChatView(project: project)
                    .id(project.id) // Force refresh when project changes
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            // Auto-select first project for testing
            if selectedProject == nil {
                selectedProject = Project.sampleProjects.first
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
            
            Text("Welcome to Arcana")
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            Text("Select a project from the sidebar to get started")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainView()
}
