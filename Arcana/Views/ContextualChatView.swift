// ContextualChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ContextualChatView: View {
    @ObservedObject var thread: ConversationThread
    @State private var inputText = ""
    @State private var isAssistantTyping = false
    @FocusState private var isInputFocused: Bool
    @StateObject private var intelligenceEngine = IntelligenceEngine()
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Contextual header
            ContextualChatHeader(thread: thread)
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(thread.messages) { message in
                            OptimizedMessageView(
                                message: message,
                                showTechnicalInfo: false
                            )
                            .id(message.id)
                        }
                        
                        if isAssistantTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToBottom"))) { _ in
                    if let lastMessage = thread.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Smart input area
            SmartInputArea(
                thread: thread,
                inputText: $inputText,
                isInputFocused: $isInputFocused,
                onSend: { content in
                    sendMessage(content)
                }
            )
        }
        .onAppear {
            isInputFocused = true
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
    }
    
    private func sendMessage(_ content: String) {
        threadManager.addMessage(content, to: thread)
        scrollToBottom()
        generateResponse(for: content)
    }
    
    private func generateResponse(for userMessage: String) {
        isAssistantTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAssistantTyping = false
            
            let workspaceType = getWorkspaceType()
            let response = intelligenceEngine.generateContextualResponse(
                userMessage: userMessage,
                workspaceType: workspaceType,
                conversationHistory: thread.messages
            )
            
            threadManager.addAssistantMessage(response, to: thread)
            scrollToBottom()
            
            // Evaluate for project promotion if instant thread
            if thread.type == .instant {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    threadManager.evaluateForProjectPromotion(thread)
                }
            }
        }
    }
    
    private func getWorkspaceType() -> WorkspaceManager.WorkspaceType {
        if let projectId = thread.projectId,
           let project = workspaceManager.workspaces.first(where: { $0.id == projectId }) {
            return workspaceManager.getWorkspaceType(for: project)
        }
        return .general
    }
    
    private func handleFileDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            handleFileURL(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func handleFileURL(_ url: URL) {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        // Add file to thread
        thread.attachedFiles.append(fileName)
        
        // Generate contextual file response
        let fileMessage = intelligenceEngine.generateFileProcessingResponse(
            fileName: fileName,
            fileExtension: fileExtension,
            workspaceType: getWorkspaceType()
        )
        
        threadManager.addAssistantMessage(fileMessage, to: thread)
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
    }
}

struct ContextualChatHeader: View {
    @ObservedObject var thread: ConversationThread
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(thread.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    // Thread type indicator
                    if thread.type == .instant {
                        Text("Quick Chat")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                // Context information
                if let projectId = thread.projectId,
                   let project = workspaceManager.workspaces.first(where: { $0.id == projectId }) {
                    HStack(spacing: 4) {
                        InvisibleWorkspaceTypeIndicator(
                            workspaceManager.getWorkspaceType(for: project),
                            inHeader: true
                        )
                        Text(project.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("General conversation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // File attachments indicator
                if !thread.attachedFiles.isEmpty {
                    Button(action: {
                        // TODO: Show file list
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                            Text("\(thread.attachedFiles.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Message count
                if !thread.messages.isEmpty {
                    Text("\(thread.messages.count) messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct SmartInputArea: View {
    @ObservedObject var thread: ConversationThread
    @Binding var inputText: String
    var isInputFocused: FocusState<Bool>.Binding
    let onSend: (String) -> Void
    
    @State private var liveWordCount = 0
    @StateObject private var intelligenceEngine = IntelligenceEngine()
    
    var body: some View {
        VStack(spacing: 8) {
            // Contextual suggestions based on thread type and content
            if thread.messages.isEmpty {
                ThreadStarterSuggestions(thread: thread, onSuggestion: { suggestion in
                    inputText = suggestion
                })
            }
            
            // Live feedback
            if !inputText.isEmpty && liveWordCount > 20 {
                HStack {
                    Text("\(liveWordCount) words")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if liveWordCount > 100 {
                        Text("Substantial content")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
            }
            
            // Input field
            HStack(alignment: .bottom, spacing: 12) {
                TextField(getPlaceholder(), text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .focused(isInputFocused)
                    .lineLimit(1...10)
                    .onSubmit {
                        sendMessage()
                    }
                    .onChange(of: inputText) {
                        updateWordCount()
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
    }
    
    private func getPlaceholder() -> String {
        if thread.type == .instant {
            return "Continue the conversation..."
        } else {
            return "Add to this discussion..."
        }
    }
    
    private func updateWordCount() {
        let words = inputText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        liveWordCount = words.count
    }
    
    private func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        onSend(content)
        inputText = ""
        liveWordCount = 0
    }
}

struct ThreadStarterSuggestions: View {
    @ObservedObject var thread: ConversationThread
    let onSuggestion: (String) -> Void
    @StateObject private var workspaceManager = WorkspaceManager.shared
    
    var suggestions: [String] {
        if let projectId = thread.projectId,
           let project = workspaceManager.workspaces.first(where: { $0.id == projectId }) {
            let workspaceType = workspaceManager.getWorkspaceType(for: project)
            return getSuggestionsForType(workspaceType)
        } else {
            return [
                "What should we explore together?",
                "I have a question about...",
                "Can you help me think through...",
                "I'd like to brainstorm..."
            ]
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                    Button(suggestion) {
                        onSuggestion(suggestion)
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
    }
    
    private func getSuggestionsForType(_ type: WorkspaceManager.WorkspaceType) -> [String] {
        switch type {
        case .code:
            return [
                "I need help reviewing this code...",
                "Can you explain how this works?",
                "Help me debug this issue...",
                "What's the best approach for..."
            ]
        case .creative:
            return [
                "Help me brainstorm ideas for...",
                "I'm working on a story about...",
                "Can you help improve this writing?",
                "What's a creative way to..."
            ]
        case .research:
            return [
                "I'm researching information about...",
                "Can you help me analyze this data?",
                "What are the key findings on...",
                "Help me fact-check this..."
            ]
        case .general:
            return [
                "I'd like to discuss...",
                "Can you help me plan...",
                "What do you think about...",
                "Help me understand..."
            ]
        }
    }
}

#Preview {
    let thread = ConversationThread(title: "Test Thread", type: .instant, projectId: nil)
    return ContextualChatView(thread: thread)
}
