//
// WorkspaceManager.swift
// Arcana - Unified Workspace Management System
// Created by Spectral Labs
//
// FOLDER: Arcana/Core/
// DEPENDENCIES: UnifiedTypes.swift, Project.swift

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
        persistenceController.deleteWorkspace(workspace)
        
        if selectedWorkspace?.id == workspace.id {
            selectedWorkspace = workspaces.first
        }
        
        updateStorageInfo()
    }
    
    func pinWorkspace(_ workspace: Project) {
        if let index = workspaces.firstIndex(of: workspace) {
            var updatedWorkspace = workspace
            // Note: In future, add isPinned property to Project model
            workspaces[index] = updatedWorkspace
            saveWorkspace(updatedWorkspace)
            sortWorkspaces()
        }
    }
    
    // MARK: - Workspace Intelligence
    
    func getWorkspaceType(for workspace: Project) -> WorkspaceType {
        // In a complete implementation, this would query the intelligence engine
        // For now, return a basic detection based on workspace content
        let title = workspace.title.lowercased()
        let description = workspace.description.lowercased()
        let combined = "\(title) \(description)"
        
        if combined.contains("code") || combined.contains("development") || combined.contains("programming") {
            return .code
        } else if combined.contains("research") || combined.contains("analysis") || combined.contains("study") {
            return .research
        } else if combined.contains("creative") || combined.contains("design") || combined.contains("art") {
            return .creative
        } else {
            return .general
        }
    }
    
    // ✅ FIXED: Renamed to avoid conflict with QuantumMemoryManager.UsagePattern
    private func analyzeUsagePattern(_ workspace: Project) -> WorkspaceUsagePattern {
        let daysSinceLastModified = Date().timeIntervalSince(workspace.lastModified) / (24 * 60 * 60)
        
        switch daysSinceLastModified {
        case 0..<1:
            return .frequent
        case 1..<7:
            return .occasional
        case 7..<30:
            return .rare
        default:
            return .unknown
        }
    }
    
    func analyzeWorkspaceIntelligence(_ workspace: Project) async -> WorkspaceIntelligence {
        let detectedType = getWorkspaceType(for: workspace)
        let usagePattern = analyzeUsagePattern(workspace)
        
        return WorkspaceIntelligence(
            workspaceId: workspace.id,
            detectedType: detectedType,
            confidence: 0.8,
            contentDepth: calculateContentDepth(workspace),
            usagePattern: usagePattern,
            recommendedActions: generateRecommendations(for: workspace)
        )
    }
    
    private func calculateContentDepth(_ workspace: Project) -> Double {
        // Placeholder calculation - in real implementation would analyze actual content
        let titleComplexity = Double(workspace.title.count) / 50.0
        let descriptionComplexity = Double(workspace.description.count) / 200.0
        return min((titleComplexity + descriptionComplexity) / 2.0, 1.0)
    }
    
    private func generateRecommendations(for workspace: Project) -> [String] {
        var recommendations: [String] = []
        
        let daysSinceLastModified = Date().timeIntervalSince(workspace.lastModified) / (24 * 60 * 60)
        
        if daysSinceLastModified > 7 {
            recommendations.append("Consider archiving this workspace if no longer needed")
        }
        
        if workspace.description.isEmpty {
            recommendations.append("Add a description to better organize this workspace")
        }
        
        return recommendations
    }
    
    private func updateWorkspaceRecommendations() async {
        var recommendations: [WorkspaceRecommendation] = []
        
        // Generate organizational recommendations
        if workspaces.count > 10 {
            recommendations.append(WorkspaceRecommendation(
                type: .organization,
                title: "Consider Workspace Organization",
                description: "You have \(workspaces.count) workspaces. Consider archiving unused ones.",
                priority: .medium,
                action: "Organize Workspaces"
            ))
        }
        
        // Generate creation recommendations
        let codeWorkspaces = filterWorkspaces(by: .code).count
        let researchWorkspaces = filterWorkspaces(by: .research).count
        
        if codeWorkspaces > researchWorkspaces * 2 {
            recommendations.append(WorkspaceRecommendation(
                type: .creation,
                title: "Balance Your Workspaces",
                description: "Consider creating research workspaces to balance your workflow.",
                priority: .low,
                action: "Create Research Workspace"
            ))
        }
        
        await MainActor.run {
            self.workspaceRecommendations = recommendations
        }
    }
    
    // MARK: - Workspace Organization
    
    func sortWorkspaces() {
        workspaces.sort { workspace1, workspace2 in
            // Pinned workspaces first (when isPinned property is added)
            // Then by last modified date
            workspace1.lastModified > workspace2.lastModified
        }
    }
    
    func getWorkspacesByType() -> [WorkspaceType: [Project]] {
        var groupedWorkspaces: [WorkspaceType: [Project]] = [:]
        
        for workspace in workspaces {
            let type = getWorkspaceType(for: workspace)
            groupedWorkspaces[type, default: []].append(workspace)
        }
        
        return groupedWorkspaces
    }
    
    func getPinnedWorkspaces() -> [Project] {
        // Return empty for now - will implement when isPinned property is added to Project
        return []
    }
    
    func getRecentWorkspaces(limit: Int = 5) -> [Project] {
        return Array(workspaces.prefix(limit))
    }
    
    func getActiveWorkspaces() -> [Project] {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return workspaces.filter { $0.lastModified > oneWeekAgo }
    }
    
    // MARK: - Storage Management
    
    private func setupStorageMonitoring() {
        updateStorageInfo()
        
        // Monitor storage changes every 60 seconds
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
    
    func saveWorkspaceFromExternal(_ workspace: Project) {
        persistenceController.saveWorkspace(workspace)
        updateStorageInfo()
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
    let usagePattern: WorkspaceUsagePattern // ✅ FIXED: Using renamed type
    let recommendedActions: [String]
    let lastAnalyzed: Date
    
    init(workspaceId: UUID, detectedType: WorkspaceManager.WorkspaceType, confidence: Double, contentDepth: Double, usagePattern: WorkspaceUsagePattern, recommendedActions: [String]) {
        self.workspaceId = workspaceId
        self.detectedType = detectedType
        self.confidence = confidence
        self.contentDepth = contentDepth
        self.usagePattern = usagePattern
        self.recommendedActions = recommendedActions
        self.lastAnalyzed = Date()
    }
}

// ✅ FIXED: Renamed enum to avoid conflict with QuantumMemoryManager
enum WorkspaceUsagePattern: String, CaseIterable {
    case frequent = "frequent"
    case occasional = "occasional"
    case rare = "rare"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .frequent: return "Very Active"
        case .occasional: return "Active"
        case .rare: return "Moderate"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .frequent: return .green
        case .occasional: return .blue
        case .rare: return .orange
        case .unknown: return .gray
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
              let freeSpace = systemAttributes[.systemFreeSize] as? Int64 else {
            return 0
        }
        return freeSpace
    }
    
    func isBackupEnabled() -> Bool {
        // Placeholder - in real implementation would check backup settings
        return true
    }
    
    func exportWorkspace(_ workspace: Project) async -> Bool {
        // Placeholder export functionality
        return true
    }
    
    func optimizeStorage() async {
        // Placeholder storage optimization
    }
}
