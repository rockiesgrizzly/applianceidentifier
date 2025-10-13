//
//  ApplianceRepository.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// Repository protocol for appliance persistence operations.
/// Returns Sendable DTOs for safe concurrent access across actor boundaries.
protocol ApplianceRepository {
    /// All saved appliances, sorted by most recent first.
    var appliances: [ApplianceDTO] { get async throws }

    /// Persists an appliance to storage and returns the saved DTO.
    /// - Parameter data: The appliance data to save
    /// - Returns: The saved appliance as a DTO with persistent identifier
    func saveAppliance(_ data: ApplianceCreationData) async throws -> ApplianceDTO

    /// Removes an appliance from storage.
    /// - Parameter id: The persistent identifier of the appliance to delete
    func deleteAppliance(_ id: PersistentIdentifier) async throws
}

/// SwiftData implementation of ApplianceRepository for local persistence.
/// Uses @ModelActor for proper thread-safety when accessing SwiftData models.
@ModelActor
actor SwiftDataApplianceRepository: ApplianceRepository {
    /// All saved appliances, sorted by most recent first.
    var appliances: [ApplianceDTO] {
        get async throws {
            let descriptor = FetchDescriptor<Appliance>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let models = try modelContext.fetch(descriptor)
            return models.map { ApplianceDTO(from: $0) }
        }
    }

    /// Persists an appliance to SwiftData storage.
    func saveAppliance(_ data: ApplianceCreationData) async throws -> ApplianceDTO {
        let appliance = Appliance(
            name: data.name,
            category: data.category,
            estimatedWattage: data.estimatedWattage,
            confidence: data.confidence,
            timestamp: data.timestamp,
            imageData: data.imageData
        )
        modelContext.insert(appliance)
        try modelContext.save()
        return ApplianceDTO(from: appliance)
    }

    /// Removes an appliance from SwiftData storage.
    func deleteAppliance(_ id: PersistentIdentifier) async throws {
        guard let appliance = modelContext.model(for: id) as? Appliance else {
            throw NSError(domain: "ApplianceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Appliance not found"
            ])
        }
        modelContext.delete(appliance)
        try modelContext.save()
    }
}
