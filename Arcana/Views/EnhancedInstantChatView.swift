//
// EnhancedInstantChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Revolutionary Instant Chat with Quantum Intelligence
//

import SwiftUI

struct EnhancedInstantChatView: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var intelligenceEngine = IntelligenceEngine.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    @State private var selectedThread: ChatThread?
    @State private var showingNewConversationDialog = false
    @State private var isCreatingThread = false
    
    var body: some View {
        NavigationSplitView {
            // Thread sidebar with intelligent organization
            InstantThreadSidebar(
                selectedThread: $selectedThread,
                showingNewConversationDialog: $showingNewConversationDialog
            )
        } detail: {
            if let thread = selectedThread {
                ConversationView(thread: thread)
            } else {
                // Welcome state
                EnhancedWelcomeView()
            }
        }
        .navigationTitle("Instant Chat")
        .sheet(isPresented: $showingNewConversationDialog) {
            NewConversationDialog { workspaceType in
                createNewThread(type: workspaceType)
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    private func setupInitialState() {
        if threadManager.threads.isEmpty {
            createNewThread(type: .general)
        } else {
            selectedThread = threadManager.threads.first
        }
    }
    
    private func createNewThread(type: WorkspaceManager.WorkspaceType) {
        let newThread = threadManager.createNewThread()
        newThread.detectedType = type
        selectedThread = newThread
        showingNewConversationDialog = false
    }
}

struct InstantThreadSidebar: View {
    @StateObject private var threadManager = ThreadManager.shared
    @Binding var selectedThread: ChatThread?
    @Binding var showingNewConversationDialog: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with new thread button
            HStack {
                Text("Conversations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingNewConversationDialog = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("New conversation")
            }
            .padding()
            
            Divider()
            
            // Thread list with invisible intelligence
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(threadManager.threads) { thread in
                        InstantThreadRow(
                            thread: thread,
                            isSelected: selectedThread?.id == thread.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedThread = thread
                        }
                        .contextMenu {
                            ThreadContextMenu(thread: thread)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Quick stats
            if !threadManager.threads.isEmpty {
                Text("\(threadManager.threads.count) conversations")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}

struct InstantThreadRow: View {
    let thread: ChatThread
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Text(thread.detectedType.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(thread.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let lastMessage = thread.messages.last {
                    Text(lastMessage.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(thread.lastActivity)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if thread.messages.count > 0 {
                    Text("\(thread.messages.count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.secondary.opacity(0.2))
                        )
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct ThreadContextMenu: View {
    let thread: ChatThread
    @StateObject private var threadManager = ThreadManager.shared
    
    var body: some View {
        Button("Rename") {
            // TODO: Implement rename
        }
        
        Button("Duplicate") {
            // TODO: Implement duplicate
        }
        
        Divider()
        
        if thread.shouldPromoteToWorkspace {
            Button("Promote to Workspace") {
                // TODO: Implement promotion
            }
        }
        
        Divider()
        
        Button("Delete", role: .destructive) {
            threadManager.deleteThread(thread)
        }
    }
}

struct NewConversationDialog: View {
    let onWorkspaceTypeSelected: (WorkspaceManager.WorkspaceType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Start New Conversation")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the type of conversation you'd like to have:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach([
                    WorkspaceManager.WorkspaceManager.WorkspaceType.general,
                    .code,
                    .creative,
                    .research
                ], id: \.self) { type in
                    Button {
                        onWorkspaceTypeSelected(type)
                    } label: {
                        VStack(spacing: 8) {
                            Text(type.emoji)
                                .font(.largeTitle)
                            
                            Text(type.displayName)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(type.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 480, height: 400)
    }
}

struct EnhancedWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Welcome header
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Welcome to Instant Chat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start a conversation or select an existing thread from the sidebar")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quick start suggestions
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Start Ideas:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    SuggestionRow(
                        icon: "swift",
                        title: "Code Help",
                        description: "Get assistance with programming and development"
                    )
                    
                    SuggestionRow(
                        icon: "lightbulb",
                        title: "Creative Writing",
                        description: "Brainstorm ideas, write content, or get feedback"
                    )
                    
                    SuggestionRow(
                        icon: "magnifyingglass",
                        title: "Research",
                        description: "Analyze information, find insights, or explore topics"
                    )
                    
                    SuggestionRow(
                        icon: "message",
                        title: "General Chat",
                        description: "Have a casual conversation about anything"
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
        .padding(40)
    }
}

struct SuggestionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
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
    }
}

struct ConversationView: View {
    let thread: ChatThread
    @State private var isAssistantTyping = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Conversation header with thread intelligence
                    ConversationHeader(thread: thread)
                    
                    // Messages
                    ForEach(thread.messages) { message in
                        EnhancedMessageBubble(
                            message: message,
                            threadType: thread.detectedType
                        )
                        .id(message.id)
                    }
                    
                    // Typing indicator
                    if isAssistantTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: thread.messages.count) {
                // Auto-scroll to latest message
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
    }
}

struct ConversationHeader: View {
    let thread: ChatThread
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Thread type and title
                Text(thread.detectedType.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.displayTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if thread.conversationDepth > 0 {
                        HStack(spacing: 8) {
                            Text("\(thread.messageCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("Depth: \(thread.conversationDepth)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Intelligent conversation summary
            if !thread.summary.isEmpty {
                Text(thread.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                    )
            }
        }
        .padding(.horizontal, 32)
    }
}

struct EnhancedInstantInputArea: View {
    let thread: ChatThread
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var intelligenceEngine = IntelligenceEngine.shared
    
    @State private var inputText = ""
    @State private var isInputFocused = false
    @State private var isAssistantTyping = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Smart input with predictive text
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $inputText)
                            .scrollContentBackground(.hidden)
                            .focused($isInputFocused)
                            .padding(8)
                        
                        // Ghost text for smart suggestions
                        if inputText.isEmpty {
                            Text("Ask anything...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(minHeight: 36, maxHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    
                    // Live word count
                    if !inputText.isEmpty {
                        Text("\(inputText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Smart starter suggestions (only for new threads)
            if thread.messages.isEmpty {
                SmartStarterSuggestions(workspaceType: thread.detectedType) { suggestion in
                    inputText = suggestion
                    sendMessage()
                }
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

        // FIXED: Create user message with correct initializer
        let userMessage = ChatMessage(
            content: trimmedText,
            isFromUser: true,
            threadId: thread.workspaceId ?? UUID()
        )
        threadManager.addMessage(userMessage, to: thread)
        
        inputText = ""
        isInputFocused = true
        
        // Generate assistant response
        generateResponse(for: userMessage)
    }
    
    private func generateResponse(for userMessage: ChatMessage) {
        isAssistantTyping = true
        
        Task {
            // FIXED: Use correct IntelligenceEngine API
            let response = await intelligenceEngine.generateContextualResponse(
                for: userMessage.content,
                context: thread.messages,
                workspaceType: thread.detectedType
            )
            
            await MainActor.run {
                isAssistantTyping = false
                
                // FIXED: Create assistant message with correct initializer
                let assistantMessage = ChatMessage(
                    content: response,
                    isFromUser: false,
                    threadId: userMessage.threadId
                )
                
                threadManager.addMessage(assistantMessage, to: thread)
                
                // 🎯 BREAKTHROUGH: Evaluate for intelligent workspace creation
                if thread.messages.count >= 4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        threadManager.evaluateForWorkspaceCreation(thread.messages)
                    }
                }
            }
        }
    }
    
    // Helper to calculate text width for ghost text positioning
    private func textWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let size = text.size(withAttributes: attributes)
        return size.width
    }
}

struct EnhancedMessageBubble: View {
    let message: ChatMessage
    let threadType: WorkspaceManager.WorkspaceType
    
    var body: some View {
        HStack(alignment: .top) {
            // FIXED: Use isFromUser instead of role
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isFromUser ? .blue : Color(NSColor.controlBackgroundColor))
                    )
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                
                // Message metadata
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    // FIXED: Use isFromUser instead of role
                    if !message.isFromUser {
                        if let metadata = message.metadata {
                            if let model = metadata.modelUsed {
                                Text("• \(model)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let confidence = metadata.confidence {
                                Text("• \(String(format: "%.0f", confidence * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .help("Confidence level")
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 500, alignment: message.isFromUser ? .trailing : .leading)
            
            // FIXED: Use isFromUser instead of role
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct SmartStarterSuggestions: View {
    let workspaceType: WorkspaceManager.WorkspaceType
    let onSuggestionTap: (String) -> Void
    
    private var suggestions: [String] {
        switch workspaceType {
        case .code:
            return [
                "I need help debugging...",
                "How do I implement...",
                "Can you review this code?",
                "What's the best practice for..."
            ]
        case .creative:
            return [
                "Help me write...",
                "I need ideas for...",
                "Can you improve this text?",
                "What's a creative approach to..."
            ]
        case .research:
            return [
                "I'm researching...",
                "Can you analyze...",
                "What are the implications of...",
                "Help me understand..."
            ]
        case .general:
            return [
                "I have a question about...",
                "Can you help me with...",
                "I'm curious about...",
                "What do you think about..."
            ]
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestionTap(suggestion)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.thinMaterial)
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 32)
    }
}

#Preview {
    EnhancedInstantChatView()
}
