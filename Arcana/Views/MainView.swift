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
            } else {
                WelcomeView()
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
            
            Text("Create a new project to get started")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainView()
}
