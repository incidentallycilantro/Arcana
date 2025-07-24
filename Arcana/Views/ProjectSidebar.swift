// ProjectSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ProjectSidebar: View {
    @Binding var selectedProject: Project?
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var searchText = ""
    @State private var showingStorageInfo = false
    
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
    
    var organizedProjects: [(String, [Project])] {
        let projects = filteredProjects
        
        // Group intelligently
        var grouped: [(String, [Project])] = []
        
        // Pinned workspaces first
        let pinnedProjects = projects.filter { $0.isPinned }
        if !pinnedProjects.isEmpty {
            grouped.append(("Pinned", pinnedProjects))
        }
        
        // Recent workspaces (modified in last 7 days)
        let recentProjects = projects.filter {
            !$0.isPinned &&
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains($0.lastModified) == true
        }
        if !recentProjects.isEmpty {
            grouped.append(("Recent", recentProjects))
        }
        
        // Remaining workspaces by type
        let remainingProjects = projects.filter { project in
            !pinnedProjects.contains(where: { $0.id == project.id }) &&
            !recentProjects.contains(where: { $0.id == project.id })
        }
        
        if !remainingProjects.isEmpty {
            // Group by type
            let typeGroups = Dictionary(grouping: remainingProjects) { project in
                workspaceManager.getWorkspaceType(for: project)
            }
            
            // Add type groups in order of frequency
            let sortedTypes: [WorkspaceManager.WorkspaceType] = [.code, .creative, .research, .general]
            for type in sortedTypes {
                if let projectsOfType = typeGroups[type], !projectsOfType.isEmpty {
                    grouped.append((type.displayName, projectsOfType))
                }
            }
        }
        
        return grouped
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workspaces")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !workspaceManager.workspaces.isEmpty {
                        Text("\(workspaceManager.workspaces.count) active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Storage info button (only when needed)
                    Button(action: {
                        showingStorageInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Storage Information")
                    .opacity(workspaceManager.workspaces.count > 10 ? 1 : 0)
                    
                    Button(action: {
                        workspaceManager.showNewWorkspaceSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("New Workspace")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Clean search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search workspaces...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
            
            // Loading state
            if workspaceManager.isLoadingWorkspaces {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading workspaces...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Ultra-clean workspace list with invisible type indicators
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(organizedProjects, id: \.0) { sectionTitle, projects in
                            Section {
                                ForEach(projects, id: \.id) { project in
                                    InvisibleWorkspaceRow(
                                        project: project,
                                        isSelected: selectedProject?.id == project.id,
                                        workspaceType: workspaceManager.getWorkspaceType(for: project)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectWorkspace(project)
                                    }
                                    .contextMenu {
                                        ProjectContextMenu(
                                            project: project,
                                            isSelected: selectedProject?.id == project.id,
                                            onAction: handleProjectAction
                                        )
                                    }
                                }
                            } header: {
                                if organizedProjects.count > 1 {
                                    SectionHeader(title: sectionTitle, count: projects.count)
                                }
                            }
                        }
                        
                        // Empty state
                        if workspaceManager.workspaces.isEmpty {
                            EmptyWorkspaceState()
                                .padding(.top, 40)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .sheet(isPresented: $workspaceManager.showNewWorkspaceSheet) {
            NewProjectSheet { title, description in
                let newWorkspace = workspaceManager.createWorkspace(title: title, description: description)
                selectedProject = newWorkspace
            }
        }
        .sheet(isPresented: $showingStorageInfo) {
            StorageInfoSheet()
        }
        .onAppear {
            selectInitialWorkspaceIfNeeded()
        }
        // CRITICAL FIX: Force UI update when workspace manager selection changes
        .onChange(of: workspaceManager.selectedWorkspace) {
            selectedProject = workspaceManager.selectedWorkspace
        }
    }
    
    private func selectWorkspace(_ workspace: Project) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedProject = workspace
            workspaceManager.selectedWorkspace = workspace
        }
        
        // Update last modified for usage tracking
        if let index = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaceManager.workspaces[index].updateModified()
        }
    }
    
    private func selectInitialWorkspaceIfNeeded() {
        if selectedProject == nil && !workspaceManager.workspaces.isEmpty {
            // Smart selection: pinned > recent > first
            let intelligentSelection = workspaceManager.workspaces.first { $0.isPinned } ??
                                     workspaceManager.workspaces.max(by: { $0.lastModified < $1.lastModified }) ??
                                     workspaceManager.workspaces.first
            
            if let workspace = intelligentSelection {
                selectWorkspace(workspace)
            }
        }
    }
    
    private func handleProjectAction(_ action: ProjectAction, for project: Project) {
        switch action {
        case .pin:
            workspaceManager.togglePin(for: project)
        case .duplicate:
            workspaceManager.duplicateWorkspace(project)
        case .delete:
            workspaceManager.deleteWorkspace(project)
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
        case .export:
            exportWorkspace(project)
        }
    }
    
    private func exportWorkspace(_ workspace: Project) {
        // TODO: Implement individual workspace export
        print("🚀 Export workspace: \(workspace.title)")
    }
}

struct InvisibleWorkspaceRow: View {
    let project: Project
    let isSelected: Bool
    let workspaceType: WorkspaceManager.WorkspaceType
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Pin indicator only (minimal visual noise)
                if project.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                
                Text(project.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                // Invisible type indicator - only shows on hover or selection
                if isHovered || isSelected {
                    InvisibleWorkspaceTypeIndicator(workspaceType)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// Supporting views remain the same...
struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.regularMaterial)
    }
}

struct ProjectContextMenu: View {
    let project: Project
    let isSelected: Bool
    let onAction: (ProjectAction, Project) -> Void
    
    var body: some View {
        Button(project.isPinned ? "Unpin Workspace" : "Pin Workspace") {
            onAction(.pin, project)
        }
        
        Button("Duplicate") {
            onAction(.duplicate, project)
        }
        
        Button("Export...") {
            onAction(.export, project)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            onAction(.delete, project)
        }
    }
}

enum ProjectAction {
    case pin, duplicate, delete, export
}

struct EmptyWorkspaceState: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                Text("No workspaces yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Create your first workspace to begin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Create Workspace") {
                workspaceManager.showNewWorkspaceSheet = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct StorageInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storageInfo: StorageInfo?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Storage Information")
                .font(.headline)
            
            if let info = storageInfo {
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Size:")
                        Spacer()
                        Text(info.formattedSize)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Files:")
                        Spacer()
                        Text("\(info.fileCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Location:")
                        Spacer()
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: info.directory.path)
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView("Calculating...")
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            loadStorageInfo()
        }
    }
    
    private func loadStorageInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            let persistence = WorkspacePersistenceController()
            let info = persistence.getStorageInfo()
            
            DispatchQueue.main.async {
                storageInfo = info
            }
        }
    }
}

#Preview {
    ProjectSidebar(selectedProject: .constant(nil))
        .frame(width: 300, height: 600)
}
