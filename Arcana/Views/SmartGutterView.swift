// SmartGutterView.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct SmartGutterView: View {
    let workspace: Project
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var toolController = SmartToolController()
    @State private var showingOverlay = false
    @State private var overlayContent: OverlayContent?
    
    var workspaceType: WorkspaceManager.WorkspaceType {
        workspaceManager.getWorkspaceType(for: workspace)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Workspace Type Indicator
            VStack(spacing: 4) {
                Text(workspaceType.emoji)
                    .font(.title2)
                
                Text(workspaceType.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Context-Specific Tools
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(toolsForWorkspace, id: \.id) { tool in
                        SmartToolButton(
                            tool: tool,
                            workspace: workspace,
                            action: {
                                performToolAction(tool)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
        }
        .frame(width: 60)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            // Tool Overlay
            Group {
                if showingOverlay, let content = overlayContent {
                    ToolOverlayView(content: content) {
                        showingOverlay = false
                        overlayContent = nil
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: showingOverlay)
    }
    
    private var toolsForWorkspace: [SmartTool] {
        switch workspaceType {
        case .code:
            return [
                SmartTool(id: "format", icon: "curlybraces", title: "Format Code", description: "Format and beautify code"),
                SmartTool(id: "analyze", icon: "magnifyingglass.circle", title: "Analyze", description: "Code analysis and suggestions"),
                SmartTool(id: "docs", icon: "doc.text", title: "Generate Docs", description: "Auto-generate documentation"),
                SmartTool(id: "test", icon: "checkmark.circle", title: "Write Tests", description: "Generate unit tests")
            ]
        case .creative:
            return [
                SmartTool(id: "wordcount", icon: "textformat.123", title: "Word Count", description: "Live word and character count"),
                SmartTool(id: "tone", icon: "waveform", title: "Tone Check", description: "Analyze writing tone"),
                SmartTool(id: "grammar", icon: "checkmark.circle.badge", title: "Grammar", description: "Grammar and style check"),
                SmartTool(id: "summarize", icon: "doc.plaintext", title: "Summarize", description: "Create content summary")
            ]
        case .research:
            return [
                SmartTool(id: "factcheck", icon: "checkmark.shield", title: "Fact Check", description: "Verify claims and facts"),
                SmartTool(id: "cite", icon: "quote.bubble", title: "Citations", description: "Generate citations"),
                SmartTool(id: "extract", icon: "rectangle.and.text.magnifyingglass", title: "Extract Data", description: "Extract key insights"),
                SmartTool(id: "timeline", icon: "calendar", title: "Timeline", description: "Create chronological timeline")
            ]
        case .general:
            return [
                SmartTool(id: "summarize", icon: "doc.plaintext", title: "Summarize", description: "Quick summary"),
                SmartTool(id: "translate", icon: "globe", title: "Translate", description: "Language translation"),
                SmartTool(id: "clarify", icon: "questionmark.circle", title: "Clarify", description: "Ask for clarification"),
                SmartTool(id: "export", icon: "square.and.arrow.up", title: "Export", description: "Export conversation")
            ]
        }
    }
    
    private func performToolAction(_ tool: SmartTool) {
        switch tool.id {
        case "wordcount":
            showWordCountOverlay()
        case "format":
            formatCode()
        case "grammar":
            performGrammarCheck()
        case "factcheck":
            performFactCheck()
        case "summarize":
            generateSummary()
        case "tone":
            analyzeTone()
        case "translate":
            showTranslationOverlay()
        case "export":
            exportConversation()
        default:
            showGenericToolOverlay(for: tool)
        }
    }
    
    // MARK: - Tool Actions
    
    private func showWordCountOverlay() {
        let stats = toolController.getConversationStats(for: workspace)
        overlayContent = OverlayContent(
            title: "Writing Statistics",
            content: """
            Words: \(stats.wordCount)
            Characters: \(stats.characterCount)
            Paragraphs: \(stats.paragraphCount)
            Avg. words per message: \(stats.avgWordsPerMessage)
            
            Reading time: ~\(stats.readingTimeMinutes) min
            """,
            type: .info
        )
        showingOverlay = true
    }
    
    private func formatCode() {
        toolController.formatCodeInConversation(workspace: workspace) { result in
            DispatchQueue.main.async {
                overlayContent = OverlayContent(
                    title: "Code Formatting",
                    content: result.success ? "Code formatted successfully!" : "Error: \(result.error ?? "Unknown error")",
                    type: result.success ? .success : .error
                )
                showingOverlay = true
            }
        }
    }
    
    private func performGrammarCheck() {
        toolController.checkGrammar(workspace: workspace) { result in
            DispatchQueue.main.async {
                overlayContent = OverlayContent(
                    title: "Grammar Check",
                    content: result.suggestions.isEmpty ? "No issues found!" : result.suggestions.joined(separator: "\n\n"),
                    type: .info
                )
                showingOverlay = true
            }
        }
    }
    
    private func performFactCheck() {
        toolController.factCheck(workspace: workspace) { result in
            DispatchQueue.main.async {
                overlayContent = OverlayContent(
                    title: "Fact Check Results",
                    content: "Verified \(result.verifiedClaims) claims\nFlagged \(result.flaggedClaims) for review",
                    type: result.flaggedClaims > 0 ? .warning : .success
                )
                showingOverlay = true
            }
        }
    }
    
    private func generateSummary() {
        toolController.generateSummary(workspace: workspace) { summary in
            DispatchQueue.main.async {
                overlayContent = OverlayContent(
                    title: "Conversation Summary",
                    content: summary,
                    type: .info
                )
                showingOverlay = true
            }
        }
    }
    
    private func analyzeTone() {
        let analysis = toolController.analyzeTone(workspace: workspace)
        overlayContent = OverlayContent(
            title: "Tone Analysis",
            content: """
            Primary tone: \(analysis.primaryTone)
            Confidence: \(Int(analysis.confidence * 100))%
            
            Detected emotions:
            \(analysis.emotions.map { "• \($0)" }.joined(separator: "\n"))
            """,
            type: .info
        )
        showingOverlay = true
    }
    
    private func showTranslationOverlay() {
        overlayContent = OverlayContent(
            title: "Translation",
            content: "Select text and choose target language to translate conversation elements.",
            type: .info
        )
        showingOverlay = true
    }
    
    private func exportConversation() {
        toolController.exportConversation(workspace: workspace) { success in
            DispatchQueue.main.async {
                overlayContent = OverlayContent(
                    title: "Export Complete",
                    content: success ? "Conversation exported to Downloads folder" : "Export failed - please try again",
                    type: success ? .success : .error
                )
                showingOverlay = true
            }
        }
    }
    
    private func showGenericToolOverlay(for tool: SmartTool) {
        overlayContent = OverlayContent(
            title: tool.title,
            content: "🚧 This tool is being developed.\n\n\(tool.description)\n\nComing soon in Phase 3!",
            type: .info
        )
        showingOverlay = true
    }
}

struct SmartToolButton: View {
    let tool: SmartTool
    let workspace: Project
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isHovered ? .blue : .primary)
                    .frame(width: 20, height: 20)
                
                Text(tool.title.prefix(4))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isHovered ? .blue : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(tool.description)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Supporting Types

struct SmartTool: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
}

struct OverlayContent {
    let title: String
    let content: String
    let type: OverlayType
    
    enum OverlayType {
        case info, success, warning, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
}

struct ToolOverlayView: View {
    let content: OverlayContent
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: content.type.icon)
                    .foregroundColor(content.type.color)
                
                Text(content.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                Text(content.content)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            
            HStack {
                Spacer()
                Button("Done", action: onDismiss)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
        .frame(minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(content.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SmartGutterView(workspace: Project.sampleProjects[0])
        .frame(height: 400)
}
