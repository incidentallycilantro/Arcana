//
// PrivacyTypes.swift
// Arcana - Privacy system data structures
// Created by Spectral Labs
//
// FOLDER: Arcana/Models/
//

import Foundation

// MARK: - Core Privacy Types

enum PrivacyLevel: String, Codable, CaseIterable {
    case minimum = "minimum"
    case moderate = "moderate"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .minimum:
            return "Basic privacy with local processing"
        case .moderate:
            return "Enhanced privacy with validation"
        case .high:
            return "Strong privacy with encryption"
        case .maximum:
            return "Zero-knowledge privacy with mathematical guarantees"
        }
    }
    
    var icon: String {
        switch self {
        case .minimum: return "lock"
        case .moderate: return "lock.fill"
        case .high: return "lock.shield"
        case .maximum: return "lock.shield.fill"
        }
    }
    
    var color: String {
        switch self {
        case .minimum: return "gray"
        case .moderate: return "blue"
        case .high: return "orange"
        case .maximum: return "red"
        }
    }
}

enum EncryptionStatus: String, Codable {
    case inactive = "inactive"
    case active = "active"
    case emergencyWiped = "emergency_wiped"
    
    var displayName: String {
        switch self {
        case .inactive: return "Inactive"
        case .active: return "Active"
        case .emergencyWiped: return "Emergency Wiped"
        }
    }
    
    var isSecure: Bool {
        return self == .active
    }
}

enum DataProcessingMode: String, Codable {
    case localOnly = "local_only"
    case localWithValidation = "local_with_validation"
    case encryptedLocal = "encrypted_local"
    case zeroKnowledge = "zero_knowledge"
    
    var displayName: String {
        switch self {
        case .localOnly: return "Local Only"
        case .localWithValidation: return "Local with Validation"
        case .encryptedLocal: return "Encrypted Local"
        case .zeroKnowledge: return "Zero Knowledge"
        }
    }
    
    var description: String {
        switch self {
        case .localOnly:
            return "All processing happens locally on your device"
        case .localWithValidation:
            return "Local processing with privacy validation"
        case .encryptedLocal:
            return "Local processing with full encryption"
        case .zeroKnowledge:
            return "Mathematical zero-knowledge guarantees"
        }
    }
    
    var securityLevel: Int {
        switch self {
        case .localOnly: return 1
        case .localWithValidation: return 2
        case .encryptedLocal: return 3
        case .zeroKnowledge: return 4
        }
    }
}

// MARK: - Privacy Metrics

struct PrivacyMetrics: Codable {
    var totalMessagesProcessed: Int = 0
    var maximumPrivacyMessages: Int = 0
    var highPrivacyMessages: Int = 0
    var moderatePrivacyMessages: Int = 0
    var minimumPrivacyMessages: Int = 0
    var averageProcessingTime: TimeInterval = 0.0
    var lastUpdated: Date = Date()
    
    var privacyDistribution: [PrivacyLevel: Double] {
        let total = Double(totalMessagesProcessed)
        guard total > 0 else { return [:] }
        
        return [
            .maximum: Double(maximumPrivacyMessages) / total,
            .high: Double(highPrivacyMessages) / total,
            .moderate: Double(moderatePrivacyMessages) / total,
            .minimum: Double(minimumPrivacyMessages) / total
        ]
    }
    
    var averagePrivacyLevel: PrivacyLevel {
        let distribution = privacyDistribution
        
        if distribution[.maximum, default: 0] > 0.5 {
            return .maximum
        } else if distribution[.high, default: 0] > 0.3 {
            return .high
        } else if distribution[.moderate, default: 0] > 0.2 {
            return .moderate
        } else {
            return .minimum
        }
    }
}

// MARK: - Privacy Processing Types

struct PrivacyProcessedMessage: Codable {
    let originalId: UUID
    let encryptedContent: Data
    let sanitizedContent: String
    let privacyLevel: PrivacyLevel
    let encryptionKeyId: UUID
    let privacyValidation: PrivacyValidation
    let processingTime: TimeInterval
    let timestamp: Date
    
    init(originalId: UUID, encryptedContent: Data, sanitizedContent: String, privacyLevel: PrivacyLevel, encryptionKeyId: UUID, privacyValidation: PrivacyValidation, processingTime: TimeInterval) {
        self.originalId = originalId
        self.encryptedContent = encryptedContent
        self.sanitizedContent = sanitizedContent
        self.privacyLevel = privacyLevel
        self.encryptionKeyId = encryptionKeyId
        self.privacyValidation = privacyValidation
        self.processingTime = processingTime
        self.timestamp = Date()
    }
    
    var isHighSecurity: Bool {
        return privacyLevel == .high || privacyLevel == .maximum
    }
    
    var processingGrade: ProcessingGrade {
        switch processingTime {
        case 0..<0.1: return .excellent
        case 0.1..<0.5: return .good
        case 0.5..<1.0: return .fair
        default: return .poor
        }
    }
}

enum ProcessingGrade: String, Codable {
    case excellent, good, fair, poor
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
}

struct PrivacyValidation: Codable {
    let sensitivityLevel: Double
    let piiLevel: PIILevel
    let requiresEncryption: Bool
    let validationTimestamp: Date
    let detectedRisks: [PrivacyRisk]
    
    init(sensitivityLevel: Double, piiLevel: PIILevel, requiresEncryption: Bool) {
        self.sensitivityLevel = sensitivityLevel
        self.piiLevel = piiLevel
        self.requiresEncryption = requiresEncryption
        self.validationTimestamp = Date()
        self.detectedRisks = []
    }
    
    var overallRiskLevel: RiskLevel {
        if detectedRisks.contains(where: { $0.severity == .critical }) {
            return .critical
        } else if detectedRisks.contains(where: { $0.severity == .high }) {
            return .high
        } else if detectedRisks.contains(where: { $0.severity == .medium }) {
            return .medium
        } else {
            return .low
        }
    }
}

enum PIILevel: String, Codable, CaseIterable {
    case none = "none"
    case minimal = "minimal"
    case moderate = "moderate"
    case aggressive = "aggressive"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .none:
            return "No personally identifiable information detected"
        case .minimal:
            return "Minor PII elements detected"
        case .moderate:
            return "Significant PII present"
        case .aggressive:
            return "High-risk PII requiring immediate protection"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "checkmark.shield"
        case .minimal: return "exclamationmark.shield"
        case .moderate: return "exclamationmark.triangle"
        case .aggressive: return "xmark.shield"
        }
    }
    
    var sanitizationRequired: Bool {
        return self != .none
    }
}

struct PrivacyRisk: Codable, Identifiable {
    let id = UUID()
    let type: RiskType
    let severity: RiskSeverity
    let description: String
    let mitigation: String
    let detectedAt: Date
    
    init(type: RiskType, severity: RiskSeverity, description: String, mitigation: String) {
        self.type = type
        self.severity = severity
        self.description = description
        self.mitigation = mitigation
        self.detectedAt = Date()
    }
}

enum RiskType: String, Codable {
    case piiExposure = "pii_exposure"
    case dataLeakage = "data_leakage"
    case insufficientEncryption = "insufficient_encryption"
    case memoryResidue = "memory_residue"
    case crossContamination = "cross_contamination"
    
    var displayName: String {
        switch self {
        case .piiExposure: return "PII Exposure"
        case .dataLeakage: return "Data Leakage"
        case .insufficientEncryption: return "Insufficient Encryption"
        case .memoryResidue: return "Memory Residue"
        case .crossContamination: return "Cross Contamination"
        }
    }
}

enum RiskSeverity: String, Codable {
    case low, medium, high, critical
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum RiskLevel: String, Codable {
    case low, medium, high, critical
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Audit & Compliance Types

struct PrivacyAuditEntry: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let messageId: UUID
    let privacyLevel: PrivacyLevel
    let operations: [String]
    let outcome: PrivacyAuditOutcome
    let processingMetrics: AuditMetrics?
    
    init(timestamp: Date, messageId: UUID, privacyLevel: PrivacyLevel, operations: [String], outcome: PrivacyAuditOutcome) {
        self.timestamp = timestamp
        self.messageId = messageId
        self.privacyLevel = privacyLevel
        self.operations = operations
        self.outcome = outcome
        self.processingMetrics = nil
    }
    
    var isSuccessful: Bool {
        return outcome == .success
    }
}

enum PrivacyAuditOutcome: String, Codable {
    case success = "success"
    case failure = "failure"
    case partial = "partial"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .success: return "green"
        case .failure: return "red"
        case .partial: return "orange"
        }
    }
}

struct AuditMetrics: Codable {
    let operationCount: Int
    let totalProcessingTime: TimeInterval
    let memoryUsage: Int
    let encryptionStrength: String
    let validationsPassed: Int
    let validationsFailed: Int
}

struct DataProcessingEntry: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let operation: String
    let dataSize: Int
    let processingTime: TimeInterval
    let privacyLevel: PrivacyLevel
    let success: Bool
    
    var efficiency: ProcessingEfficiency {
        let bytesPerSecond = Double(dataSize) / processingTime
        
        switch bytesPerSecond {
        case 10000...: return .excellent
        case 5000..<10000: return .good
        case 1000..<5000: return .fair
        default: return .poor
        }
    }
}

enum ProcessingEfficiency: String, Codable {
    case excellent, good, fair, poor
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Data Governance Types

struct DataDeletionResult: Codable {
    let requestedDeletions: Int
    let successfulDeletions: Int
    let failedDeletions: Int
    let deletionDetails: [UUID: Bool]
    let completedAt: Date
    
    init(requestedDeletions: Int, successfulDeletions: Int, failedDeletions: Int, deletionDetails: [UUID: Bool]) {
        self.requestedDeletions = requestedDeletions
        self.successfulDeletions = successfulDeletions
        self.failedDeletions = failedDeletions
        self.deletionDetails = deletionDetails
        self.completedAt = Date()
    }
    
    var successRate: Double {
        guard requestedDeletions > 0 else { return 0.0 }
        return Double(successfulDeletions) / Double(requestedDeletions)
    }
    
    var isFullySuccessful: Bool {
        return failedDeletions == 0
    }
}

struct PrivacyReport: Codable {
    let currentPrivacyLevel: PrivacyLevel
    let encryptionStatus: EncryptionStatus
    let dataProcessingMode: DataProcessingMode
    let metrics: PrivacyMetrics
    let recentAudits: [PrivacyAuditEntry]
    let recentProcessing: [DataProcessingEntry]
    let generatedAt: Date
    let complianceScore: Double
    
    init(currentPrivacyLevel: PrivacyLevel, encryptionStatus: EncryptionStatus, dataProcessingMode: DataProcessingMode, metrics: PrivacyMetrics, recentAudits: [PrivacyAuditEntry], recentProcessing: [DataProcessingEntry], generatedAt: Date) {
        self.currentPrivacyLevel = currentPrivacyLevel
        self.encryptionStatus = encryptionStatus
        self.dataProcessingMode = dataProcessingMode
        self.metrics = metrics
        self.recentAudits = recentAudits
        self.recentProcessing = recentProcessing
        self.generatedAt = generatedAt
        
        // Calculate compliance score
        let auditSuccessRate = recentAudits.isEmpty ? 1.0 :
            Double(recentAudits.filter { $0.isSuccessful }.count) / Double(recentAudits.count)
        let processingSuccessRate = recentProcessing.isEmpty ? 1.0 :
            Double(recentProcessing.filter { $0.success }.count) / Double(recentProcessing.count)
        let encryptionScore = encryptionStatus.isSecure ? 1.0 : 0.0
        
        self.complianceScore = (auditSuccessRate + processingSuccessRate + encryptionScore) / 3.0
    }
    
    var complianceGrade: ComplianceGrade {
        switch complianceScore {
        case 0.95...1.0: return .excellent
        case 0.85..<0.95: return .good
        case 0.70..<0.85: return .fair
        default: return .poor
        }
    }
}

enum ComplianceGrade: String, Codable {
    case excellent, good, fair, poor
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Exceeds all privacy standards"
        case .good: return "Meets privacy requirements"
        case .fair: return "Adequate privacy protection"
        case .poor: return "Privacy improvements needed"
        }
    }
}

struct PrivacyComplianceResult: Codable {
    let overallCompliance: Bool
    let encryptionCompliance: Bool
    let memoryManagementCompliance: Bool
    let dataGovernanceCompliance: Bool
    let recommendedActions: [String]
    let lastValidated: Date
    let compliancePercentage: Double
    
    init(overallCompliance: Bool, encryptionCompliance: Bool, memoryManagementCompliance: Bool, dataGovernanceCompliance: Bool, recommendedActions: [String], lastValidated: Date) {
        self.overallCompliance = overallCompliance
        self.encryptionCompliance = encryptionCompliance
        self.memoryManagementCompliance = memoryManagementCompliance
        self.dataGovernanceCompliance = dataGovernanceCompliance
        self.recommendedActions = recommendedActions
        self.lastValidated = lastValidated
        
        // Calculate compliance percentage
        let scores = [encryptionCompliance, memoryManagementCompliance, dataGovernanceCompliance]
        let passedCount = scores.filter { $0 }.count
        self.compliancePercentage = Double(passedCount) / Double(scores.count)
    }
    
    var status: ComplianceStatus {
        if overallCompliance {
            return .compliant
        } else if compliancePercentage >= 0.8 {
            return .mostlyCompliant
        } else if compliancePercentage >= 0.5 {
            return .partiallyCompliant
        } else {
            return .nonCompliant
        }
    }
}

enum ComplianceStatus: String, Codable {
    case compliant = "compliant"
    case mostlyCompliant = "mostly_compliant"
    case partiallyCompliant = "partially_compliant"
    case nonCompliant = "non_compliant"
    
    var displayName: String {
        switch self {
        case .compliant: return "Fully Compliant"
        case .mostlyCompliant: return "Mostly Compliant"
        case .partiallyCompliant: return "Partially Compliant"
        case .nonCompliant: return "Non-Compliant"
        }
    }
    
    var color: String {
        switch self {
        case .compliant: return "green"
        case .mostlyCompliant: return "blue"
        case .partiallyCompliant: return "orange"
        case .nonCompliant: return "red"
        }
    }
}

// MARK: - Emergency Response Types

struct EmergencyWipeResult: Codable {
    let timestamp: Date
    let componentsWiped: Int
    let successfulWipes: Int
    let failedWipes: Int
    let wipeDetails: [String: Bool]
    let totalWipeTime: TimeInterval
    
    init(timestamp: Date, componentsWiped: Int, successfulWipes: Int, failedWipes: Int, wipeDetails: [String: Bool]) {
        self.timestamp = timestamp
        self.componentsWiped = componentsWiped
        self.successfulWipes = successfulWipes
        self.failedWipes = failedWipes
        self.wipeDetails = wipeDetails
        self.totalWipeTime = 0.0
    }
    
    var isFullySuccessful: Bool {
        return failedWipes == 0
    }
    
    var successRate: Double {
        guard componentsWiped > 0 else { return 0.0 }
        return Double(successfulWipes) / Double(componentsWiped)
    }
    
    var status: WipeStatus {
        if isFullySuccessful {
            return .complete
        } else if successRate >= 0.8 {
            return .mostlySuccessful
        } else if successRate >= 0.5 {
            return .partial
        } else {
            return .failed
        }
    }
}

enum WipeStatus: String, Codable {
    case complete = "complete"
    case mostlySuccessful = "mostly_successful"
    case partial = "partial"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .complete: return "Complete"
        case .mostlySuccessful: return "Mostly Successful"
        case .partial: return "Partial"
        case .failed: return "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .complete: return "green"
        case .mostlySuccessful: return "blue"
        case .partial: return "orange"
        case .failed: return "red"
        }
    }
}
