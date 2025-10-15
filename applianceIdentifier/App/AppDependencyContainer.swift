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
    /// - Parameters:
    ///   - modelContainer: The SwiftData ModelContainer for persistence
    ///   - mlModelRepository: Optional test ML repository (defaults to CoreMLModelRepository)
    init(modelContainer: ModelContainer, mlModelRepository: MLModelRepository? = nil) {
        self.dataFactory = DataFactory(modelContainer: modelContainer, mlModelRepository: mlModelRepository)
        self.domainFactory = DomainFactory(dataFactory: dataFactory)
        self.presentationFactory = PresentationFactory(domainFactory: domainFactory)
    }
    
    var presentation: PresentationFactory {
        presentationFactory
    }
}
