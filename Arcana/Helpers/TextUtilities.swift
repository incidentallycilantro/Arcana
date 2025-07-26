// TextUtilities.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift

import Foundation

struct TextUtilities {
    
    // Token counting estimate (rough approximation)
    static func estimateTokenCount(_ text: String) -> Int {
        // Rough estimate: ~4 characters per token
        return max(1, text.count / 4)
    }
    
    // Text chunking for large documents
    static func chunkText(_ text: String, maxChunkSize: Int = 1000) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var chunks: [String] = []
        var currentChunk = ""
        
        for word in words {
            if currentChunk.count + word.count + 1 <= maxChunkSize {
                if !currentChunk.isEmpty {
                    currentChunk += " "
                }
                currentChunk += word
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = word
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    // Clean text for processing
    static func cleanText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    // Extract key phrases (placeholder implementation)
    static func extractKeyPhrases(from text: String) -> [String] {
        // TODO: Implement proper key phrase extraction
        // This is a simple placeholder
        return text
            .components(separatedBy: .punctuationCharacters)
            .compactMap { phrase in
                let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.count > 10 ? cleaned : nil
            }
            .prefix(5)
            .map { String($0) }
    }
}
