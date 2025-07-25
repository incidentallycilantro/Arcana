// MainView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct MainView: View {
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingSidebar = true

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(showingSidebar ? .all : .detailOnly)) {
            // Revolutionary Fluid Sidebar
            FluidSidebar()
                .frame(minWidth: 320, maxWidth: 400)
        } detail: {
            // Adaptive Content Area
            AdaptiveContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSidebar.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Toggle Sidebar")

                Spacer()

                Button(action: {
                    threadManager.createNewThread()
                }) {
                    Image(systemName: "plus.message")
                }
                .help("New Conversation")
                
                Button(action: {
                    workspaceManager.showNewWorkspaceSheet = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("New Workspace")
            }
        }
        .onAppear {
            initializeApp()
        }
        .sheet(isPresented: $threadManager.showWorkspaceCreationDialog) {
            if let context = threadManager.workspaceCreationContext {
                IntelligentWorkspaceCreationDialog(context: context)
            }
        }
    }
    
    private func initializeApp() {
        // Initialize the revolutionary PRISM system
        Task {
            do {
                print("🚀 Starting PRISM Engine initialization...")
                try await PRISMEngine.shared.initialize()
                print("✅ PRISM Engine fully initialized and ready!")
            } catch {
                print("❌ PRISM Engine initialization failed: \(error)")
            }
        }
        
        // Initialize existing systems
        threadManager.loadThreads()
        
        // Create initial thread if needed
        if threadManager.threads.isEmpty {
            threadManager.createNewThread()
        }
    }
}

// MARK: - Adaptive Content View

struct AdaptiveContentView: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        Group {
            if let selectedThread = threadManager.selectedThread {
                // Thread conversation view
                FluidConversationView(thread: selectedThread)
            } else if let selectedWorkspace = workspaceManager.selectedWorkspace {
                // Workspace overview with knowledge management
                WorkspaceKnowledgeView(workspace: selectedWorkspace)
            } else {
                // Welcome state with revolutionary onboarding
                RevolutionaryWelcomeView()
            }
        }
    }
}

// MARK: - Fluid Conversation View

struct FluidConversationView: View {
    let thread: ChatThread
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var predictiveController = PredictiveInputController()
    @State private var isAssistantTyping = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Intelligent conversation header
            FluidConversationHeader(thread: thread)
            
            Divider()
            
            // Messages with file context
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(thread.messages) { message in
                            FluidMessageBubble(
                                message: message,
                                threadType: thread.detectedType
                            )
                            .id(message.id)
                        }
                        
                        if isAssistantTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: thread.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            Divider()
            
            // Enhanced input with file drop support
            FluidInputArea(
                thread: thread,
                predictiveController: predictiveController,
                isAssistantTyping: $isAssistantTyping
            )
        }
    }
    
    // FIXED: Corrected ScrollViewProxy type
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = thread.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if isAssistantTyping {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }
}

// MARK: - Conversation Header

struct FluidConversationHeader: View {
    let thread: ChatThread
    @StateObject private var threadManager = ThreadManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.detectedType.emoji)
                        .font(.title2)
                    
                    Text(thread.displayTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if thread.shouldPromoteToWorkspace {
                        Text("Ready for workspace")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                Text("Conversation evolving • \(thread.messageCount) • \(thread.lastActivity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if thread.shouldPromoteToWorkspace {
                    Button("Create Workspace") {
                        threadManager.promoteThreadToWorkspace(thread)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Menu {
                    Button("Timeline View") {
                        // TODO: Show timeline
                    }
                    
                    Button("Export Thread") {
                        // TODO: Export functionality
                    }
                    
                    Divider()
                    
                    Button("Delete Thread", role: .destructive) {
                        threadManager.deleteThread(thread)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
    }
}

// MARK: - Enhanced Input Area

struct FluidInputArea: View {
    let thread: ChatThread
    @ObservedObject var predictiveController: PredictiveInputController
    @Binding var isAssistantTyping: Bool
    
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var intelligenceEngine = IntelligenceEngine()
    @StateObject private var threadManager = ThreadManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // File drop zone with visual feedback
            FileDropZone(thread: thread)
            
            // Predictive suggestions
            if !predictiveController.contextualSuggestions.isEmpty && !inputText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(predictiveController.contextualSuggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                inputText = suggestion
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Input field with predictive text
            HStack(alignment: .bottom, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    TextField("Continue the conversation...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .focused($isInputFocused)
                        .lineLimit(1...10)
                        .onSubmit {
                            sendMessage()
                        }
                        .onChange(of: inputText) {
                            predictiveController.analyzeInput(
                                inputText,
                                conversationHistory: thread.messages,
                                workspaceType: thread.detectedType
                            )
                        }
                    
                    // Ghost text prediction
                    if predictiveController.showPrediction && !inputText.isEmpty {
                        Text(inputText + predictiveController.predictiveText)
                            .font(.system(.body))
                            .foregroundStyle(.clear)
                            .overlay(
                                Text(predictiveController.predictiveText)
                                    .font(.system(.body))
                                    .foregroundStyle(.secondary.opacity(0.6))
                                    .offset(x: textWidth(inputText))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                            .lineLimit(1)
                    }
                }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let userMessage = ChatMessage(content: trimmedText, role: .user, projectId: thread.workspaceId ?? UUID())
        threadManager.addMessage(userMessage, to: thread)
        
        inputText = ""
        isInputFocused = true
        
        generateResponse(for: userMessage)
    }
    
    private func generateResponse(for userMessage: ChatMessage) {
        isAssistantTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAssistantTyping = false
            
            let response = intelligenceEngine.generateContextualResponse(
                userMessage: userMessage.content,
                workspaceType: thread.detectedType,
                conversationHistory: thread.messages
            )
            
            let assistantMessage = ChatMessage(
                content: response,
                role: .assistant,
                projectId: userMessage.projectId
            )
            
            threadManager.addMessage(assistantMessage, to: thread)
            
            // Check for workspace promotion
            if thread.messages.count >= 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    threadManager.evaluateForWorkspaceCreation(thread.messages)
                }
            }
        }
    }
    
    private func textWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = text.size(withAttributes: attributes)
        return size.width
    }
}

// MARK: - File Drop Zone

struct FileDropZone: View {
    let thread: ChatThread
    @State private var isDropTargeted = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isDropTargeted ? Color.blue.opacity(0.1) : Color.clear)
            .stroke(isDropTargeted ? Color.blue : Color.clear, style: StrokeStyle(lineWidth: 2, dash: [5]))
            .frame(height: isDropTargeted ? 60 : 0)
            .overlay(
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.blue)
                    Text("Drop files to add to conversation")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .opacity(isDropTargeted ? 1 : 0)
            )
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleFileDrop(providers)
            }
            .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }
    
    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            processDroppedFile(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func processDroppedFile(_ url: URL) {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        // Create file attachment message
        let fileMessage = "📎 I've attached \(fileName) to our conversation. What would you like to know about it?"
        
        let userMessage = ChatMessage(content: fileMessage, role: .assistant, projectId: thread.workspaceId ?? UUID())
        ThreadManager.shared.addMessage(userMessage, to: thread)
        
        // TODO: In Phase 5, this will integrate with PRISM file processing
        print("🗂️ File attached to thread: \(fileName) (\(fileExtension))")
    }
}

// MARK: - Workspace Knowledge View

struct WorkspaceKnowledgeView: View {
    let workspace: Project
    @StateObject private var threadManager = ThreadManager.shared
    
    var relatedThreads: [ChatThread] {
        threadManager.threads.filter { $0.workspaceId == workspace.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Workspace header
            WorkspaceHeader(workspace: workspace)
            
            Divider()
            
            // Knowledge sections
            ScrollView {
                VStack(spacing: 24) {
                    // Active conversations in this workspace
                    if !relatedThreads.isEmpty {
                        WorkspaceConversationsSection(threads: relatedThreads)
                    }
                    
                    // Knowledge library (ready for Phase 5)
                    WorkspaceKnowledgeSection(workspace: workspace)
                    
                    // AI insights (ready for future enhancement)
                    WorkspaceInsightsSection(workspace: workspace)
                }
                .padding()
            }
            
            Divider()
            
            // Workspace-level input
            WorkspaceInputArea(workspace: workspace)
        }
    }
}

// MARK: - Workspace Header

struct WorkspaceHeader: View {
    let workspace: Project
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workspaceManager.getWorkspaceType(for: workspace).emoji)
                        .font(.title2)
                    
                    Text(workspace.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(workspaceManager.getWorkspaceType(for: workspace).displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                Text(workspace.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("New Conversation") {
                    let newThread = ThreadManager.shared.createNewThread()
                    newThread.workspaceId = workspace.id
                    ThreadManager.shared.saveThread(newThread)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Menu {
                    Button("Workspace Settings") {
                        // TODO: Settings
                    }
                    
                    Button("Export Workspace") {
                        // TODO: Export
                    }
                    
                    Divider()
                    
                    Button("Delete Workspace", role: .destructive) {
                        workspaceManager.deleteWorkspace(workspace)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
    }
}

// MARK: - Workspace Sections

struct WorkspaceConversationsSection: View {
    let threads: [ChatThread]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Conversations")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(threads.prefix(4), id: \.id) { thread in
                    WorkspaceThreadCard(thread: thread)
                }
            }
            
            if threads.count > 4 {
                Button("View all \(threads.count) conversations") {
                    // TODO: Show all conversations
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}

struct WorkspaceKnowledgeSection: View {
    let workspace: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Knowledge Library")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Files") {
                    // TODO: File picker
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // File drop zone for workspace-level files
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text("Drop files here for workspace-wide access")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Files will be available to all conversations in this workspace")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                )
            
            Text("Ready for Phase 5: File intelligence and processing")
                .font(.caption2)
                .foregroundStyle(.blue)
                .italic()
        }
    }
}

struct WorkspaceInsightsSection: View {
    let workspace: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InsightCard(
                    icon: "brain.head.profile",
                    title: "Pattern Recognition",
                    description: "AI will identify recurring themes and connections across conversations"
                )
                
                InsightCard(
                    icon: "link",
                    title: "Cross-References",
                    description: "Automatic linking between related discussions and files"
                )
                
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "Monitor development and completion of workspace goals"
                )
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkspaceThreadCard: View {
    let thread: ChatThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.displayTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text("\(thread.messageCount) messages • \(thread.lastActivity)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            ThreadManager.shared.selectThread(thread)
        }
    }
}

// MARK: - Workspace Input Area

struct WorkspaceInputArea: View {
    let workspace: Project
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Start a new conversation in this workspace...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .focused($isInputFocused)
                .lineLimit(1...10)
                .onSubmit {
                    startWorkspaceConversation()
                }
            
            Button(action: startWorkspaceConversation) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    private func startWorkspaceConversation() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newThread = ThreadManager.shared.createNewThread()
        newThread.workspaceId = workspace.id
        
        let userMessage = ChatMessage(content: trimmedText, role: .user, projectId: workspace.id)
        ThreadManager.shared.addMessage(userMessage, to: newThread)
        ThreadManager.shared.selectThread(newThread)
        
        inputText = ""
        isInputFocused = true
    }
}

// MARK: - Revolutionary Welcome View

struct RevolutionaryWelcomeView: View {
    @StateObject private var threadManager = ThreadManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated hero section
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 12) {
                    Text("Intelligence awakens")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                    
                    Text("Start any conversation and watch your ideas organize themselves into workspaces")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Revolutionary features showcase
            VStack(spacing: 20) {
                FeatureShowcase(
                    icon: "brain.head.profile",
                    title: "Conversations evolve naturally",
                    description: "No forced organization. Threads become workspaces when they add value."
                )
                
                FeatureShowcase(
                    icon: "text.cursor",
                    title: "Predictive intelligence",
                    description: "AI suggests completions and helps you express ideas faster."
                )
                
                FeatureShowcase(
                    icon: "folder.badge.gearshape",
                    title: "Knowledge-aware workspaces",
                    description: "Files and conversations connect intelligently across projects."
                )
            }
            
            // Call to action
            Button("Start your first conversation") {
                threadManager.createNewThread()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureShowcase: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Fluid Message Bubble

struct FluidMessageBubble: View {
    let message: ChatMessage
    let threadType: WorkspaceManager.WorkspaceType
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.role == .user ? .blue : Color(NSColor.controlBackgroundColor))
                    )
                    .foregroundStyle(message.role == .user ? .white : .primary)
                
                // Minimal metadata
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if message.role == .assistant, let metadata = message.metadata {
                        if metadata.wasSpeculative == true {
                            Text("⚡")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .help("Predictive response")
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 500, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
