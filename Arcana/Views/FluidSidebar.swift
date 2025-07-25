//
// FluidSidebar.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Fluid Interface with Invisible Intelligence
//

import SwiftUI

struct FluidSidebar: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var userSettings = UserSettings.shared
    
    @Binding var selectedItem: SidebarItem?
    @State private var hoveredItem: SidebarItem?
    @State private var searchText = ""
    @State private var showingNewItemDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and new item
            VStack(spacing: 12) {
                HStack {
                    Text("Arcana")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button {
                        showingNewItemDialog = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("New conversation or workspace")
                }
                
                // Intelligent search
                SearchField(text: $searchText, placeholder: "Search conversations...")
            }
            .padding()
            
            Divider()
            
            // Dynamic content with invisible intelligence
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(organizedItems, id: \.0) { sectionTitle, items in
                        Section {
                            ForEach(items, id: \.id) { item in
                                FluidSidebarRow(
                                    item: item,
                                    isSelected: selectedItem?.id == item.id,
                                    isHovered: hoveredItem?.id == item.id
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectItem(item)
                                }
                                .onHover { hovering in
                                    hoveredItem = hovering ? item : nil
                                }
                                .contextMenu {
                                    SidebarContextMenu(item: item)
                                }
                            }
                        } header: {
                            if organizedItems.count > 1 {
                                // Note: SectionHeader is defined in ProjectSidebar.swift as a shared component
                                HStack {
                                    Text(sectionTitle)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(items.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.regularMaterial)
                            }
                        }
                    }
                    
                    // Empty state
                    if organizedItems.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    }
                }
            }
            
            Spacer()
            
            // Status and intelligence indicators
            if userSettings.showPerformanceMetrics {
                IntelligenceStatusBar()
                    .padding()
            }
        }
        .sheet(isPresented: $showingNewItemDialog) {
            NewItemDialog { itemType in
                createNewItem(type: itemType)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var organizedItems: [(String, [SidebarItem])] {
        let filteredItems = allItems.filter { item in
            searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
        }
        
        // Group by intelligent categories
        let grouped = Dictionary(grouping: filteredItems) { item in
            switch item.type {
            case .workspace:
                return "Workspaces"
            case .conversation:
                return "Recent Conversations"
            case .evolvingConversation:
                return "Evolving Conversations"
            }
        }
        
        // Sort sections by priority
        let sectionOrder = ["Workspaces", "Evolving Conversations", "Recent Conversations"]
        return sectionOrder.compactMap { section in
            guard let items = grouped[section], !items.isEmpty else { return nil }
            return (section, items.sorted { $0.lastActivity > $1.lastActivity })
        }
    }
    
    private var allItems: [SidebarItem] {
        var items: [SidebarItem] = []
        
        // Add workspaces
        for workspace in workspaceManager.workspaces {
            items.append(SidebarItem(
                id: workspace.id,
                title: workspace.title,
                subtitle: workspace.description,
                type: .workspace,
                workspaceType: workspaceManager.getWorkspaceType(for: workspace),
                lastActivity: workspace.lastModified,
                messageCount: 0, // Workspaces don't have direct message counts
                eligibilityScore: 0.0
            ))
        }
        
        // Add threads with intelligent categorization
        for thread in threadManager.threads {
            let itemType: SidebarItemType = thread.shouldPromoteToWorkspace ?
                .evolvingConversation : .conversation
            
            items.append(SidebarItem(
                id: thread.id,
                title: thread.displayTitle,
                subtitle: generateThreadSubtitle(thread),
                type: itemType,
                workspaceType: thread.detectedType,
                lastActivity: thread.lastModified,
                messageCount: thread.messages.count,
                eligibilityScore: thread.promotionEligibility
            ))
        }
        
        return items
    }
    
    // MARK: - Helper Methods
    
    private func generateThreadSubtitle(_ thread: ChatThread) -> String {
        // Use isFromUser instead of role to match the actual ChatMessage structure
        let userMessages = thread.messages.filter { $0.isFromUser }
        
        if let lastUserMessage = userMessages.last {
            return String(lastUserMessage.content.prefix(50)) + (lastUserMessage.content.count > 50 ? "..." : "")
        } else {
            return "No messages yet"
        }
    }
    
    private func selectItem(_ item: SidebarItem) {
        selectedItem = item
        
        // Update managers based on selection
        if item.type == .workspace {
            if let workspace = workspaceManager.workspaces.first(where: { $0.id == item.id }) {
                workspaceManager.selectedWorkspace = workspace
            }
        } else {
            if let thread = threadManager.threads.first(where: { $0.id == item.id }) {
                threadManager.selectedThread = thread
            }
        }
    }
    
    private func createNewItem(type: NewItemType) {
        switch type {
        case .conversation:
            let newThread = threadManager.createNewThread()
            selectedItem = SidebarItem(
                id: newThread.id,
                title: newThread.displayTitle,
                subtitle: "",
                type: .conversation,
                workspaceType: newThread.detectedType,
                lastActivity: newThread.lastModified,
                messageCount: 0,
                eligibilityScore: 0.0
            )
        case .workspace:
            // This would open the NewProjectSheet
            break
        }
        showingNewItemDialog = false
    }
}

// MARK: - Supporting Views

struct FluidSidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Evolution indicator with workspace type
            EvolutionIndicator(
                type: item.type,
                workspaceType: item.workspaceType,
                eligibility: item.eligibilityScore
            )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    // Note: HoverRevealTypeBadge is defined in SharedUIComponents.swift
                    HStack {
                        Spacer()
                        
                        // Only show type badge on hover or when selected
                        if isHovered || isSelected {
                            InvisibleWorkspaceTypeIndicator(item.workspaceType)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(2)
                }
                
                // Metadata row
                HStack(spacing: 8) {
                    Text(item.messageCount > 0 ? "\(item.messageCount)" : "")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
                    
                    Text(item.lastActivity.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(itemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        
        // Nested threads for evolving conversations
        if item.type == .evolvingConversation {
            if let thread = ThreadManager.shared.threads.first(where: { $0.id == item.id }),
               let nestedThreads = getNestedThreads(for: thread),
               !nestedThreads.isEmpty {
                nestedThreadsView(nestedThreads)
            }
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
    
    private func getNestedThreads(for thread: ChatThread) -> [ChatThread]? {
        // Return related threads based on topic similarity
        // This is a placeholder - would be implemented with actual similarity logic
        return nil
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
                .foregroundStyle(isParentSelected ? .white.opacity(0.7) : Color.secondary.opacity(0.8))
        }
        .padding(.leading, 16)
        .padding(.vertical, 2)
    }
}

// MARK: - Supporting Components

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct SidebarContextMenu: View {
    let item: SidebarItem
    
    var body: some View {
        Button("Rename") {
            // TODO: Implement rename
        }
        
        if item.type != .workspace {
            Button("Promote to Workspace") {
                // TODO: Implement promotion
            }
            .disabled(item.eligibilityScore < 0.6)
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            // TODO: Implement delete
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No conversations yet")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Start a new conversation to get going")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

struct IntelligenceStatusBar: View {
    @StateObject private var intelligenceEngine = IntelligenceEngine.shared
    
    var body: some View {
        HStack(spacing: 8) {
            // Processing indicator
            if intelligenceEngine.isProcessing {
                ProgressView()
                    .controlSize(.mini)
                Text("Thinking...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "brain.filled")
                    .foregroundStyle(.blue)
                Text("Ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Confidence indicator
            if intelligenceEngine.confidenceScore > 0 {
                Text("\(String(format: "%.0f", intelligenceEngine.confidenceScore * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .help("Last response confidence")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.thinMaterial)
        )
    }
}

struct NewItemDialog: View {
    let onItemTypeSelected: (NewItemType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Button {
                    onItemTypeSelected(.conversation)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "message")
                            .font(.title)
                        Text("Conversation")
                            .font(.headline)
                        Text("Quick chat or discussion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button {
                    onItemTypeSelected(.workspace)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.title)
                        Text("Workspace")
                            .font(.headline)
                        Text("Organized project space")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(width: 400, height: 300)
    }
}

// MARK: - Data Models

struct SidebarItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let type: SidebarItemType
    let workspaceType: WorkspaceManager.WorkspaceType
    let lastActivity: Date
    let messageCount: Int
    let eligibilityScore: Double
}

enum SidebarItemType: String, CaseIterable {
    case conversation = "conversation"
    case evolvingConversation = "evolving_conversation"
    case workspace = "workspace"
}

enum NewItemType: String, CaseIterable {
    case conversation = "conversation"
    case workspace = "workspace"
}

// MARK: - Extensions

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    FluidSidebar(selectedItem: .constant(nil))
        .frame(width: 300, height: 600)
}
