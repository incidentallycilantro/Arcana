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
            // Enhanced sidebar with contextual organization
            ContextualSidebar()
                .frame(minWidth: 280, maxWidth: 350)
        } detail: {
            // Main chat area - always available, contextually smart
            Group {
                if let activeThread = threadManager.activeThread {
                    ContextualChatView(thread: activeThread)
                } else {
                    // Default instant chat - no project required
                    InstantChatView()
                }
            }
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
                    threadManager.createInstantThread()
                }) {
                    Image(systemName: "plus.message")
                }
                .help("New Conversation")
            }
        }
        .onAppear {
            // Always ensure there's an active thread for immediate use
            if threadManager.activeThread == nil {
                threadManager.createInstantThread()
            }
        }
    }
}

struct InstantChatView: View {
    @StateObject private var threadManager = ThreadManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean, welcoming header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 8) {
                    Text("Ready to think together")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Start a conversation about anything")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Immediate input area
            InstantInputArea()
        }
    }
}

struct InstantInputArea: View {
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var intelligenceEngine = IntelligenceEngine()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                TextField("What's on your mind?", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .focused($isInputFocused)
                    .lineLimit(1...10)
                    .onSubmit {
                        startConversation()
                    }
                
                Button(action: startConversation) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Smart suggestions for getting started
            SmartStarterSuggestions()
        }
        .padding()
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func startConversation() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Create or use existing instant thread
        let thread = threadManager.getOrCreateInstantThread()
        
        // Add the message and switch to chat view
        threadManager.addMessage(trimmedText, to: thread)
        threadManager.activeThread = thread
        
        // Clear input
        inputText = ""
        
        // Generate contextual response
        intelligenceEngine.generateContextualResponse(
            userMessage: trimmedText,
            workspaceType: .general,
            conversationHistory: thread.messages
        ) { response in
            threadManager.addAssistantMessage(response, to: thread)
            
            // Offer contextual organization after meaningful exchange
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                threadManager.evaluateForProjectPromotion(thread)
            }
        }
    }
}

struct SmartStarterSuggestions: View {
    @StateObject private var threadManager = ThreadManager.shared
    
    private let suggestions = [
        "Help me brainstorm ideas for...",
        "I need to review some code",
        "Can you help me write something?",
        "I want to research a topic"
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        startSuggestedConversation(suggestion)
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
    
    private func startSuggestedConversation(_ suggestion: String) {
        let thread = threadManager.getOrCreateInstantThread()
        threadManager.addMessage(suggestion, to: thread)
        threadManager.activeThread = thread
        
        // Generate helpful response based on suggestion type
        let response = generateSuggestedResponse(for: suggestion)
        threadManager.addAssistantMessage(response, to: thread)
    }
    
    private func generateSuggestedResponse(for suggestion: String) -> String {
        switch suggestion {
        case let s where s.contains("brainstorm"):
            return "I'd love to help you brainstorm! What topic or challenge are you working on? I can help generate ideas, explore different angles, or organize your thoughts."
            
        case let s where s.contains("code"):
            return "Great! I can help review code for improvements, debug issues, explain complex logic, or suggest best practices. Feel free to paste your code or describe what you're working on."
            
        case let s where s.contains("write"):
            return "I'm here to help with your writing! Whether it's creative content, technical documentation, emails, or any other writing project, I can assist with structure, tone, and clarity. What are you looking to write?"
            
        case let s where s.contains("research"):
            return "Perfect! I can help you research topics, analyze information, find connections between ideas, and organize your findings. What subject would you like to explore?"
            
        default:
            return "I'm ready to help with whatever you're thinking about. What would you like to explore together?"
        }
    }
}

#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
