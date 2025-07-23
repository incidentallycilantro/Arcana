// ProjectSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ProjectSidebar: View {
    @Binding var selectedProject: Project?
    @State private var projects: [Project] = Project.sampleProjects
    @State private var searchText = ""
    @State private var showingNewProjectSheet = false
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects.sorted { $0.isPinned && !$1.isPinned }
        } else {
            return projects.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Projects")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingNewProjectSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search projects...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            // Projects List
            List(filteredProjects, id: \.id, selection: $selectedProject) { project in
                ProjectRow(project: project)
                    .listRowInsets(EdgeInsets())
                    .contextMenu {
                        Button("Pin Project") {
                            togglePin(for: project)
                        }
                        Button("Duplicate") {
                            duplicateProject(project)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteProject(project)
                        }
                    }
            }
            .listStyle(.sidebar)
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(projects: $projects)
        }
    }
    
    private func togglePin(for project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isPinned.toggle()
        }
    }
    
    private func duplicateProject(_ project: Project) {
        var newProject = project
        newProject.title += " Copy"
        projects.append(newProject)
    }
    
    private func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = nil
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
    }
}

struct NewProjectSheet: View {
    @Binding var projects: [Project]
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newProject = Project(title: title, description: description)
                        projects.append(newProject)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ProjectSidebar(selectedProject: .constant(nil))
        .frame(width: 300, height: 600)
}
