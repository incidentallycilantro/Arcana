// ProjectSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ProjectSidebar: View {
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @State private var searchText = ""
    @State private var showingNewProjectSheet = false
    
    var filteredProjects: [Project] {
        workspaceManager.filteredWorkspaces(searchText: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workspaces")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingNewProjectSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search workspaces...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            // Workspaces List
            List(selection: $workspaceManager.selectedWorkspace) {
                ForEach(filteredProjects) { project in
                    ProjectRow(project: project)
                        .listRowInsets(EdgeInsets())
                        .contentShape(Rectangle())
                        .onTapGesture {
                            workspaceManager.selectedWorkspace = project
                        }
                        .contextMenu {
                            Button(project.isPinned ? "Unpin Workspace" : "Pin Workspace") {
                                workspaceManager.togglePin(for: project)
                            }
                            Button("Duplicate") {
                                workspaceManager.duplicateWorkspace(project)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                workspaceManager.deleteWorkspace(project)
                            }
                        }
                        .tag(project)
                }
            }
            .listStyle(.sidebar)
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet { newProject in
                workspaceManager.createWorkspace(title: newProject.title, description: newProject.description)
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if project.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text(project.lastModified, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())  // Makes entire row tappable
    }
}

#Preview {
    ProjectSidebar()
        .environmentObject(WorkspaceManager.shared)
        .frame(width: 300, height: 600)
}
