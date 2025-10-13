//
//  AppDependencyContainer.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// App-level dependency injection container following Clean Architecture.
/// Serves as the composition root that wires up all dependencies across layers.
/// Dependency flow: App -> Presentation -> Domain -> Data (outer to inner).
@MainActor
@Observable
final class AppDependencyContainer {

    // MARK: - Layer Factories

    private let dataFactory: DataFactory
    private let domainFactory: DomainFactory
    private let presentationFactory: PresentationFactory

    /// Initializes the dependency container with a SwiftData model container.
    /// Creates factories from outer to inner layers, maintaining Clean Architecture principles.
    /// - Parameter modelContainer: The SwiftData ModelContainer for persistence
    init(modelContainer: ModelContainer) {
        self.dataFactory = DataFactory(modelContainer: modelContainer)
        self.domainFactory = DomainFactory(dataFactory: dataFactory)
        self.presentationFactory = PresentationFactory(domainFactory: domainFactory)
    }

    // MARK: - ViewModels

    /// Provides a ViewModel for the appliance list screen.
    var applianceListViewModel: ApplianceListViewModel {
        presentationFactory.applianceListViewModel
    }

    /// Provides a ViewModel for the camera/photo picker screen.
    var cameraViewModel: CameraViewModel {
        presentationFactory.cameraViewModel
    }
}
