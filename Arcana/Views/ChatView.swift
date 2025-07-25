//
// ChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//

import SwiftUI

struct ChatView: View {
    let project: Project
    
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var intelligenceEngine = IntelligenceEngine.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isAssistantTyping = false
    @State private var showModelInfo = false
    @State private var liveWordCount = 0
    @State private var showWorkspacePromotionDialog = false
    @State private var showingToolFeedback = false
    @State private var toolFeedback = ""
    
    private let maxInputLength = 10000
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with intelligence indicators
            if userSettings.showModelAttribution {
                HStack {
                    // Workspace type indicator
                    InvisibleWorkspaceTypeIndicator(
                        workspaceManager.getWorkspaceType(for: project),
                        inHeader: true
                    )
                    
                    Text(project.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Context intelligence indicator
                    if messages.count > 5 {
                        Text("\(messages.count) context")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.secondary.opacity(0.1))
                            )
                    }
                }
                .padding()
                
                // Smart Tool Feedback Bar
                if showingToolFeedback {
                    HStack {
                        Image(systemName: "gear.badge.checkmark")
                            .foregroundColor(.blue)
                        Text(toolFeedback)
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button("Dismiss") {
                            withAnimation {
                                showingToolFeedback = false
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                }
            }
            
            Divider()
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                showModelInfo: userSettings.showModelAttribution || userSettings.showPerformanceMetrics
                            )
                            .id(message.id)
                        }
                        
                        if isAssistantTyping {
                            TypingIndicator() // Using shared component from SharedUIComponents.swift
                                .id("typing-indicator")
                        }
                    }
                    .padding()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToBottom"))) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isAssistantTyping) { _, _ in
                    if isAssistantTyping {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Smart suggestions (context-aware)
            if !inputText.isEmpty && inputText.count > 10 {
                SmartSuggestionsBar(
                    workspaceType: workspaceManager.getWorkspaceType(for: project),
                    inputText: inputText
                ) { suggestion in
                    inputText += " " + suggestion
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Divider()
            
            // Enhanced Input Area
            VStack(spacing: 8) {
                // Live word count and context awareness
                if !inputText.isEmpty && liveWordCount > 20 {
                    HStack {
                        Text("\(liveWordCount) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // Context-aware suggestions
                        if liveWordCount > 100 {
                            Text("Long form detected - workspace promotion available")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Input area
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Enhanced text input with intelligent features
                        TextEditor(text: $inputText)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .frame(minHeight: 36, maxHeight: 120)
                            .onChange(of: inputText) { _, newValue in
                                updateLiveWordCount()
                                
                                // Limit input length
                                if newValue.count > maxInputLength {
                                    inputText = String(newValue.prefix(maxInputLength))
                                }
                            }
                            .onSubmit {
                                sendMessage()
                            }
                        
                        // Live stats and intelligent suggestions
                        HStack {
                            Text("\(liveWordCount) words")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            if inputText.count > maxInputLength - 500 {
                                Text("• \(maxInputLength - inputText.count) chars left")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            
                            Spacer()
                            
                            // Model info toggle
                            Button(action: { showModelInfo.toggle() }) {
                                Image(systemName: showModelInfo ? "info.circle.fill" : "info.circle")
                                    .foregroundStyle(showModelInfo ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Toggle model information display")
                        }
                    }
                    
                    // Send button with intelligent state
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSendMessage ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSendMessage)
                    .keyboardShortcut(.return, modifiers: .command)
                }
                .padding()
            }
        }
        .navigationTitle(project.title)
        .navigationSubtitle("Intelligent Workspace")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Export Conversation") {
                        exportConversation()
                    }
                    
                    Button("Clear Chat") {
                        clearChat()
                    }
                    
                    Divider()
                    
                    Button("Promote to Workspace") {
                        showWorkspacePromotionDialog = true
                    }
                    .disabled(messages.count < 3)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showWorkspacePromotionDialog) {
            // FIXED: Use proper ProjectPromotionSuggestion structure from ProjectPromotionSheet.swift
            ProjectPromotionSheet(
                suggestion: ProjectPromotionSuggestion(
                    suggestedType: workspaceManager.getWorkspaceType(for: project),
                    suggestedTitle: project.title,
                    reason: "This conversation shows focused discussion that would benefit from workspace organization.",
                    description: "Development workspace for organizing related conversations and resources.",
                    messageCount: messages.count,
                    conversationStart: Date()
                )
            )
        }
        .onAppear {
            loadConversationHistory()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isAssistantTyping
    }
    
    // MARK: - Helper Methods
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isAssistantTyping {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func updateLiveWordCount() {
        let words = inputText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        liveWordCount = words.count
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            content: trimmedText,
            isFromUser: true,
            threadId: project.id
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        liveWordCount = 0
        
        // Generate intelligent response
        generateIntelligentResponse(for: userMessage)
    }
    
    private func generateIntelligentResponse(for userMessage: ChatMessage) {
        isAssistantTyping = true
        
        Task {
            do {
                let workspaceType = workspaceManager.getWorkspaceType(for: project)
                
                // FIXED: Use correct IntelligenceEngine API
                let response = await intelligenceEngine.generateContextualResponse(
                    for: userMessage.content,
                    context: messages,
                    workspaceType: workspaceType
                )
                
                await MainActor.run {
                    isAssistantTyping = false
                    
                    var assistantMessage = ChatMessage(
                        content: response,
                        isFromUser: false,
                        threadId: project.id
                    )
                    
                    // Add enhanced metadata
                    var metadata = MessageMetadata()
                    metadata.modelUsed = "Enhanced Intelligence"
                    metadata.responseTime = 1.2 // Simulated for now
                    metadata.confidence = 0.85
                    metadata.responseTokens = response.components(separatedBy: .whitespacesAndNewlines).count
                    metadata.inferenceTime = 1.2
                    
                    assistantMessage.metadata = metadata
                    messages.append(assistantMessage)
                    
                    // Save conversation
                    saveConversation()
                }
            } catch {
                await MainActor.run {
                    isAssistantTyping = false
                    let errorMessage = ChatMessage(
                        content: "I apologize, but I encountered an error while processing your request. Please try again.",
                        isFromUser: false,
                        threadId: project.id
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func loadConversationHistory() {
        // For now, just initialize empty messages
        // In the full implementation, this would load from ThreadManager
        messages = []
    }
    
    private func saveConversation() {
        // For now, this is a placeholder
        // In the full implementation, this would save to ThreadManager
        print("💾 Saving conversation for project: \(project.title)")
    }
    
    private func exportConversation() {
        let conversationText = messages.map { message in
            let sender = message.isFromUser ? "User" : "Assistant"
            let timestamp = message.timestamp.formatted(date: .abbreviated, time: .shortened)
            return "\(sender) (\(timestamp)):\n\(message.content)\n"
        }.joined(separator: "\n")
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(project.title)_conversation.txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? conversationText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func clearChat() {
        messages.removeAll()
        saveConversation()
    }
}

// MARK: - Message Bubble View

struct MessageBubble: View {
    let message: ChatMessage
    let showModelInfo: Bool
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? Color.blue : Color(NSColor.controlBackgroundColor))
                    )
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                
                // Enhanced message metadata
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if showModelInfo && !message.isFromUser {
                        if let metadata = message.metadata {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            if let model = metadata.modelUsed {
                                Text(model)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // FIXED: Use responseTokens instead of tokensGenerated
                            if let tokens = metadata.responseTokens {
                                Text("• \(tokens) tokens")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let responseTime = metadata.responseTime {
                                Text("• \(String(format: "%.1f", responseTime))s")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // FIXED: Show confidence if available instead of wasSpeculative
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
            .frame(maxWidth: 400, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

// MARK: - Smart Suggestions Bar

struct SmartSuggestionsBar: View {
    let workspaceType: WorkspaceManager.WorkspaceType
    let inputText: String
    let onSuggestionTap: (String) -> Void
    
    var suggestions: [String] {
        switch workspaceType {
        case .code:
            return [
                "Can you review this code for improvements?",
                "Help me debug this issue:",
                "Explain how this works:",
                "Optimize this for performance"
            ]
        case .research:
            return [
                "Can you help me research:",
                "What are the key findings about:",
                "Summarize the main points:",
                "Find sources for:"
            ]
        case .creative:
            return [
                "Help me improve this writing:",
                "Can you edit this for clarity:",
                "Suggest a better structure:",
                "Check grammar and style"
            ]
        case .general:
            return [
                "Can you help me with:",
                "Explain this concept:",
                "What do you think about:",
                "Help me understand:"
            ]
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestionTap(suggestion)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - Supporting Data Structures
// Note: ProjectPromotionSuggestion is defined in ProjectPromotionSheet.swift
