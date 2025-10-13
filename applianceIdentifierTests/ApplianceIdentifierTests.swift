//
//  applianceIdentifierTests.swift
//  applianceIdentifierTests
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import CoreGraphics
import CoreFoundation
import Testing
@testable import applianceIdentifier

struct ApplianceIdentifierTests {
    @Test("Creating ApplianceCreationData assigns all fields")
    @MainActor
    func createApplianceCreationData() async throws {
        let now = Date()
        let data = ApplianceCreationData(
            name: "microwave",
            category: "Kitchen",
            estimatedWattage: 1200,
            confidence: 0.92,
            timestamp: now,
            imageData: Data([0xAA, 0xBB])
        )
        #expect(data.name == "microwave")
        #expect(data.category == "Kitchen")
        #expect(data.estimatedWattage == 1200)
        #expect(data.confidence == 0.92)
        #expect(data.timestamp == now)
        #expect(data.imageData == Data([0xAA, 0xBB]))
    }

    @Test("StaticEnergyDataRepository fuzzy matching and fallback")
    @MainActor
    func staticRepositoryLookup() async throws {
        let repo = StaticEnergyDataRepository()
        let wattage1 = repo.estimateWattage(for: "microwave")
        #expect(wattage1 == 1200)
        let wattage2 = repo.estimateWattage(for: "Washing Machine")
        #expect(wattage2 == 500)
        let wattage3 = repo.estimateWattage(for: "UnknownThing")
        #expect(wattage3 == 100)
        let cat = repo.getCategory(for: "UnknownThing")
        #expect(cat == "Unknown")
    }

    @Test("ClassifyApplianceUseCase produces expected ApplianceCreationData")
    @MainActor
    func classifyApplianceIntegration() async throws {
        class TestEnergyDataRepository: EnergyDataRepository {
            func getEnergyData(for applianceName: String) -> ApplianceEnergyData? {
                ApplianceEnergyData(category: "Laundry", typicalWattage: 501, usageHoursPerDay: 1)
            }
            func estimateWattage(for applianceName: String) -> Double { 501 }
            func getCategory(for applianceName: String) -> String { "Laundry" }
        }
        let useCase = ClassifyApplianceUseCase(
            mlModelRepository: TestMLModelRepository(),
            energyDataRepository: TestEnergyDataRepository()
        )
        let dataProvider = CGDataProvider(data: Data([0xFF,0xFF,0xFF,0xFF]) as CFData)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let image = CGImage(
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )!

        let result = try await useCase.classifyAppliance(from: image)
        #expect(result.name == "washing machine")
        #expect(result.category == "Laundry")
        #expect(result.estimatedWattage == 501)
        #expect(abs(result.confidence - 0.88) < 0.0001, "Confidence should match ML result")
        #expect(result.imageData != nil, "Should produce JPEG image data")
    }

}

@MainActor
private class TestMLModelRepository: MLModelRepository {
    func classify(image: CGImage) async throws -> applianceIdentifier.ClassificationResult {
        .init(identifier: "n01234567 washing_machine", confidence: 0.88)
    }
    
    var modelMetadata: [String : String] = [:]
}

#if canImport(applianceIdentifier)
// Using app module types
#else
// Test-only shims to satisfy the compiler when app types are not visible.
// If your app defines these types, prefer making them internal/public in the app target and remove these shims.
struct ApplianceCreationData {
    let name: String
    let category: String
    let estimatedWattage: Double
    let confidence: Float
    let timestamp: Date
    let imageData: Data?
}

struct ApplianceEnergyData {
    let category: String
    let typicalWattage: Double
    let usageHoursPerDay: Double
}

protocol MLModelRepository {
    @MainActor
    func classify(image: CGImage) async throws -> (identifier: String, confidence: Float)
}

protocol EnergyDataRepository {
    func getEnergyData(for applianceName: String) -> ApplianceEnergyData?
    func estimateWattage(for applianceName: String) -> Double
    func getCategory(for applianceName: String) -> String
}

struct StaticEnergyDataRepository: EnergyDataRepository {
    func getEnergyData(for applianceName: String) -> ApplianceEnergyData? { nil }
    func estimateWattage(for applianceName: String) -> Double { 100 }
    func getCategory(for applianceName: String) -> String { "Unknown" }
}

struct ClassifyApplianceUseCase {
    let mlModelRepository: MLModelRepository
    let energyDataRepository: EnergyDataRepository
    func classifyAppliance(from image: CGImage) async throws -> ApplianceCreationData {
        let result = try await mlModelRepository.classify(image: image)
        let name = result.identifier.split(separator: " ").last.map(String.init) ?? result.identifier
        let category = energyDataRepository.getCategory(for: name)
        let watt = energyDataRepository.estimateWattage(for: name)
        return ApplianceCreationData(
            name: name.replacingOccurrences(of: "_", with: " "),
            category: category,
            estimatedWattage: watt,
            confidence: result.confidence,
            timestamp: Date(),
            imageData: Data([0x00])
        )
    }
}
#endif

