//
//  DeleteApplianceUseCase.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// Use case protocol for removing appliances from storage.
protocol DeleteApplianceUseCaseProtocol {
    /// Deletes an appliance from persistent storage.
    /// - Parameter id: The persistent identifier of the appliance to delete
    /// - Throws: Repository errors if delete operation fails
    func deleteAppliance(_ id: PersistentIdentifier) async throws
}

/// Removes appliances from the repository.
final class DeleteApplianceUseCase: DeleteApplianceUseCaseProtocol {
    private let applianceRepository: ApplianceRepository

    init(applianceRepository: ApplianceRepository) {
        self.applianceRepository = applianceRepository
    }

    /// Deletes an appliance from persistent storage.
    func deleteAppliance(_ id: PersistentIdentifier) async throws {
        try await applianceRepository.deleteAppliance(id)
    }
}
