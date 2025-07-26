//
// WorkspaceManager.swift
// Arcana - Unified Workspace Management System
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
// DEPENDENCIES: UnifiedTypes.swift, WorkspaceManager.swift, Project.swift

import Foundation
import SwiftUI
import Combine

// MARK: - Main Workspace Manager

@MainActor
class WorkspaceManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = WorkspaceManager()
    
    // MARK: - Published Properties
    @Published var workspaces: [Project] = []
    @Published var selectedWorkspace: Project?
    @Published var showNewWorkspaceSheet = false
    @Published var showStorageInfoSheet = false
    
    // MARK: - Workspace Intelligence
    @Published var intelligenceEngine = IntelligenceEngine.shared
    @Published var isAnalyzingWorkspace = false
    @Published var workspaceRecommendations: [WorkspaceRecommendation] = []
    
    // MARK: - Storage Information
    @Published var totalStorageUsed: Int64 = 0
    @Published var workspaceCount: Int = 0
    @Published var lastBackupDate: Date?
    
    // MARK: - Private Properties
    private let persistenceController = WorkspacePersistenceController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadWorkspaces()
        setupStorageMonitoring()
        
        // Monitor workspace changes for intelligent recommendations
        $workspaces
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateWorkspaceRecommendations()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Workspace CRUD Operations
    
    func createWorkspace(title: String, description: String = "", type: WorkspaceType? = nil) {
        let workspace = Project(title: title, description: description)
        
        // Set workspace type if provided
        if let detectedType = type {
            // Note: In a complete implementation, we'd add workspace type to Project model
            // For now, we track this through the intelligence engine
            Task {
                await intelligenceEngine.updateWorkspaceTypeDetection(workspace.id, type: detectedType)
            }
        }
        
        workspaces.insert(workspace, at: 0)
        selectedWorkspace = workspace
        saveWorkspace(workspace)
        
        updateStorageInfo()
    }
    
    func duplicateWorkspace(_ workspace: Project) {
        let duplicate = Project(
            title: "\(workspace.title) Copy",
            description: workspace.description
        )
        
        workspaces.insert(duplicate, at: workspaces.firstIndex(of: workspace)! + 1)
        saveWorkspace(duplicate)
        updateStorageInfo()
    }
    
    func deleteWorkspace(_ workspace: Project) {
        workspaces.removeAll { $0.id == workspace.id }
        
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = workspaces.first
        }
        
        persistenceController.deleteWorkspace(workspace)
        updateStorageInfo()
    }
    
    func pinWorkspace(_ workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].isPinned.toggle()
            saveWorkspace(workspaces[index])
            
            // Re-sort workspaces to move pinned ones to top
            sortWorkspaces()
        }
    }
    
    func saveWorkspaceFromExternal(_ workspace: Project) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
        } else {
            workspaces.append(workspace)
        }
        saveWorkspace(workspace)
        updateStorageInfo()
    }
    
    // MARK: - Workspace Intelligence
    
    func getWorkspaceType(for workspace: Project) -> WorkspaceType {
        // In a complete implementation, this would query the intelligence engine
        // For now, return a basic detection based on workspace content
        let title = workspace.title.lowercased()
        let description = workspace.description.lowercased()
        let combinedText = "\(title) \(description)"
        
        // Code-related keywords
        let codeKeywords = ["code", "development", "programming", "api", "git", "repo", "swift", "javascript", "python"]
        if codeKeywords.contains(where: { combinedText.contains($0) }) {
            return .code
        }
        
        // Creative keywords
        let creativeKeywords = ["creative", "writing", "story", "design", "art", "content", "blog", "marketing"]
        if creativeKeywords.contains(where: { combinedText.contains($0) }) {
            return .creative
        }
        
        // Research keywords
        let researchKeywords = ["research", "analysis", "study", "data", "report", "academic", "thesis", "review"]
        if researchKeywords.contains(where: { combinedText.contains($0) }) {
            return .research
        }
        
        return .general
    }
    
    func analyzeWorkspaceIntelligence(for workspace: Project) async -> WorkspaceIntelligence {
        isAnalyzingWorkspace = true
        defer { isAnalyzingWorkspace = false }
        
        // Simulate intelligent analysis
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let detectedType = getWorkspaceType(for: workspace)
        let contentDepth = calculateContentDepth(workspace)
        let usagePattern = analyzeUsagePattern(workspace)
        
        return WorkspaceIntelligence(
            workspaceId: workspace.id,
            detectedType: detectedType,
            confidence: 0.85,
            contentDepth: contentDepth,
            usagePattern: usagePattern,
            recommendedActions: generateRecommendedActions(for: workspace, type: detectedType),
            lastAnalyzed: Date()
        )
    }
    
    private func calculateContentDepth(_ workspace: Project) -> Double {
        // Basic calculation - in real implementation would analyze conversation history
        let titleLength = workspace.title.count
        let descriptionLength = workspace.description.count
        return min(Double(titleLength + descriptionLength) / 200.0, 1.0)
    }
    
    private func analyzeUsagePattern(_ workspace: Project) -> UsagePattern {
        let daysSinceCreated = Date().timeIntervalSince(workspace.createdAt) / (24 * 60 * 60)
        let daysSinceModified = Date().timeIntervalSince(workspace.lastModified) / (24 * 60 * 60)
        
        if daysSinceModified < 1 {
            return .veryActive
        } else if daysSinceModified < 7 {
            return .active
        } else if daysSinceModified < 30 {
            return .moderate
        } else {
            return .inactive
        }
    }
    
    private func generateRecommendedActions(for workspace: Project, type: WorkspaceType) -> [String] {
        var actions: [String] = []
        
        switch type {
        case .code:
            actions.append("Set up code review templates")
            actions.append("Enable development tools integration")
            actions.append("Add project documentation templates")
        case .creative:
            actions.append("Enable creative writing aids")
            actions.append("Set up inspiration collections")
            actions.append("Add creative project templates")
        case .research:
            actions.append("Enable research citation tools")
            actions.append("Set up literature review templates")
            actions.append("Add data analysis capabilities")
        case .general:
            actions.append("Customize for your specific needs")
            actions.append("Add relevant templates")
            actions.append("Set up productivity workflows")
        }
        
        return actions
    }
    
    private func updateWorkspaceRecommendations() async {
        var recommendations: [WorkspaceRecommendation] = []
        
        // Analyze workspace patterns
        let activeWorkspaces = workspaces.filter { workspace in
            Date().timeIntervalSince(workspace.lastModified) < 7 * 24 * 60 * 60 // Last 7 days
        }
        
        // Recommend workspace organization
        if workspaces.count > 5 && workspaces.filter({ $0.isPinned }).count == 0 {
            recommendations.append(WorkspaceRecommendation(
                type: .organization,
                title: "Pin Frequently Used Workspaces",
                description: "Pin your most important workspaces for quick access",
                priority: .medium,
                action: "pin_workspaces"
            ))
        }
        
        // Recommend workspace creation based on patterns
        let typeDistribution = workspaces.reduce(into: [WorkspaceType: Int]()) { result, workspace in
            let type = getWorkspaceType(for: workspace)
            result[type, default: 0] += 1
        }
        
        if typeDistribution[.code, default: 0] > 2 && typeDistribution[.research, default: 0] == 0 {
            recommendations.append(WorkspaceRecommendation(
                type: .creation,
                title: "Create Research Workspace",
                description: "Consider creating a research workspace for technical documentation",
                priority: .low,
                action: "create_research_workspace"
            ))
        }
        
        workspaceRecommendations = recommendations
    }
    
    // MARK: - Workspace Organization
    
    func sortWorkspaces() {
        workspaces.sort { workspace1, workspace2 in
            // Pinned workspaces first
            if workspace1.isPinned != workspace2.isPinned {
                return workspace1.isPinned
            }
            
            // Then by last modified date
            return workspace1.lastModified > workspace2.lastModified
        }
    }
    
    func getWorkspacesByType() -> [WorkspaceType: [Project]] {
        return Dictionary(grouping: workspaces) { workspace in
            getWorkspaceType(for: workspace)
        }
    }
    
    func getPinnedWorkspaces() -> [Project] {
        return workspaces.filter { $0.isPinned }
    }
    
    func getRecentWorkspaces(limit: Int = 5) -> [Project] {
        return Array(workspaces.sorted { $0.lastModified > $1.lastModified }.prefix(limit))
    }
    
    // MARK: - Storage Management
    
    private func setupStorageMonitoring() {
        updateStorageInfo()
        
        // Update storage info periodically
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateStorageInfo()
            }
            .store(in: &cancellables)
    }
    
    private func updateStorageInfo() {
        totalStorageUsed = persistenceController.calculateStorageUsage()
        workspaceCount = workspaces.count
        lastBackupDate = persistenceController.getLastBackupDate()
    }
    
    func getStorageInfo() -> StorageInfo {
        return StorageInfo(
            totalStorageUsed: totalStorageUsed,
            workspaceCount: workspaceCount,
            averageWorkspaceSize: workspaceCount > 0 ? totalStorageUsed / Int64(workspaceCount) : 0,
            lastBackupDate: lastBackupDate,
            availableSpace: persistenceController.getAvailableSpace(),
            backupEnabled: persistenceController.isBackupEnabled()
        )
    }
    
    func exportWorkspace(_ workspace: Project) async -> Bool {
        return await persistenceController.exportWorkspace(workspace)
    }
    
    func optimizeStorage() async {
        await persistenceController.optimizeStorage()
        updateStorageInfo()
    }
    
    // MARK: - Persistence
    
    private func loadWorkspaces() {
        workspaces = persistenceController.loadWorkspaces()
        sortWorkspaces()
        updateStorageInfo()
    }
    
    private func saveWorkspace(_ workspace: Project) {
        persistenceController.saveWorkspace(workspace)
    }
    
    func saveAllWorkspaces() {
        for workspace in workspaces {
            saveWorkspace(workspace)
        }
    }
    
    // MARK: - Search and Filtering
    
    func searchWorkspaces(_ query: String) -> [Project] {
        guard !query.isEmpty else { return workspaces }
        
        let lowercaseQuery = query.lowercased()
        return workspaces.filter { workspace in
            workspace.title.lowercased().contains(lowercaseQuery) ||
            workspace.description.lowercased().contains(lowercaseQuery)
        }
    }
    
    func filterWorkspaces(by type: WorkspaceType) -> [Project] {
        return workspaces.filter { getWorkspaceType(for: $0) == type }
    }
    
    func getWorkspaceStatistics() -> WorkspaceStatistics {
        let typeDistribution = getWorkspacesByType().mapValues { $0.count }
        let totalWorkspaces = workspaces.count
        let pinnedCount = getPinnedWorkspaces().count
        let activeCount = workspaces.filter { workspace in
            Date().timeIntervalSince(workspace.lastModified) < 7 * 24 * 60 * 60
        }.count
        
        return WorkspaceStatistics(
            totalWorkspaces: totalWorkspaces,
            pinnedWorkspaces: pinnedCount,
            activeWorkspaces: activeCount,
            typeDistribution: typeDistribution,
            averageAge: calculateAverageWorkspaceAge(),
            storageUsed: totalStorageUsed
        )
    }
    
    private func calculateAverageWorkspaceAge() -> TimeInterval {
        guard !workspaces.isEmpty else { return 0 }
        
        let totalAge = workspaces.reduce(0.0) { sum, workspace in
            sum + Date().timeIntervalSince(workspace.createdAt)
        }
        
        return totalAge / Double(workspaces.count)
    }
}

// MARK: - Supporting Data Structures

struct WorkspaceIntelligence {
    let workspaceId: UUID
    let detectedType: WorkspaceManager.WorkspaceType
    let confidence: Double
    let contentDepth: Double
    let usagePattern: UsagePattern
    let recommendedActions: [String]
    let lastAnalyzed: Date
}

enum UsagePattern: String, CaseIterable {
    case veryActive = "very_active"
    case active = "active"
    case moderate = "moderate"
    case inactive = "inactive"
    
    var displayName: String {
        switch self {
        case .veryActive: return "Very Active"
        case .active: return "Active"
        case .moderate: return "Moderate"
        case .inactive: return "Inactive"
        }
    }
    
    var color: Color {
        switch self {
        case .veryActive: return .green
        case .active: return .blue
        case .moderate: return .orange
        case .inactive: return .gray
        }
    }
}

struct WorkspaceRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: Priority
    let action: String
    
    enum RecommendationType {
        case organization
        case creation
        case optimization
        case feature
    }
    
    enum Priority {
        case low
        case medium
        case high
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

struct StorageInfo {
    let totalStorageUsed: Int64
    let workspaceCount: Int
    let averageWorkspaceSize: Int64
    let lastBackupDate: Date?
    let availableSpace: Int64
    let backupEnabled: Bool
    
    var formattedStorageUsed: String {
        return ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }
    
    var formattedAverageSize: String {
        return ByteCountFormatter.string(fromByteCount: averageWorkspaceSize, countStyle: .file)
    }
    
    var formattedAvailableSpace: String {
        return ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }
}

struct WorkspaceStatistics {
    let totalWorkspaces: Int
    let pinnedWorkspaces: Int
    let activeWorkspaces: Int
    let typeDistribution: [WorkspaceManager.WorkspaceType: Int]
    let averageAge: TimeInterval
    let storageUsed: Int64
    
    var formattedAverageAge: String {
        let days = Int(averageAge / (24 * 60 * 60))
        if days < 1 {
            return "Less than a day"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

// MARK: - Workspace Persistence Controller

class WorkspacePersistenceController {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var workspacesDirectory: URL {
        documentsPath.appendingPathComponent("Arcana/Workspaces", isDirectory: true)
    }
    
    init() {
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: workspacesDirectory, withIntermediateDirectories: true)
    }
    
    func loadWorkspaces() -> [Project] {
        guard let workspaceFiles = try? FileManager.default.contentsOfDirectory(at: workspacesDirectory, includingPropertiesForKeys: nil) else {
            return Project.sampleProjects
        }
        
        let loadedWorkspaces = workspaceFiles.compactMap { url -> Project? in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url),
                  let workspace = try? JSONDecoder().decode(Project.self, from: data) else {
                return nil
            }
            return workspace
        }
        
        return loadedWorkspaces.isEmpty ? Project.sampleProjects : loadedWorkspaces
    }
    
    func saveWorkspace(_ workspace: Project) {
        let fileURL = workspacesDirectory.appendingPathComponent("\(workspace.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(workspace)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save workspace: \(error)")
        }
    }
    
    func deleteWorkspace(_ workspace: Project) {
        let fileURL = workspacesDirectory.appendingPathComponent("\(workspace.id.uuidString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func calculateStorageUsage() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: workspacesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return files.reduce(0) { total, url in
            guard let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resources.fileSize else {
                return total
            }
            return total + Int64(fileSize)
        }
    }
    
    func getLastBackupDate() -> Date? {
        // Simulate backup date - in real implementation would check actual backup system
        return Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
    }
    
    func getAvailableSpace() -> Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentsPath.path),
              let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber else {
            return 0
        }
        return freeSpace.int64Value
    }
    
    func isBackupEnabled() -> Bool {
        // Simulate backup status - in real implementation would check backup configuration
        return true
    }
    
    func exportWorkspace(_ workspace: Project) async -> Bool {
        guard let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let exportURL = downloadsURL.appendingPathComponent("\(workspace.title).arcana")
        
        do {
            let exportData = try JSONEncoder().encode(workspace)
            try exportData.write(to: exportURL)
            return true
        } catch {
            print("❌ Failed to export workspace: \(error)")
            return false
        }
    }
    
    func optimizeStorage() async {
        // Simulate storage optimization
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // In real implementation:
        // - Compress old workspace data
        // - Remove duplicate files
        // - Clean up temporary files
        // - Optimize file formats
        
        print("✅ Storage optimization completed")
    }
}

// MARK: - Extensions for Legacy Compatibility

extension WorkspaceManager.WorkspaceType: Equatable, Hashable {
    public static func == (lhs: WorkspaceManager.WorkspaceType, rhs: WorkspaceManager.WorkspaceType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
