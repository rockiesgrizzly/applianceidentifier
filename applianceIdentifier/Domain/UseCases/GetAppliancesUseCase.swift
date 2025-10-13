//
//  GetAppliancesUseCase.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// Use case protocol for retrieving all saved appliances.
protocol GetAppliancesUseCaseProtocol {
    /// All saved appliances, sorted by most recent first.
    var appliances: [ApplianceDTO] { get async throws }
}

/// Retrieves the complete list of identified appliances from persistent storage.
final class GetAppliancesUseCase: GetAppliancesUseCaseProtocol {
    private let applianceRepository: ApplianceRepository

    init(applianceRepository: ApplianceRepository) {
        self.applianceRepository = applianceRepository
    }

    /// All saved appliances, sorted by most recent first.
    var appliances: [ApplianceDTO] {
        get async throws {
            try await applianceRepository.appliances
        }
    }
}
