// WorkspacePersistenceController.swift
// Created by Dylan E. | Spectral Labs
// Arcana - Privacy-first AI Assistant for macOS
//
// DEPENDENCIES: UnifiedTypes.swift, WorkspaceManager.swift

import Foundation

class WorkspacePersistenceController {
    
    private let fileManager = FileManager.default
    private var workspaceDirectory: URL {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let arcanaURL = appSupportURL.appendingPathComponent("Arcana")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: arcanaURL, withIntermediateDirectories: true)
        
        return arcanaURL.appendingPathComponent("Workspaces")
    }
    
    private var metadataURL: URL {
        return workspaceDirectory.appendingPathComponent("metadata.json")
    }
    
    init() {
        setupDirectories()
    }
    
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: workspaceDirectory, withIntermediateDirectories: true)
            print("📁 Workspace storage ready at: \(workspaceDirectory.path)")
        } catch {
            print("❌ Failed to create workspace directory: \(error)")
        }
    }
    
    // MARK: - Workspace Persistence
    
    func saveWorkspace(_ workspace: Project) {
        let workspaceURL = workspaceDirectory.appendingPathComponent("\(workspace.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(workspace)
            try data.write(to: workspaceURL)
            
            // Also update metadata for quick loading
            updateMetadata()
            
            print("💾 Saved workspace: \(workspace.title)")
        } catch {
            print("❌ Failed to save workspace \(workspace.title): \(error)")
        }
    }
    
    func loadWorkspaces() -> [Project] {
        var workspaces: [Project] = []
        
        do {
            let workspaceURLs = try fileManager.contentsOfDirectory(
                at: workspaceDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" && $0.lastPathComponent != "metadata.json" }
            
            for url in workspaceURLs {
                if let workspace = loadWorkspace(from: url) {
                    workspaces.append(workspace)
                }
            }
            
            print("📂 Loaded \(workspaces.count) workspaces from disk")
            
        } catch {
            print("❌ Failed to load workspaces: \(error)")
        }
        
        return workspaces.sorted { $0.lastModified > $1.lastModified }
    }
    
    private func loadWorkspace(from url: URL) -> Project? {
        do {
            let data = try Data(contentsOf: url)
            let workspace = try JSONDecoder().decode(Project.self, from: data)
            return workspace
        } catch {
            print("❌ Failed to load workspace from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    func deleteWorkspace(_ workspace: Project) {
        let workspaceURL = workspaceDirectory.appendingPathComponent("\(workspace.id.uuidString).json")
        
        do {
            try fileManager.removeItem(at: workspaceURL)
            updateMetadata()
            print("🗑️ Deleted workspace: \(workspace.title)")
        } catch {
            print("❌ Failed to delete workspace \(workspace.title): \(error)")
        }
    }
    
    // MARK: - Metadata Management
    
    private func updateMetadata() {
        let metadata = WorkspaceMetadata(
            lastUpdated: Date(),
            version: "1.0",
            totalWorkspaces: getWorkspaceCount()
        )
        
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("❌ Failed to update metadata: \(error)")
        }
    }
    
    private func getWorkspaceCount() -> Int {
        do {
            let contents = try fileManager.contentsOfDirectory(at: workspaceDirectory, includingPropertiesForKeys: nil)
            return contents.filter { $0.pathExtension == "json" && $0.lastPathComponent != "metadata.json" }.count
        } catch {
            return 0
        }
    }
    
    // MARK: - Backup and Export
    
    func exportAllWorkspaces() -> URL? {
        let exportURL = workspaceDirectory.appendingPathComponent("ArcanaBackup_\(Date().timeIntervalSince1970).json")
        
        let workspaces = loadWorkspaces()
        let backup = WorkspaceBackup(
            exportDate: Date(),
            version: "1.0",
            workspaces: workspaces
        )
        
        do {
            let data = try JSONEncoder().encode(backup)
            try data.write(to: exportURL)
            print("📦 Exported \(workspaces.count) workspaces to: \(exportURL.lastPathComponent)")
            return exportURL
        } catch {
            print("❌ Failed to export workspaces: \(error)")
            return nil
        }
    }
    
    func importWorkspaces(from url: URL) -> [Project] {
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(WorkspaceBackup.self, from: data)
            
            // Save each imported workspace
            for workspace in backup.workspaces {
                saveWorkspace(workspace)
            }
            
            print("📥 Imported \(backup.workspaces.count) workspaces")
            return backup.workspaces
            
        } catch {
            print("❌ Failed to import workspaces: \(error)")
            return []
        }
    }
    
    // MARK: - Storage Management
    
    func getStorageInfo() -> StorageInfo {
        var totalSize: Int64 = 0
        var fileCount = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: workspaceDirectory,
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
            print("❌ Failed to calculate storage info: \(error)")
        }
        
        return StorageInfo(
            totalSizeBytes: totalSize,
            fileCount: fileCount,
            directory: workspaceDirectory
        )
    }
    
    func cleanupOldBackups() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: workspaceDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let backupFiles = contents.filter { $0.lastPathComponent.hasPrefix("ArcanaBackup_") }
            
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
                    print("🧹 Cleaned up old backup: \(backup.lastPathComponent)")
                }
            }
            
        } catch {
            print("❌ Failed to cleanup old backups: \(error)")
        }
    }
}

// MARK: - Data Models

private struct WorkspaceMetadata: Codable {
    let lastUpdated: Date
    let version: String
    let totalWorkspaces: Int
}

private struct WorkspaceBackup: Codable {
    let exportDate: Date
    let version: String
    let workspaces: [Project]
}

struct StorageInfo {
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
