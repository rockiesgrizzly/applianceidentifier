//
//  ClassifyApplianceUseCase.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Use case protocol for classifying appliances from images using ML.
protocol ClassifyApplianceUseCaseProtocol {
    /// Classifies an appliance from an image and enriches it with energy consumption data.
    /// - Parameter image: The CGImage containing the appliance to classify
    /// - Returns: ApplianceCreationData with classification results and energy estimates
    /// - Throws: MLModelError if classification fails
    func classifyAppliance(from image: CGImage) async throws -> ApplianceCreationData
}

/// Orchestrates appliance classification by combining ML inference with energy data lookup.
/// This is the core business logic for identifying appliances and estimating their energy usage.
final class ClassifyApplianceUseCase: ClassifyApplianceUseCaseProtocol {
    private let mlModelRepository: MLModelRepository
    private let energyDataRepository: EnergyDataRepository

    init(
        mlModelRepository: MLModelRepository,
        energyDataRepository: EnergyDataRepository
    ) {
        self.mlModelRepository = mlModelRepository
        self.energyDataRepository = energyDataRepository
    }

    /// Classifies an appliance from an image and enriches it with energy consumption data.
    /// Performs ML classification, cleans the identifier, looks up energy data, and constructs ApplianceCreationData.
    func classifyAppliance(from image: CGImage) async throws -> ApplianceCreationData {
        let result = try await mlModelRepository.classify(image: image)
        let applianceName = cleanApplianceName(result.identifier)
        let estimatedWattage = energyDataRepository.estimateWattage(for: applianceName)
        let category = energyDataRepository.getCategory(for: applianceName)
        let imageData = convertToJPEGData(image)

        return ApplianceCreationData(
            name: applianceName,
            category: category,
            estimatedWattage: estimatedWattage,
            confidence: Double(result.confidence),
            imageData: imageData
        )
    }

    /// Converts ML model identifiers to human-readable names.
    /// Handles formats like "n07697537 washing_machine" by extracting and formatting the readable part.
    private func cleanApplianceName(_ identifier: String) -> String {
        let components = identifier.components(separatedBy: " ")
        if components.count > 1 {
            return components[1...].joined(separator: " ").replacingOccurrences(of: "_", with: " ")
        }
        return identifier.replacingOccurrences(of: "_", with: " ")
    }

    /// Converts a CGImage to JPEG data for storage.
    /// - Parameter image: The CGImage to convert
    /// - Returns: JPEG data at 80% quality, or nil if conversion fails
    private func convertToJPEGData(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data
    }
}
