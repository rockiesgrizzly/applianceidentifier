//
//  ApplianceListViewModel.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// ViewModel for the appliance list screen.
/// Manages loading, displaying, and deleting saved appliances.
@MainActor
@Observable
final class ApplianceListViewModel {
    private let getAppliancesUseCase: GetAppliancesUseCaseProtocol
    private let deleteApplianceUseCase: DeleteApplianceUseCaseProtocol

    /// List of all saved appliances
    var appliances: [ApplianceDTO] = []

    /// Loading state indicator
    var isLoading = false

    /// Error message to display to user, if any
    var errorMessage: String?

    init(
        getAppliancesUseCase: GetAppliancesUseCaseProtocol,
        deleteApplianceUseCase: DeleteApplianceUseCaseProtocol
    ) {
        self.getAppliancesUseCase = getAppliancesUseCase
        self.deleteApplianceUseCase = deleteApplianceUseCase
    }

    /// Loads all saved appliances from storage.
    /// Updates appliances array and sets loading/error states appropriately.
    func loadAppliances() async {
        isLoading = true
        errorMessage = nil

        do {
            appliances = try await getAppliancesUseCase.appliances
        } catch {
            errorMessage = "Failed to load appliances: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Deletes an appliance and refreshes the list.
    /// - Parameter appliance: The appliance DTO to delete
    func deleteAppliance(_ appliance: ApplianceDTO) async {
        do {
            try await deleteApplianceUseCase.deleteAppliance(appliance.persistentID)
            await loadAppliances()
        } catch {
            errorMessage = "Failed to delete appliance: \(error.localizedDescription)"
        }
    }
}
