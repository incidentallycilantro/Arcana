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
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
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
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
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
            
            // Input Area
            VStack(spacing: 8) {
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
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Quick actions or file drop area could go here
            }
            .padding()
        }
        .onAppear {
            loadMessages()
            isInputFocused = true
        }
    }
    
    private func loadMessages() {
        messages = ChatMessage.sampleMessages(for: project.id)
        lastMessageCount = messages.count
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: trimmedText, role: .user, projectId: project.id)
        messages.append(userMessage)
        
        // Scroll to bottom
        scrollToBottom()
        
        // Clear input
        inputText = ""
        
        // Simulate assistant response
        simulateAssistantResponse()
    }
    
    private func simulateAssistantResponse() {
        isAssistantTyping = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAssistantTyping = false
            
            let responses = [
                "I understand! Let me help you with that.",
                "That's a great question. Here's what I think...",
                "Based on what you've shared, I'd suggest...",
                "I can definitely help you explore this further."
            ]
            
            let randomResponse = responses.randomElement() ?? responses[0]
            let assistantMessage = ChatMessage(content: randomResponse, role: .assistant, projectId: project.id)
            
            withAnimation(.easeOut) {
                messages.append(assistantMessage)
            }
            
            // Scroll to bottom after response
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToBottom()
            }
        }
    }
    
    private func scrollToBottom() {
        NotificationCenter.default.post(name: NSNotification.Name("ScrollToBottom"), object: nil)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? Color.blue : Color(NSColor.controlBackgroundColor))
                    )
                    .foregroundStyle(message.role == .user ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 400, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.secondary)
                            .frame(width: 6, height: 6)
                            .opacity(animationPhase == index ? 1 : 0.3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                Text("Arcana is typing...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    ChatView(project: Project.sampleProjects[0])
        .frame(width: 600, height: 500)
}
