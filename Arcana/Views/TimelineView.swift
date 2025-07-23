// TimelineView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct TimelineView: View {
    let project: Project
    @State private var selectedMessageIndex: Int = 0
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeline Header
            HStack {
                Text("Conversation Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Fork Here") {
                    forkConversation()
                }
                .buttonStyle(.bordered)
                .disabled(messages.isEmpty)
            }
            .padding()
            
            Divider()
            
            if !messages.isEmpty {
                // Timeline Slider
                VStack(spacing: 16) {
                    HStack {
                        Text("Message \(selectedMessageIndex + 1) of \(messages.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(messages[selectedMessageIndex].timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(selectedMessageIndex) },
                            set: { selectedMessageIndex = Int($0) }
                        ),
                        in: 0...Double(messages.count - 1),
                        step: 1
                    )
                    .tint(.blue)
                }
                .padding()
                
                Divider()
                
                // Message Preview
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0...selectedMessageIndex, id: \.self) { index in
                            MessageTimelineItem(
                                message: messages[index],
                                isSelected: index == selectedMessageIndex
                            )
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    
                    Text("No conversation history")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Start a conversation to see the timeline")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadTimelineData()
        }
    }
    
    private func loadTimelineData() {
        // TODO: Load actual conversation history
        messages = ChatMessage.sampleMessages(for: project.id)
        selectedMessageIndex = max(0, messages.count - 1)
    }
    
    private func forkConversation() {
        // TODO: Implement conversation forking
        print("Fork conversation at message \(selectedMessageIndex)")
    }
}

struct MessageTimelineItem: View {
    let message: ChatMessage
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Role indicator
            Circle()
                .fill(message.role == .user ? Color.blue : Color.green)
                .frame(width: 8, height: 8)
                .offset(y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.role.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(message.role == .user ? .blue : .green)
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Text(message.content)
                    .font(.callout)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(isSelected ? nil : 3)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview {
    TimelineView(project: Project.sampleProjects[0])
        .frame(width: 400, height: 600)
}
