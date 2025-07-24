// InvisibleChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct InvisibleChatView: View {
    let project: Project
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isAssistantTyping = false
    @State private var liveWordCount = 0
    @FocusState private var isInputFocused: Bool
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var intelligenceEngine = IntelligenceEngine()
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal header with invisible type indicator
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Invisible workspace type indicator - barely visible, only shows on hover
                InvisibleWorkspaceTypeIndicator(
                    WorkspaceManager.shared.getWorkspaceType(for: project),
                    inHeader: true
                )
            }
            .padding()
            
            Divider()
            
            // High-performance conversation area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(messages) { message in
                            OptimizedMessageView(
                                message: message,
                                showTechnicalInfo: userSettings.showModelAttribution || userSettings.showPerformanceMetrics
                            )
                            .id(message.id)
                        }
                        
                        if isAssistantTyping {
                            TypingIndicator() // Now using shared component
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
            }
            
            Divider()
            
            // Optimized input area
            VStack(spacing: 8) {
                // Live word count (appears as you type)
                if !inputText.isEmpty && liveWordCount > 20 {
                    HStack {
                        Text("\(liveWordCount) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        // Contextual suggestions appear inline
                        if liveWordCount > 100 {
                            Text("Long form detected")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Performance-optimized text field
                    TextField("Share your thoughts...", text: $inputText, axis: .vertical)
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
                            updateLiveWordCountOptimized()
                            // Only analyze if text is reasonable length
                            if inputText.count < 2000 {
                                intelligenceEngine.analyzeInputInRealTime(inputText, workspaceType: WorkspaceManager.shared.getWorkspaceType(for: project))
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
                
                // File drop hint (minimal)
                if messages.isEmpty {
                    Text("Drop files here or start typing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .onAppear {
            loadMessages()
            isInputFocused = true
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers)
        }
    }
    
    private func loadMessages() {
        messages = ChatMessage.sampleMessages(for: project.id)
    }
    
    private func updateLiveWordCountOptimized() {
        // Optimize word counting for large texts
        if inputText.count > 5000 {
            // For very large texts, estimate word count
            liveWordCount = inputText.count / 5 // Rough estimate
        } else {
            // For normal texts, accurate word count
            let words = inputText.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            liveWordCount = words.count
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: trimmedText, role: .user, projectId: project.id)
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        liveWordCount = 0
        
        // Scroll to bottom
        scrollToBottom()
        
        // Generate intelligent response
        generateIntelligentResponse(for: userMessage)
    }
    
    private func generateIntelligentResponse(for userMessage: ChatMessage) {
        isAssistantTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAssistantTyping = false
            
            let workspaceType = WorkspaceManager.shared.getWorkspaceType(for: project)
            let response = intelligenceEngine.generateContextualResponse(
                userMessage: userMessage.content,
                workspaceType: workspaceType,
                conversationHistory: messages
            )
            
            var assistantMessage = ChatMessage(content: response, role: .assistant, projectId: project.id)
            assistantMessage.metadata = MessageMetadata(
                modelUsed: "Mistral-7B",
                tokensGenerated: Int.random(in: 50...150),
                responseTime: Double.random(in: 0.3...1.2),
                wasSpeculative: false
            )
            
            withAnimation(.easeOut) {
                messages.append(assistantMessage)
            }
            
            // Check if Arcana should offer proactive help
            intelligenceEngine.checkForProactiveAssistance(
                userMessage: userMessage.content,
                workspaceType: workspaceType
            ) { assistance in
                if let helpMessage = assistance {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        let helpResponse = ChatMessage(content: helpMessage, role: .assistant, projectId: project.id)
                        withAnimation(.easeOut) {
                            messages.append(helpResponse)
                        }
                        scrollToBottom()
                    }
                }
            }
            
            scrollToBottom()
        }
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
        
        // Instead of showing processing UI, Arcana just talks about the file
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let fileMessage = intelligenceEngine.generateFileProcessingResponse(
                fileName: fileName,
                fileExtension: fileExtension,
                workspaceType: WorkspaceManager.shared.getWorkspaceType(for: project)
            )
            
            let assistantMessage = ChatMessage(content: fileMessage, role: .assistant, projectId: project.id)
            withAnimation(.easeOut) {
                messages.append(assistantMessage)
            }
            scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
    }
}

struct OptimizedMessageView: View {
    let message: ChatMessage
    let showTechnicalInfo: Bool
    
    // Performance optimization: limit text rendering for very long messages
    private var displayContent: String {
        if message.content.count > 3000 {
            // For very long messages, show truncated version with option to expand
            return String(message.content.prefix(3000)) + "..."
        }
        return message.content
    }
    
    private var isTruncated: Bool {
        return message.content.count > 3000
    }
    
    @State private var showFullContent = false
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Optimized message content with truncation handling
                VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                    Text(showFullContent ? message.content : displayContent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(message.role == .user ? .blue : Color(NSColor.controlBackgroundColor))
                        )
                        .foregroundStyle(message.role == .user ? .white : .primary)
                    
                    // Show expand button for truncated messages
                    if isTruncated && !showFullContent {
                        Button("Show full message") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFullContent = true
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .buttonStyle(.plain)
                    }
                }
                
                // Minimal metadata (only if enabled)
                if showTechnicalInfo && message.role == .assistant {
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        if let metadata = message.metadata {
                            if let model = metadata.modelUsed {
                                Text("• \(model)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let responseTime = metadata.responseTime {
                                Text("• \(String(format: "%.1f", responseTime))s")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: 500, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    InvisibleChatView(project: Project.sampleProjects[0])
}
