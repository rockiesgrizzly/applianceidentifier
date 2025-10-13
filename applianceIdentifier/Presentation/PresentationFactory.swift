//
//  PresentationFactory.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// Factory for creating Presentation layer dependencies (ViewModels).
/// Constructs ViewModels with their required use case dependencies from the Domain layer.
@MainActor
final class PresentationFactory {
    private let domainFactory: DomainFactory

    init(domainFactory: DomainFactory) {
        self.domainFactory = domainFactory
    }

    // MARK: - ViewModels

    /// Creates a ViewModel for the appliance list screen.
    var applianceListViewModel: ApplianceListViewModel {
        ApplianceListViewModel(
            getAppliancesUseCase: domainFactory.getAppliancesUseCase,
            deleteApplianceUseCase: domainFactory.deleteApplianceUseCase
        )
    }

    /// Creates a ViewModel for the camera/photo picker screen.
    var cameraViewModel: CameraViewModel {
        CameraViewModel(
            classifyApplianceUseCase: domainFactory.classifyApplianceUseCase,
            saveApplianceUseCase: domainFactory.saveApplianceUseCase
        )
    }
}
