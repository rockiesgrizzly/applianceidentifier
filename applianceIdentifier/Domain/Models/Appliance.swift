//
//  Appliance.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import SwiftData

/// Domain entity representing an identified appliance with energy consumption data.
/// Persisted using SwiftData for historical tracking.
/// Thread-safety should be handled through ModelActor when crossing actor boundaries.
@Model
final class Appliance {
    /// Unique identifier for the appliance
    var id: UUID

    /// Human-readable name (e.g., "refrigerator", "washing machine")
    var name: String

    /// Appliance category (e.g., "Kitchen", "Laundry", "Climate")
    var category: String

    /// Estimated power consumption in watts
    var estimatedWattage: Double

    /// ML model confidence score (0.0 to 1.0)
    var confidence: Double

    /// Timestamp when the appliance was identified
    var timestamp: Date

    /// JPEG image data of the appliance photo
    var imageData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        estimatedWattage: Double,
        confidence: Double,
        timestamp: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.estimatedWattage = estimatedWattage
        self.confidence = confidence
        self.timestamp = timestamp
        self.imageData = imageData
    }

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
