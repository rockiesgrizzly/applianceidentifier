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
    private let customMLModelRepository: MLModelRepository?

    init(modelContainer: ModelContainer, mlModelRepository: MLModelRepository? = nil) {
        self.modelContainer = modelContainer
        self.customMLModelRepository = mlModelRepository
    }

    // MARK: - Repositories

    /// Creates a repository for appliance persistence using SwiftData.
    var applianceRepository: ApplianceRepository {
        SwiftDataApplianceRepository(modelContainer: modelContainer)
    }

    /// Creates a repository for ML model inference using Vision/CoreML.
    /// In tests, a custom repository can be injected via the initializer.
    var mlModelRepository: MLModelRepository {
        customMLModelRepository ?? CoreMLModelRepository()
    }

    /// Creates a repository for appliance energy consumption lookup.
    var energyDataRepository: EnergyDataRepository {
        StaticEnergyDataRepository()
    }
}
