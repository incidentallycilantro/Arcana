// NewProjectSheet.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import SwiftUI

struct NewProjectSheet: View {
    let onProjectCreated: ((title: String, description: String)) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @FocusState private var titleFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with elegant gradient background
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 4) {
                    Text("Create New Workspace")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Design a dedicated space for focused AI collaboration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            // Main content
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workspace Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., Creative Writing, Code Review, Market Research", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($titleFieldFocused)
                        .onSubmit {
                            if canCreate {
                                createProject()
                            }
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Describe what you'll use this project for...", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            
            Spacer()
            
            // Action buttons with modern styling
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)
                
                Button("Create Workspace") {
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canCreate)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(width: 480, height: 400)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            titleFieldFocused = true
        }
    }
    
    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createProject() {
        onProjectCreated((title: title, description: description))
        dismiss()
    }
}
