//
//  DataFactory.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// Factory for creating Data layer dependencies (Repositories).
/// Provides repository implementations for persistence, ML inference, and energy data.
final class DataFactory {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Repositories

    /// Creates a repository for appliance persistence using SwiftData.
    var applianceRepository: ApplianceRepository {
        SwiftDataApplianceRepository(modelContainer: modelContainer)
    }

    /// Creates a repository for ML model inference using Vision/CoreML.
    var mlModelRepository: MLModelRepository {
        CoreMLModelRepository()
    }

    /// Creates a repository for appliance energy consumption lookup.
    var energyDataRepository: EnergyDataRepository {
        StaticEnergyDataRepository()
    }
}
