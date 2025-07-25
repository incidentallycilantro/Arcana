// FluidSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct FluidSidebar: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    private let intelligenceEngine = IntelligenceEngine.shared
    
    @State private var searchText = ""
    @State private var showingNewWorkspaceSheet = false
    
    var filteredItems: [SidebarItem] {
        let allItems = generateSidebarItems()
        
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean, unified header
            FluidSidebarHeader(
                searchText: $searchText,
                onNewConversation: { threadManager.createNewThread() }
            )
            
            Divider()
            
            // Revolutionary fluid content
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        FluidItemView(
                            item: item,
                            isSelected: isSelected(item),
                            onTap: { selectItem(item) },
                            onPromote: { promoteToWorkspace(item) },
                            onAction: { action in handleItemAction(action, for: item) }
                        )
                        .contentShape(Rectangle())
                    }
                    
                    if filteredItems.isEmpty {
                        FluidEmptyState(onCreateWorkspace: {
                            showingNewWorkspaceSheet = true
                        })
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingNewWorkspaceSheet) {
            NewProjectSheet { title, description in
                let _ = workspaceManager.createWorkspace(title: title, description: description)
            }
        }
    }
    
    // MARK: - Sidebar Intelligence
    
    private func generateSidebarItems() -> [SidebarItem] {
        var items: [SidebarItem] = []
        
        // Active conversations (evolving threads)
        let conversations = threadManager.threads.map { thread in
            SidebarItem(
                id: thread.id.uuidString,
                type: thread.shouldPromoteToWorkspace ? .evolvingConversation : .conversation,
                title: thread.displayTitle,
                summary: generateSmartSummary(for: thread),
                lastActivity: thread.lastActivity,
                messageCount: thread.messages.count,
                workspaceType: thread.detectedType,
                promotionEligibility: thread.promotionEligibility,
                associatedThread: thread,
                associatedWorkspace: nil
            )
        }
        
        // Established workspaces with their threads
        let workspaces = workspaceManager.workspaces.map { workspace in
            let relatedThreads = threadManager.threads.filter { $0.workspaceId == workspace.id }
            
            return SidebarItem(
                id: workspace.id.uuidString,
                type: .workspace,
                title: workspace.title,
                summary: workspace.description,
                lastActivity: formatDate(workspace.lastModified),
                messageCount: relatedThreads.reduce(0) { $0 + $1.messages.count },
                workspaceType: workspaceManager.getWorkspaceType(for: workspace),
                promotionEligibility: 1.0,
                associatedThread: nil,
                associatedWorkspace: workspace,
                nestedThreads: relatedThreads
            )
        }
        
        items.append(contentsOf: conversations)
        items.append(contentsOf: workspaces)
        
        // Sort by importance and recency
        return items.sorted { lhs, rhs in
            // Workspaces first
            if lhs.type == .workspace && rhs.type != .workspace {
                return true
            }
            if rhs.type == .workspace && lhs.type != .workspace {
                return false
            }
            
            // Then by promotion eligibility
            if lhs.promotionEligibility != rhs.promotionEligibility {
                return lhs.promotionEligibility > rhs.promotionEligibility
            }
            
            // Finally by activity
            return lhs.lastActivity > rhs.lastActivity
        }
    }
    
    private func generateSmartSummary(for thread: ChatThread) -> String {
        guard !thread.messages.isEmpty else { return "Ready to start chatting" }
        
        let userMessages = thread.messages.filter { $0.role == .user }
        let recentContent = userMessages.suffix(3).map { $0.content }.joined(separator: " ")
        
        // Generate context-aware summary
        switch thread.detectedType {
        case .code:
            if recentContent.lowercased().contains("error") || recentContent.lowercased().contains("bug") {
                return "Debugging and troubleshooting discussion"
            } else if recentContent.lowercased().contains("implement") || recentContent.lowercased().contains("build") {
                return "Implementation planning and development"
            } else {
                return "Technical discussion and code review"
            }
            
        case .creative:
            if recentContent.lowercased().contains("story") || recentContent.lowercased().contains("character") {
                return "Creative storytelling and character development"
            } else if recentContent.lowercased().contains("write") || recentContent.lowercased().contains("draft") {
                return "Writing and content creation"
            } else {
                return "Creative brainstorming and ideation"
            }
            
        case .research:
            if recentContent.lowercased().contains("analyze") || recentContent.lowercased().contains("data") {
                return "Data analysis and research findings"
            } else if recentContent.lowercased().contains("study") || recentContent.lowercased().contains("investigate") {
                return "Research methodology and investigation"
            } else {
                return "Research and fact-finding discussion"
            }
            
        case .general:
            if thread.messages.count < 3 {
                return "Getting started with exploration"
            } else {
                return "General discussion and collaboration"
            }
        }
    }
    
    private func isSelected(_ item: SidebarItem) -> Bool {
        if let thread = item.associatedThread {
            return threadManager.selectedThread?.id == thread.id
        } else if let workspace = item.associatedWorkspace {
            return workspaceManager.selectedWorkspace?.id == workspace.id
        }
        return false
    }
    
    private func selectItem(_ item: SidebarItem) {
        if let thread = item.associatedThread {
            threadManager.selectThread(thread)
        } else if let workspace = item.associatedWorkspace {
            workspaceManager.selectedWorkspace = workspace
        }
    }
    
    private func promoteToWorkspace(_ item: SidebarItem) {
        guard let thread = item.associatedThread else { return }
        threadManager.promoteThreadToWorkspace(thread)
    }
    
    private func handleItemAction(_ action: FluidItemAction, for item: SidebarItem) {
        switch action {
        case .promote:
            promoteToWorkspace(item)
        case .rename:
            // TODO: Implement rename
            break
        case .duplicate:
            if let workspace = item.associatedWorkspace {
                workspaceManager.duplicateWorkspace(workspace)
            }
        case .delete:
            if let thread = item.associatedThread {
                threadManager.deleteThread(thread)
            } else if let workspace = item.associatedWorkspace {
                workspaceManager.deleteWorkspace(workspace)
            }
        case .export:
            // TODO: Implement export
            break
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sidebar Header

struct FluidSidebarHeader: View {
    @Binding var searchText: String
    let onNewConversation: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Arcana")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Intelligence at work")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onNewConversation) {
                    Image(systemName: "plus.message")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("New Conversation")
            }
            
            // Unified search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search conversations and workspaces...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}

// MARK: - Fluid Item View

struct FluidItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let onTap: () -> Void
    let onPromote: () -> Void
    let onAction: (FluidItemAction) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main item content
            itemContent
            
            // Nested threads for workspaces
            if item.type == .workspace, let nestedThreads = item.nestedThreads, !nestedThreads.isEmpty {
                nestedThreadsView(nestedThreads)
            }
        }
        .background(itemBackground)
        .padding(.horizontal, 8)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            FluidItemContextMenu(item: item, onAction: onAction)
        }
    }
    
    // FIXED: Broken down into separate computed properties to avoid compiler timeout
    private var itemContent: some View {
        HStack(alignment: .top, spacing: 12) {
            // Visual evolution indicator
            EvolutionIndicator(
                type: item.type,
                workspaceType: item.workspaceType,
                eligibility: item.promotionEligibility
            )
            
            // Content
            itemTextContent
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
    
    private var itemTextContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            itemHeader
            
            // Smart summary
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Metadata
            itemMetadata
        }
    }
    
    private var itemHeader: some View {
        HStack {
            Text(item.title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Spacer()
            
            // Promotion hint
            if item.type == .evolvingConversation {
                Button("Promote", action: onPromote)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
    }
    
    private var itemMetadata: some View {
        HStack(spacing: 8) {
            Text("\(item.messageCount) message\(item.messageCount == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
            
            Text("•")
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
            
            Text(item.lastActivity)
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
        }
    }
    
    private var itemBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue : (isHovered ? Color.black.opacity(0.05) : Color.clear))
    }
    
    private func nestedThreadsView(_ nestedThreads: [ChatThread]) -> some View {
        VStack(spacing: 4) {
            ForEach(nestedThreads.prefix(3), id: \.id) { thread in
                NestedThreadView(thread: thread, isParentSelected: isSelected)
            }
            
            if nestedThreads.count > 3 {
                Text("+ \(nestedThreads.count - 3) more conversations")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 24)
                    .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Evolution Indicator

struct EvolutionIndicator: View {
    let type: SidebarItemType
    let workspaceType: WorkspaceManager.WorkspaceType
    let eligibility: Double
    
    var body: some View {
        VStack(spacing: 4) {
            // Main type indicator
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: indicatorSize, height: indicatorSize)
                
                Text(workspaceType.emoji)
                    .font(.system(size: emojiSize))
            }
            
            // Evolution progress
            if type == .evolvingConversation {
                Rectangle()
                    .fill(.orange.opacity(0.6))
                    .frame(width: 2, height: 8)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .conversation:
            return .gray.opacity(0.2)
        case .evolvingConversation:
            return .orange.opacity(0.2)
        case .workspace:
            return workspaceType == .code ? .blue.opacity(0.2) :
                   workspaceType == .creative ? .purple.opacity(0.2) :
                   workspaceType == .research ? .green.opacity(0.2) :
                   .gray.opacity(0.2)
        }
    }
    
    private var indicatorSize: CGFloat {
        switch type {
        case .conversation: return 24
        case .evolvingConversation: return 28
        case .workspace: return 32
        }
    }
    
    private var emojiSize: CGFloat {
        switch type {
        case .conversation: return 10
        case .evolvingConversation: return 12
        case .workspace: return 14
        }
    }
}

// MARK: - Nested Thread View

struct NestedThreadView: View {
    let thread: ChatThread
    let isParentSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 2, height: 16)
            
            Text(thread.displayTitle)
                .font(.caption)
                .foregroundStyle(isParentSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(thread.messages.count)")
                .font(.caption2)
                .foregroundStyle(isParentSelected ? .white.opacity(0.6) : Color.secondary.opacity(0.8))
        }
        .padding(.leading, 24)
        .padding(.trailing, 12)
        .padding(.vertical, 2)
    }
}

// MARK: - Context Menu

struct FluidItemContextMenu: View {
    let item: SidebarItem
    let onAction: (FluidItemAction) -> Void
    
    var body: some View {
        if item.type == .evolvingConversation {
            Button("Promote to Workspace") {
                onAction(.promote)
            }
            
            Divider()
        }
        
        Button("Rename") {
            onAction(.rename)
        }
        
        if item.type == .workspace {
            Button("Duplicate") {
                onAction(.duplicate)
            }
        }
        
        Button("Export...") {
            onAction(.export)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            onAction(.delete)
        }
    }
}

// MARK: - Empty State

struct FluidEmptyState: View {
    let onCreateWorkspace: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Intelligence at rest")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Start a conversation and watch your ideas organize themselves")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Workspace") {
                onCreateWorkspace()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Data Models

struct SidebarItem: Identifiable {
    let id: String
    let type: SidebarItemType
    let title: String
    let summary: String
    let lastActivity: String
    let messageCount: Int
    let workspaceType: WorkspaceManager.WorkspaceType
    let promotionEligibility: Double
    let associatedThread: ChatThread?
    let associatedWorkspace: Project?
    let nestedThreads: [ChatThread]?
    
    init(id: String, type: SidebarItemType, title: String, summary: String, lastActivity: String, messageCount: Int, workspaceType: WorkspaceManager.WorkspaceType, promotionEligibility: Double, associatedThread: ChatThread?, associatedWorkspace: Project?, nestedThreads: [ChatThread]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.summary = summary
        self.lastActivity = lastActivity
        self.messageCount = messageCount
        self.workspaceType = workspaceType
        self.promotionEligibility = promotionEligibility
        self.associatedThread = associatedThread
        self.associatedWorkspace = associatedWorkspace
        self.nestedThreads = nestedThreads
    }
}

enum SidebarItemType {
    case conversation
    case evolvingConversation
    case workspace
}

enum FluidItemAction {
    case promote
    case rename
    case duplicate
    case delete
    case export
}
