// ChatView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct ChatView: View {
    let project: Project
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isAssistantTyping = false
    @State private var lastMessageCount = 0
    @FocusState private var isInputFocused: Bool
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var toolController = SmartToolController()
    @State private var showingToolFeedback = false
    @State private var toolFeedback: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header with Smart Feedback
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !project.description.isEmpty {
                            Text(project.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator with workspace type
                    HStack(spacing: 8) {
                        let workspaceType = WorkspaceManager.shared.getWorkspaceType(for: project)
                        Text(workspaceType.emoji)
                            .font(.caption)
                        
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Ready")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                            TypingIndicator()
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
            
            // Enhanced Input Area with Smart Suggestions
            VStack(spacing: 8) {
                // Smart suggestions based on workspace type
                if !inputText.isEmpty {
                    SmartSuggestionsBar(
                        workspaceType: WorkspaceManager.shared.getWorkspaceType(for: project),
                        inputText: inputText,
                        onSuggestionTap: { suggestion in
                            inputText = suggestion
                        }
                    )
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type your message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .focused($isInputFocused)
                        .lineLimit(1...10)
                        .onSubmit {
                            sendMessage()
                        }
                        .onChange(of: inputText) {
                            // Real-time smart analysis
                            analyzeInput()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // File drop area hint
                if messages.isEmpty {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(.secondary)
                        Text("Drop files here to analyze with AI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
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
        messages = []
        lastMessageCount = messages.count
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: trimmedText, isFromUser: true)
        messages.append(userMessage)
        
        // Scroll to bottom
        scrollToBottom()
        
        // Clear input
        inputText = ""
        
        // Smart context analysis before response
        analyzeMessageContext(userMessage)
        
        // Simulate assistant response
        simulateAssistantResponse()
    }
    
    private func simulateAssistantResponse() {
        isAssistantTyping = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAssistantTyping = false
            
            let workspaceType = WorkspaceManager.shared.getWorkspaceType(for: project)
            let responses = responsesForWorkspaceType(workspaceType)
            
            let randomResponse = responses.randomElement() ?? "I can help you with that."
            
            // Create assistant message with metadata
            var assistantMessage = ChatMessage(content: randomResponse, isFromUser: false)
            assistantMessage.metadata = MessageMetadata()
            
            withAnimation(.easeOut) {
                messages.append(assistantMessage)
            }
            
            // Scroll to bottom after response
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToBottom()
            }
        }
    }
    
    private func responsesForWorkspaceType(_ type: WorkspaceManager.WorkspaceType) -> [String] {
        switch type {
        case .code:
            return [
                "I can help you analyze this code. Would you like me to check for optimizations?",
                "Let me review the code structure and suggest improvements.",
                "I notice this is code-related. I can help with debugging, documentation, or testing."
            ]
        case .creative:
            return [
                "That's an interesting creative direction! Let me help you develop this further.",
                "I can help refine the tone and style of your writing.",
                "Great creative work! Would you like me to analyze the narrative structure?"
            ]
        case .research:
            return [
                "I can help verify those claims and find supporting evidence.",
                "Let me analyze the data and provide insights on the research.",
                "I notice this involves research. I can help with fact-checking and citations."
            ]
        case .general:
            return [
                "I understand! Let me help you with that.",
                "That's a great question. Here's what I think...",
                "Based on what you've shared, I'd suggest...",
                "I can definitely help you explore this further."
            ]
        }
    }
    
    private func analyzeInput() {
        // Real-time input analysis for smart suggestions
        guard !inputText.isEmpty else { return }
        
        let workspaceType = WorkspaceManager.shared.getWorkspaceType(for: project)
        
        // Provide contextual feedback
        if inputText.count > 500 && workspaceType == .creative {
            showToolFeedback("Long form detected - consider using summarization tools")
        } else if inputText.contains("function") || inputText.contains("class") && workspaceType == .code {
            showToolFeedback("Code detected - formatting and analysis tools are available")
        }
    }
    
    private func analyzeMessageContext(_ message: ChatMessage) {
        let workspaceType = WorkspaceManager.shared.getWorkspaceType(for: project)
        
        // Trigger appropriate tool suggestions
        switch workspaceType {
        case .code:
            if message.content.contains("error") || message.content.contains("debug") {
                showToolFeedback("Code debugging tools are active in Smart Gutter")
            }
        case .creative:
            if message.content.count > 200 {
                showToolFeedback("Writing analysis tools available for longer content")
            }
        case .research:
            if message.content.contains("study") || message.content.contains("research") {
                showToolFeedback("Fact-checking and citation tools are ready")
            }
        case .general:
            break
        }
    }
    
    private func showToolFeedback(_ message: String) {
        toolFeedback = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToolFeedback = true
        }
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingToolFeedback = false
            }
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
        
        // Show appropriate file processing message
        let fileMessage = "📎 Processing \(fileName)..."
        inputText = fileMessage
        
        // Simulate file processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let processedMessage = generateFileProcessingMessage(fileName: fileName, extension: fileExtension)
            inputText = processedMessage
            showToolFeedback("File processed - use Smart Gutter tools for analysis")
        }
    }
    
    private func generateFileProcessingMessage(fileName: String, extension fileExtension: String) -> String {
        switch fileExtension {
        case "pdf":
            return "I've analyzed the PDF '\(fileName)'. What would you like to know about its contents?"
        case "docx", "doc":
            return "I've processed the document '\(fileName)'. I can summarize, extract key points, or analyze the content."
        case "swift", "py", "js", "java":
            return "I've reviewed the code file '\(fileName)'. I can help with analysis, documentation, or improvements."
        case "md", "txt":
            return "I've read '\(fileName)'. How can I help you work with this content?"
        default:
            return "I've processed '\(fileName)'. What would you like me to help you with?"
        }
    }
    
    private func scrollToBottom() {
        NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
    }
}

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
                            
                            if let tokens = metadata.tokensGenerated {
                                Text("• \(tokens) tokens")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let responseTime = metadata.responseTime {
                                Text("• \(String(format: "%.1f", responseTime))s")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if metadata.wasSpeculative == true {
                                Text("• ⚡")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .help("Speculative response")
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: 400, alignment: message.isFromUser ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct SmartSuggestionsBar: View {
    let workspaceType: WorkspaceManager.WorkspaceType
    let inputText: String
    let onSuggestionTap: (String) -> Void
    
    var suggestions: [String] {
        switch workspaceType {
        case .code:
            return [
                "Can you review this code for improvements?",
                "Help me debug this function",
                "Generate documentation for this code",
                "Write unit tests for this"
            ]
        case .creative:
            return [
                "Help me improve the tone of this writing",
                "Can you check the grammar?",
                "Suggest ways to make this more engaging",
                "Analyze the writing style"
            ]
        case .research:
            return [
                "Can you fact-check this information?",
                "Help me find sources for this claim",
                "Summarize the key findings",
                "Generate citations for this research"
            ]
        case .general:
            return [
                "Can you help me with this?",
                "Please explain this in simpler terms",
                "What are the key points here?",
                "Can you summarize this?"
            ]
        }
    }
    
    var body: some View {
        if inputText.count > 20 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                        Button(suggestion) {
                            onSuggestionTap(suggestion)
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
        }
    }
}

#Preview {
    ChatView(project: Project.sampleProjects[0])
        .frame(width: 600, height: 500)
}
