//
//  DomainFactory.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// Factory for creating Domain layer dependencies (Use Cases).
/// Constructs use cases with their required repository dependencies from the Data layer.
final class DomainFactory {
    private let dataFactory: DataFactory

    init(dataFactory: DataFactory) {
        self.dataFactory = dataFactory
    }

    // MARK: - Use Cases

    /// Creates a use case for classifying appliances from images.
    var classifyApplianceUseCase: ClassifyApplianceUseCaseProtocol {
        ClassifyApplianceUseCase(
            mlModelRepository: dataFactory.mlModelRepository,
            energyDataRepository: dataFactory.energyDataRepository
        )
    }

    /// Creates a use case for retrieving all saved appliances.
    var getAppliancesUseCase: GetAppliancesUseCaseProtocol {
        GetAppliancesUseCase(applianceRepository: dataFactory.applianceRepository)
    }

    /// Creates a use case for persisting appliances.
    var saveApplianceUseCase: SaveApplianceUseCaseProtocol {
        SaveApplianceUseCase(applianceRepository: dataFactory.applianceRepository)
    }

    /// Creates a use case for removing appliances.
    var deleteApplianceUseCase: DeleteApplianceUseCaseProtocol {
        DeleteApplianceUseCase(applianceRepository: dataFactory.applianceRepository)
    }
}
