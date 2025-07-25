// EnhancedInstantChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct EnhancedInstantChatView: View {
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var predictiveController = PredictiveInputController()
    private let intelligenceEngine = IntelligenceEngine.shared
    
    var currentThread: ChatThread {
        return threadManager.selectedThread ?? threadManager.threads.first ?? ChatThread()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if currentThread.messages.isEmpty {
                // Welcome state - ready to chat
                WelcomeState()
            } else {
                // Active conversation view
                ConversationView(thread: currentThread)
            }

            Divider()

            // Enhanced input with predictive intelligence
            EnhancedInputArea(
                thread: currentThread,
                predictiveController: predictiveController
            )
        }
    }
}

struct WelcomeState: View {
    var body: some View {
        VStack(spacing: 24) {
            // Animated welcome icon
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.pulse)
            
            VStack(spacing: 12) {
                Text("Ready to think together")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Start a conversation about anything")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Feature hints
            VStack(spacing: 8) {
                FeatureHint(
                    icon: "brain.head.profile",
                    text: "AI suggests workspaces as you chat"
                )
                
                FeatureHint(
                    icon: "text.cursor",
                    text: "Predictive completions help you express ideas"
                )
                
                FeatureHint(
                    icon: "folder.badge.gearshape",
                    text: "Conversations organize themselves intelligently"
                )
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureHint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 32)
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
                            
                            if thread.topicConsistency > 0.6 {
                                Label("Focused", systemImage: "target")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            
                            if thread.shouldPromoteToWorkspace {
                                Label("Ready for workspace", systemImage: "arrow.up.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Thread actions
                HStack(spacing: 8) {
                    if thread.shouldPromoteToWorkspace {
                        Button("Promote") {
                            ThreadManager.shared.promoteThreadToWorkspace(thread)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    
                    Menu {
                        Button("Rename Thread") {
                            // TODO: Implement rename
                        }
                        
                        Button("Export Thread") {
                            // TODO: Implement export
                        }
                        
                        Divider()
                        
                        Button("Delete Thread", role: .destructive) {
                            ThreadManager.shared.deleteThread(thread)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            
            // Contextual tags
            if !thread.contextualTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(thread.contextualTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.blue.opacity(0.1))
                                        .stroke(.blue.opacity(0.3), lineWidth: 0.5)
                                )
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

struct EnhancedInputArea: View {
    let thread: ChatThread
    @ObservedObject var predictiveController: PredictiveInputController
    
    @State private var inputText = ""
    @State private var isAssistantTyping = false
    @FocusState private var isInputFocused: Bool
    private let intelligenceEngine = IntelligenceEngine.shared
    @StateObject private var threadManager = ThreadManager.shared

    var body: some View {
        VStack(spacing: 8) {
            // 🚀 BREAKTHROUGH: Contextual suggestions (appear as you type)
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

            HStack(alignment: .bottom, spacing: 12) {
                // Enhanced text input with predictive overlay
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
                            // 🧠 BREAKTHROUGH: Real-time predictive analysis
                            predictiveController.analyzeInput(
                                inputText,
                                conversationHistory: thread.messages,
                                workspaceType: thread.detectedType
                            )
                        }
                    
                    // 🔮 BREAKTHROUGH: Ghost text prediction
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

        // Create and add user message
        let userMessage = ChatMessage(content: trimmedText, role: .user, projectId: thread.workspaceId ?? UUID())
        threadManager.addMessage(userMessage, to: thread)
        
        inputText = ""
        isInputFocused = true
        
        // Generate assistant response
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
            
            // 🎯 BREAKTHROUGH: Evaluate for intelligent workspace creation
            if thread.messages.count >= 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    threadManager.evaluateForWorkspaceCreation(thread.messages)
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
                
                // Message metadata
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if message.role == .assistant {
                        if let metadata = message.metadata {
                            if let model = metadata.modelUsed {
                                Text("• \(model)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if metadata.wasSpeculative == true {
                                Text("• ⚡")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .help("Predictive response")
                            }
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
                "What's a better way to say..."
            ]
        case .research:
            return [
                "Help me research...",
                "What are the implications of...",
                "Can you analyze...",
                "What evidence supports..."
            ]
        case .general:
            return [
                "Help me brainstorm ideas for...",
                "I need to understand...",
                "Can you explain...",
                "What do you think about..."
            ]
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestionTap(suggestion)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    EnhancedInstantChatView()
        .frame(width: 800, height: 600)
}
