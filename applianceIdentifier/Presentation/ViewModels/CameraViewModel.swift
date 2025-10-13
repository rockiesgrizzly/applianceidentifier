//
//  CameraViewModel.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import CoreGraphics

/// ViewModel for the camera/photo picker screen.
/// Handles image classification and saving results.
@MainActor
@Observable
final class CameraViewModel {
    private let classifyApplianceUseCase: ClassifyApplianceUseCaseProtocol
    private let saveApplianceUseCase: SaveApplianceUseCaseProtocol

    /// Processing state indicator for ML inference
    var isProcessing = false

    /// Error message to display to user, if any
    var errorMessage: String?

    /// The most recently classified and saved appliance result
    var classifiedAppliance: ApplianceDTO?

    init(
        classifyApplianceUseCase: ClassifyApplianceUseCaseProtocol,
        saveApplianceUseCase: SaveApplianceUseCaseProtocol
    ) {
        self.classifyApplianceUseCase = classifyApplianceUseCase
        self.saveApplianceUseCase = saveApplianceUseCase
    }

    /// Classifies an appliance from an image and saves it to storage.
    /// Updates processing state, classified result, and error messages.
    /// - Parameter image: The CGImage to classify
    func classifyAndSave(image: CGImage) async {
        isProcessing = true
        errorMessage = nil
        classifiedAppliance = nil

        do {
            let creationData = try await classifyApplianceUseCase.classifyAppliance(from: image)
            let savedAppliance = try await saveApplianceUseCase.saveAppliance(creationData)
            classifiedAppliance = savedAppliance
        } catch {
            errorMessage = "Failed to classify appliance: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    /// Resets the classification state for a new capture.
    func reset() {
        classifiedAppliance = nil
        errorMessage = nil
    }
}
