//
//  ApplianceDTO.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// Data Transfer Object for creating a new appliance.
/// Used when classification results need to be persisted.
/// DTO Usage:
/// 1. Thread-safety - All properties are immutable (let) and Sendable types
//  2. Decoupling - Views don't depend on SwiftData's @Model macro
//  3. Clear boundaries - Explicit conversion points show where data crosses contexts
//  4. Same interface - DTOs can have the same computed properties, so views don't need to change
struct ApplianceCreationData: Sendable {
    /// Human-readable name (e.g., "refrigerator", "washing machine")
    let name: String

    /// Appliance category (e.g., "Kitchen", "Laundry", "Climate")
    let category: String

    /// Estimated power consumption in watts
    let estimatedWattage: Double

    /// ML model confidence score (0.0 to 1.0)
    let confidence: Double

    /// Timestamp when the appliance was identified
    let timestamp: Date

    /// JPEG image data of the appliance photo
    let imageData: Data?

    init(
        name: String,
        category: String,
        estimatedWattage: Double,
        confidence: Double,
        timestamp: Date = Date(),
        imageData: Data? = nil
    ) {
        self.name = name
        self.category = category
        self.estimatedWattage = estimatedWattage
        self.confidence = confidence
        self.timestamp = timestamp
        self.imageData = imageData
    }
}

/// Data Transfer Object for passing appliance data across actor boundaries.
/// This Sendable struct allows safe concurrent access without requiring @unchecked Sendable.
struct ApplianceDTO: Sendable, Identifiable {
    /// Unique identifier for the appliance
    let id: UUID

    /// Persistent identifier for referencing the SwiftData model
    let persistentID: PersistentIdentifier

    /// Human-readable name (e.g., "refrigerator", "washing machine")
    let name: String

    /// Appliance category (e.g., "Kitchen", "Laundry", "Climate")
    let category: String

    /// Estimated power consumption in watts
    let estimatedWattage: Double

    /// ML model confidence score (0.0 to 1.0)
    let confidence: Double

    /// Timestamp when the appliance was identified
    let timestamp: Date

    /// JPEG image data of the appliance photo
    let imageData: Data?

    /// Estimated daily energy consumption in kilowatt-hours.
    /// Assumes 24-hour usage; adjust based on appliance type for production.
    var dailyKWh: Double {
        (estimatedWattage * 24) / 1000
    }

    /// Estimated monthly electricity cost in USD.
    /// Calculated using average US electricity rate of $0.16 per kWh.
    var monthlyCost: Double {
        let monthlyKWh = dailyKWh * 30
        return monthlyKWh * 0.16
    }
}

// MARK: Interfaces

extension ApplianceDTO {
    /// Creates a DTO from a SwiftData Appliance model.
    /// - Parameter appliance: The Appliance model to convert
    static func from(_ appliance: Appliance) -> Self {
        Self(id: appliance.id,
             persistentID: appliance.persistentModelID,
             name: appliance.name,
             category: appliance.category,
             estimatedWattage: appliance.estimatedWattage,
             confidence: appliance.confidence,
             timestamp: appliance.timestamp,
             imageData: appliance.imageData)
    }
}
