//
//  MLModelRepository.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import CoreML
import Vision
import CoreGraphics

/// Result of a machine learning classification operation.
struct ClassificationResult {
    /// The identified object/scene label
    let identifier: String

    /// Confidence score from 0.0 to 1.0
    let confidence: Float
}

/// Repository protocol for machine learning model operations.
protocol MLModelRepository {
    /// Classifies an image using the ML model.
    /// - Parameter image: The image to classify
    /// - Returns: Classification result with identifier and confidence
    /// - Throws: MLModelError if classification fails
    func classify(image: CGImage) async throws -> ClassificationResult

    /// Metadata about the current ML model for versioning and monitoring.
    var modelMetadata: [String: String] { get }
}

/// Vision framework implementation using Apple's scene classifier.
/// In production, replace with a custom CoreML model trained on appliance images.
final class CoreMLModelRepository: MLModelRepository {
    private var model: VNCoreMLModel?
    private let modelVersion = "1.0.0"

    /// Initializes the repository.
    /// For production, load a custom .mlmodel file here using VNCoreMLModel(for:).
    init() {}

    /// Classifies an image using Apple's built-in scene classifier.
    /// Returns the top classification result with confidence score.
    func classify(image: CGImage) async throws -> ClassificationResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Use a lock to prevent double-resumption when Vision framework errors occur
            let lock = NSLock()
            var resumed = false

            let request = VNClassifyImageRequest { request, error in
                lock.lock()
                defer { lock.unlock() }

                // Guard against double-resumption
                guard !resumed else { return }
                resumed = true

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(throwing: MLModelError.noResults)
                    return
                }

                let result = ClassificationResult(
                    identifier: topResult.identifier,
                    confidence: topResult.confidence
                )
                continuation.resume(returning: result)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                lock.lock()
                defer { lock.unlock() }

                // Guard against double-resumption
                guard !resumed else { return }
                resumed = true

                continuation.resume(throwing: error)
            }
        }
    }

    /// Metadata about the current ML model for MLOps tracking.
    /// Includes version, type, framework, and last update timestamp.
    var modelMetadata: [String: String] {
        return [
            "version": modelVersion,
            "modelType": "VNSceneClassifier",
            "framework": "Vision",
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "note": "Using Apple's built-in scene classifier. Replace with custom CoreML model for production."
        ]
    }
}

/// Errors that can occur during ML model operations.
enum MLModelError: Error {
    /// The CoreML model failed to load
    case modelNotLoaded

    /// No classification results were returned
    case noResults
}
