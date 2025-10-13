//
//  EnergyDataRepository.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation

/// Energy consumption data for a specific appliance type.
struct ApplianceEnergyData {
    /// Appliance category (e.g., "Kitchen", "Laundry")
    let category: String

    /// Average power consumption in watts
    let typicalWattage: Double

    /// Estimated hours of usage per day
    let usageHoursPerDay: Double

    /// Calculated daily energy consumption in kilowatt-hours
    var dailyKWh: Double {
        (typicalWattage * usageHoursPerDay) / 1000
    }
}

/// Repository protocol for looking up appliance energy consumption data.
protocol EnergyDataRepository {
    /// Retrieves complete energy data for an appliance.
    /// - Parameter applianceName: The appliance name to look up
    /// - Returns: Energy data if found, nil otherwise
    func getEnergyData(for applianceName: String) -> ApplianceEnergyData?

    /// Estimates typical wattage for an appliance.
    /// - Parameter applianceName: The appliance name to look up
    /// - Returns: Estimated wattage, defaults to 100W if not found
    func estimateWattage(for applianceName: String) -> Double

    /// Retrieves the category for an appliance.
    /// - Parameter applianceName: The appliance name to look up
    /// - Returns: Category name, defaults to "Unknown" if not found
    func getCategory(for applianceName: String) -> String
}

/// Static database of typical appliance energy consumption values.
/// Contains 20+ common household appliances with realistic wattage and usage patterns.
final class StaticEnergyDataRepository: EnergyDataRepository {
    /// Database of appliance energy data organized by normalized appliance name.
    /// Values based on typical residential usage patterns in the United States.
    private let energyData: [String: ApplianceEnergyData] = [
        // Kitchen Appliances
        "refrigerator": ApplianceEnergyData(category: "Kitchen", typicalWattage: 150, usageHoursPerDay: 24),
        "microwave": ApplianceEnergyData(category: "Kitchen", typicalWattage: 1200, usageHoursPerDay: 0.5),
        "oven": ApplianceEnergyData(category: "Kitchen", typicalWattage: 2400, usageHoursPerDay: 1),
        "dishwasher": ApplianceEnergyData(category: "Kitchen", typicalWattage: 1800, usageHoursPerDay: 1),
        "toaster": ApplianceEnergyData(category: "Kitchen", typicalWattage: 1200, usageHoursPerDay: 0.2),
        "coffee maker": ApplianceEnergyData(category: "Kitchen", typicalWattage: 1000, usageHoursPerDay: 0.5),

        // Laundry
        "washer": ApplianceEnergyData(category: "Laundry", typicalWattage: 500, usageHoursPerDay: 1),
        "dryer": ApplianceEnergyData(category: "Laundry", typicalWattage: 3000, usageHoursPerDay: 1),
        "washing machine": ApplianceEnergyData(category: "Laundry", typicalWattage: 500, usageHoursPerDay: 1),

        // Climate Control
        "air conditioner": ApplianceEnergyData(category: "Climate", typicalWattage: 3500, usageHoursPerDay: 8),
        "heater": ApplianceEnergyData(category: "Climate", typicalWattage: 1500, usageHoursPerDay: 6),
        "fan": ApplianceEnergyData(category: "Climate", typicalWattage: 75, usageHoursPerDay: 8),

        // Electronics
        "television": ApplianceEnergyData(category: "Electronics", typicalWattage: 150, usageHoursPerDay: 5),
        "computer": ApplianceEnergyData(category: "Electronics", typicalWattage: 200, usageHoursPerDay: 8),
        "monitor": ApplianceEnergyData(category: "Electronics", typicalWattage: 50, usageHoursPerDay: 8),
        "laptop": ApplianceEnergyData(category: "Electronics", typicalWattage: 50, usageHoursPerDay: 8),

        // Lighting
        "lamp": ApplianceEnergyData(category: "Lighting", typicalWattage: 60, usageHoursPerDay: 5),

        // Water Heating
        "water heater": ApplianceEnergyData(category: "Water Heating", typicalWattage: 4500, usageHoursPerDay: 3),
    ]

    /// Looks up energy data with fuzzy matching.
    /// First attempts exact match (case-insensitive), then falls back to substring matching.
    func getEnergyData(for applianceName: String) -> ApplianceEnergyData? {
        let normalizedName = applianceName.lowercased()

        if let data = energyData[normalizedName] {
            return data
        }

        for (key, data) in energyData {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return data
            }
        }

        return nil
    }

    /// Returns estimated wattage with 100W fallback for unknown appliances.
    func estimateWattage(for applianceName: String) -> Double {
        return getEnergyData(for: applianceName)?.typicalWattage ?? 100.0
    }

    /// Returns category with "Unknown" fallback for unrecognized appliances.
    func getCategory(for applianceName: String) -> String {
        return getEnergyData(for: applianceName)?.category ?? "Unknown"
    }
}
