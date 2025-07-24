// ThreadPersistenceController.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS

import Foundation

class ThreadPersistenceController {
    
    private let fileManager = FileManager.default
    private var threadsDirectory: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let arcanaURL = appSupportURL.appendingPathComponent("Arcana")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: arcanaURL, withIntermediateDirectories: true)
        
        return arcanaURL.appendingPathComponent("Threads")
    }
    
    private var metadataURL: URL {
        return threadsDirectory.appendingPathComponent("metadata.json")
    }
    
    init() {
        setupDirectories()
    }
    
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: threadsDirectory, withIntermediateDirectories: true)
            print("📁 Thread storage ready at: \(threadsDirectory.path)")
        } catch {
            print("❌ Failed to create threads directory: \(error)")
        }
    }
    
    // MARK: - Thread Persistence
    
    func saveThread(_ thread: ConversationThread) {
        let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(thread)
            try data.write(to: threadURL)
            
            // Update metadata for quick loading
            updateMetadata()
            
            print("💾 Saved thread: \(thread.title)")
        } catch {
            print("❌ Failed to save thread \(thread.title): \(error)")
        }
    }
    
    func loadThreads() -> [ConversationThread] {
        var threads: [ConversationThread] = []
        
        do {
            let threadURLs = try fileManager.contentsOfDirectory(
                at: threadsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" && $0.lastPathComponent != "metadata.json" }
            
            for url in threadURLs {
                if let thread = loadThread(from: url) {
                    threads.append(thread)
                }
            }
            
            print("📂 Loaded \(threads.count) threads from disk")
            
        } catch {
            print("❌ Failed to load threads: \(error)")
        }
        
        return threads.sorted { $0.lastModified > $1.lastModified }
    }
    
    private func loadThread(from url: URL) -> ConversationThread? {
        do {
            let data = try Data(contentsOf: url)
            let thread = try JSONDecoder().decode(ConversationThread.self, from: data)
            return thread
        } catch {
            print("❌ Failed to load thread from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    func deleteThread(_ thread: ConversationThread) {
        let threadURL = threadsDirectory.appendingPathComponent("\(thread.id.uuidString).json")
        
        do {
            try fileManager.removeItem(at: threadURL)
            updateMetadata()
            print("🗑️ Deleted thread: \(thread.title)")
        } catch {
            print("❌ Failed to delete thread \(thread.title): \(error)")
        }
    }
    
    // MARK: - Metadata Management
    
    private func updateMetadata() {
        let metadata = ThreadMetadata(
            lastUpdated: Date(),
            version: "1.0",
            totalThreads: getThreadCount()
        )
        
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("❌ Failed to update thread metadata: \(error)")
        }
    }
    
    private func getThreadCount() -> Int {
        do {
            let contents = try fileManager.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil)
            return contents.filter { $0.pathExtension == "json" && $0.lastPathComponent != "metadata.json" }.count
        } catch {
            return 0
        }
    }
    
    // MARK: - Backup and Export
    
    func exportAllThreads() -> URL? {
        let exportURL = threadsDirectory.appendingPathComponent("ArcanaThreadsBackup_\(Date().timeIntervalSince1970).json")
        
        let threads = loadThreads()
        let backup = ThreadBackup(
            exportDate: Date(),
            version: "1.0",
            threads: threads
        )
        
        do {
            let data = try JSONEncoder().encode(backup)
            try data.write(to: exportURL)
            print("📦 Exported \(threads.count) threads to: \(exportURL.lastPathComponent)")
            return exportURL
        } catch {
            print("❌ Failed to export threads: \(error)")
            return nil
        }
    }
    
    func importThreads(from url: URL) -> [ConversationThread] {
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(ThreadBackup.self, from: data)
            
            // Save each imported thread
            for thread in backup.threads {
                saveThread(thread)
            }
            
            print("📥 Imported \(backup.threads.count) threads")
            return backup.threads
            
        } catch {
            print("❌ Failed to import threads: \(error)")
            return []
        }
    }
    
    // MARK: - Storage Management
    
    func getStorageInfo() -> ThreadStorageInfo {
        var totalSize: Int64 = 0
        var fileCount = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: threadsDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            for url in contents {
                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resources.fileSize {
                    totalSize += Int64(fileSize)
                    fileCount += 1
                }
            }
            
        } catch {
            print("❌ Failed to calculate thread storage info: \(error)")
        }
        
        return ThreadStorageInfo(
            totalSizeBytes: totalSize,
            fileCount: fileCount,
            directory: threadsDirectory
        )
    }
    
    func cleanupOldBackups() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: threadsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let backupFiles = contents.filter { $0.lastPathComponent.hasPrefix("ArcanaThreadsBackup_") }
            
            // Keep only the 5 most recent backups
            if backupFiles.count > 5 {
                let sortedBackups = backupFiles.sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
                
                let backupsToDelete = Array(sortedBackups.dropFirst(5))
                for backup in backupsToDelete {
                    try fileManager.removeItem(at: backup)
                    print("🧹 Cleaned up old thread backup: \(backup.lastPathComponent)")
                }
            }
            
        } catch {
            print("❌ Failed to cleanup old thread backups: \(error)")
        }
    }
}

// MARK: - Data Models

private struct ThreadMetadata: Codable {
    let lastUpdated: Date
    let version: String
    let totalThreads: Int
}

private struct ThreadBackup: Codable {
    let exportDate: Date
    let version: String
    let threads: [ConversationThread]
}

struct ThreadStorageInfo {
    let totalSizeBytes: Int64
    let fileCount: Int
    let directory: URL
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }
}
