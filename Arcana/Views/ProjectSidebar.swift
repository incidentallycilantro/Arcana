// ProjectSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ProjectSidebar: View {
    @Binding var selectedProject: Project?
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var searchText = ""
    
    var filteredProjects: [Project] {
        let projects = workspaceManager.workspaces
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - NO SIDEBAR TOGGLE (using native macOS toggle only)
            HStack {
                Text("Workspaces")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    workspaceManager.showNewWorkspaceSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("New Workspace")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search - Reduced top padding to fix new workspace visibility
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search workspaces...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            // Projects List - Fixed insets for proper visibility
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredProjects, id: \.id) { project in
                        ProjectRow(
                            project: project,
                            isSelected: selectedProject?.id == project.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProject = project
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
                                if selectedProject?.id == project.id {
                                    selectedProject = nil
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4) // Small top padding for first item visibility
            }
        }
        .sheet(isPresented: $workspaceManager.showNewWorkspaceSheet) {
            NewProjectSheet { title, description in
                let newWorkspace = workspaceManager.createWorkspace(title: title, description: description)
                selectedProject = newWorkspace
            }
        }
        .onAppear {
            // Ensure the first workspace is visible
            if let firstWorkspace = workspaceManager.workspaces.first, selectedProject == nil {
                selectedProject = firstWorkspace
                workspaceManager.selectedWorkspace = firstWorkspace
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    let isSelected: Bool
    
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
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
            
            Text(project.lastModified, style: .relative)
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.6) : .secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}

#Preview {
    ProjectSidebar(selectedProject: .constant(nil))
        .frame(width: 300, height: 600)
}
