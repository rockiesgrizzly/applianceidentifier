//
//  SaveApplianceUseCase.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// Use case protocol for persisting appliances.
protocol SaveApplianceUseCaseProtocol {
    /// Saves an appliance to persistent storage and returns the saved DTO.
    /// - Parameter data: The appliance data to save
    /// - Returns: The saved appliance as a DTO with persistent identifier
    /// - Throws: Repository errors if save operation fails
    func saveAppliance(_ data: ApplianceCreationData) async throws -> ApplianceDTO
}

/// Persists identified appliances to the repository for historical tracking.
final class SaveApplianceUseCase: SaveApplianceUseCaseProtocol {
    private let applianceRepository: ApplianceRepository

    init(applianceRepository: ApplianceRepository) {
        self.applianceRepository = applianceRepository
    }

    /// Saves an appliance to persistent storage and returns the saved DTO.
    func saveAppliance(_ data: ApplianceCreationData) async throws -> ApplianceDTO {
        try await applianceRepository.saveAppliance(data)
    }
}
