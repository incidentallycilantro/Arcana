// ContextualSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ContextualSidebar: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack {
                Text("Conversations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    threadManager.createInstantThread()
                }) {
                    Image(systemName: "plus.message")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("New Conversation")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search conversations...", text: $searchText)
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
            
            // Contextual organization
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    
                    // Recent/Instant conversations
                    if !threadManager.recentThreads.isEmpty {
                        Section {
                            ForEach(filteredRecentThreads) { thread in
                                ThreadRow(
                                    thread: thread,
                                    isActive: threadManager.activeThread?.id == thread.id
                                )
                                .onTapGesture {
                                    threadManager.activeThread = thread
                                }
                                .contextMenu {
                                    ThreadContextMenu(thread: thread)
                                }
                            }
                        } header: {
                            SectionHeader(title: "Recent", count: filteredRecentThreads.count)
                        }
                    }
                    
                    // Project workspaces with their threads
                    ForEach(workspaceManager.workspaces, id: \.id) { project in
                        let projectThreads = threadManager.getThreadsForProject(project.id)
                        
                        if !projectThreads.isEmpty || workspaceManager.selectedWorkspace?.id == project.id {
                            Section {
                                // Project header row
                                ProjectHeaderRow(
                                    project: project,
                                    threadCount: projectThreads.count,
                                    isSelected: workspaceManager.selectedWorkspace?.id == project.id
                                )
                                .onTapGesture {
                                    selectProject(project)
                                }
                                .contextMenu {
                                    ProjectContextMenu(project: project)
                                }
                                
                                // Project threads (if any)
                                ForEach(filteredProjectThreads(projectThreads)) { thread in
                                    ThreadRow(
                                        thread: thread,
                                        isActive: threadManager.activeThread?.id == thread.id,
                                        isProjectThread: true
                                    )
                                    .onTapGesture {
                                        workspaceManager.selectedWorkspace = project
                                        threadManager.activeThread = thread
                                    }
                                    .contextMenu {
                                        ThreadContextMenu(thread: thread)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Empty state
                    if threadManager.recentThreads.isEmpty && workspaceManager.workspaces.isEmpty {
                        EmptyConversationState()
                            .padding(.top, 40)
                    }
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: $workspaceManager.showNewWorkspaceSheet) {
            NewProjectSheet { title, description in
                let newProject = workspaceManager.createWorkspace(title: title, description: description)
                let thread = threadManager.createProjectThread(for: newProject)
                workspaceManager.selectedWorkspace = newProject
                threadManager.activeThread = thread
            }
        }
        .sheet(isPresented: $threadManager.showProjectPromotionSuggestion) {
            if let suggestion = threadManager.promotionSuggestion {
                ProjectPromotionSheet(suggestion: suggestion)
            }
        }
    }
    
    private var filteredRecentThreads: [ConversationThread] {
        if searchText.isEmpty {
            return threadManager.recentThreads
        } else {
            return threadManager.recentThreads.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func filteredProjectThreads(_ threads: [ConversationThread]) -> [ConversationThread] {
        if searchText.isEmpty {
            return threads
        } else {
            return threads.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func selectProject(_ project: Project) {
        workspaceManager.selectedWorkspace = project
        
        // Get or create a thread for this project
        let projectThreads = threadManager.getThreadsForProject(project.id)
        if let mostRecentThread = projectThreads.first {
            threadManager.activeThread = mostRecentThread
        } else {
            let newThread = threadManager.createProjectThread(for: project)
            threadManager.activeThread = newThread
        }
    }
}

struct ThreadRow: View {
    let thread: ConversationThread
    let isActive: Bool
    var isProjectThread: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thread type indicator
            Image(systemName: isProjectThread ? "bubble.left.and.bubble.right" : "message")
                .font(.caption)
                .foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(thread.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(isActive ? .white : .primary)
                
                if let lastMessage = thread.messages.last {
                    Text(lastMessage.content)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(isActive ? .white.opacity(0.7) : .secondary)
                }
                
                // Thread metadata
                HStack(spacing: 8) {
                    Text(thread.lastModified, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(isActive ? .white.opacity(0.6) : .secondary)
                    
                    if !thread.messages.isEmpty {
                        Text("• \(thread.messages.count) messages")
                            .font(.caption2)
                            .foregroundStyle(isActive ? .white.opacity(0.6) : .secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, isProjectThread ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}

struct ProjectHeaderRow: View {
    let project: Project
    let threadCount: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Project type indicator
            InvisibleWorkspaceTypeIndicator(
                WorkspaceManager.shared.getWorkspaceType(for: project)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            
            Spacer()
            
            if threadCount > 0 {
                Text("\(threadCount)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white.opacity(0.2) : Color.secondary.opacity(0.1))
                    )
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Button(action: {
                let thread = ThreadManager.shared.createProjectThread(for: project)
                ThreadManager.shared.activeThread = thread
            }) {
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .buttonStyle(.plain)
            .help("New Thread")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .padding(.horizontal, 8)
    }
}

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

struct ThreadContextMenu: View {
    let thread: ConversationThread
    
    var body: some View {
        if thread.type == .instant {
            Button("Promote to Project") {
                // Trigger promotion evaluation
                ThreadManager.shared.evaluateForProjectPromotion(thread)
            }
        }
        
        Button("Rename") {
            // TODO: Implement rename
        }
        
        Button("Duplicate") {
            // TODO: Implement duplicate
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            ThreadManager.shared.deleteThread(thread)
        }
    }
}

struct ProjectContextMenu: View {
    let project: Project
    
    var body: some View {
        Button("New Thread") {
            let thread = ThreadManager.shared.createProjectThread(for: project)
            ThreadManager.shared.activeThread = thread
        }
        
        Button(project.isPinned ? "Unpin Project" : "Pin Project") {
            WorkspaceManager.shared.togglePin(for: project)
        }
        
        Button("Duplicate") {
            WorkspaceManager.shared.duplicateWorkspace(project)
        }
        
        Button("Export...") {
            // TODO: Implement export
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            WorkspaceManager.shared.deleteWorkspace(project)
        }
    }
}

struct EmptyConversationState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                Text("No conversations yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Start chatting to begin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Start Conversation") {
                ThreadManager.shared.createInstantThread()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContextualSidebar()
        .frame(width: 300, height: 600)
}
