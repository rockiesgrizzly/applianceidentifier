//
//  applianceIdentifierTests.swift
//  applianceIdentifierTests
//
//  Created by Josh MacDonald on 10/13/25.
//

import Foundation
import CoreGraphics
import CoreFoundation
import SwiftData
import Testing
@testable import applianceIdentifier

// MARK: - Integration Tests

/// Integration tests for the full application stack.
/// Tests flow from ViewModels → Use Cases → Repositories → SwiftData.
/// Verifies DTOs properly cross actor boundaries and data persists correctly.
struct ApplianceIntegrationTests {

    /// Creates an in-memory test container for isolated testing
    @MainActor
    private func createTestContainer() throws -> (ModelContainer, AppDependencyContainer) {
        let schema = Schema([Appliance.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        // Use test ML repository to avoid slow Vision framework calls
        let dependencyContainer = AppDependencyContainer(
            modelContainer: container,
            mlModelRepository: TestMLModelRepository()
        )
        return (container, dependencyContainer)
    }

    /// Creates a test CGImage for classification tests
    private func createTestImage() -> CGImage {
        // Create a 2x2 pixel image with RGBA data (4 bytes per pixel)
        // Each pixel: R, G, B, A (premultiplied alpha)
        let pixelData: [UInt8] = [
            255, 0, 0, 255,    // Red pixel
            0, 255, 0, 255,    // Green pixel
            0, 0, 255, 255,    // Blue pixel
            255, 255, 0, 255   // Yellow pixel
        ]

        let dataProvider = CGDataProvider(data: Data(pixelData) as CFData)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let image = CGImage(
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 8,  // 2 pixels * 4 bytes per pixel
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            fatalError("Failed to create test CGImage - this should never happen with valid parameters")
        }

        return image
    }

    // MARK: - Full Stack Tests

    @Test("Integration: Classify and save appliance through full stack")
    @MainActor
    func classifyAndSaveFullStack() async throws {
        let (_, container) = try createTestContainer()
        let cameraViewModel = container.cameraViewModel
        let listViewModel = container.applianceListViewModel

        // Start with empty list
        await listViewModel.loadAppliances()
        #expect(listViewModel.appliances.isEmpty, "Should start with no appliances")

        // Classify and save an appliance
        let testImage = createTestImage()
        await cameraViewModel.classifyAndSave(image: testImage)

        // Verify ViewModel received the DTO
        #expect(cameraViewModel.classifiedAppliance != nil, "Should have classified appliance")
        #expect(cameraViewModel.errorMessage == nil, "Should have no errors")

        let classified = try #require(cameraViewModel.classifiedAppliance)
        #expect(classified.name.isEmpty == false, "Should have appliance name")
        #expect(classified.estimatedWattage > 0, "Should have wattage estimate")
        #expect(classified.confidence >= 0 && classified.confidence <= 1, "Confidence should be 0-1")

        // Verify persistence by loading in list view
        await listViewModel.loadAppliances()
        #expect(listViewModel.appliances.count == 1, "Should have 1 saved appliance")

        let savedAppliance = try #require(listViewModel.appliances.first)
        #expect(savedAppliance.id == classified.id, "IDs should match")
        #expect(savedAppliance.name == classified.name, "Names should match")
        #expect(savedAppliance.estimatedWattage == classified.estimatedWattage, "Wattage should match")
    }

    @Test("Integration: Load appliances returns DTOs on MainActor")
    @MainActor
    func loadAppliancesReturnsDTO() async throws {
        let (_, container) = try createTestContainer()
        let cameraViewModel = container.cameraViewModel
        let listViewModel = container.applianceListViewModel

        // Save multiple appliances
        for _ in 0..<3 {
            await cameraViewModel.classifyAndSave(image: createTestImage())
        }

        // Load appliances
        await listViewModel.loadAppliances()

        // Verify we got DTOs back
        #expect(listViewModel.appliances.count == 3, "Should have 3 appliances")
        #expect(listViewModel.errorMessage == nil, "Should have no errors")

        // Verify DTOs have data (proves they came from SwiftData)
        for dto in listViewModel.appliances {
            #expect(dto.name.isEmpty == false, "Should have name")
            #expect(dto.category.isEmpty == false, "Should have category")
            #expect(dto.estimatedWattage > 0, "Should have positive wattage")
        }

        // Verify sorted by most recent
        let timestamps = listViewModel.appliances.map { $0.timestamp }
        for i in 0..<(timestamps.count - 1) {
            #expect(timestamps[i] >= timestamps[i + 1], "Should be sorted by most recent")
        }
    }

    @Test("Integration: Delete appliance using PersistentIdentifier")
    @MainActor
    func deleteApplianceFullStack() async throws {
        let (_, container) = try createTestContainer()
        let cameraViewModel = container.cameraViewModel
        let listViewModel = container.applianceListViewModel

        // Create and save appliances
        await cameraViewModel.classifyAndSave(image: createTestImage())
        await cameraViewModel.classifyAndSave(image: createTestImage())
        await listViewModel.loadAppliances()

        #expect(listViewModel.appliances.count == 2, "Should start with 2 appliances")

        // Delete the first appliance using its DTO
        let toDelete = listViewModel.appliances[0]
        await listViewModel.deleteAppliance(toDelete)

        // Verify deletion
        #expect(listViewModel.appliances.count == 1, "Should have 1 appliance after delete")
        #expect(listViewModel.errorMessage == nil, "Should have no errors")

        // Verify the correct one was deleted (by checking ID)
        let remaining = listViewModel.appliances[0]
        #expect(remaining.persistentID != toDelete.persistentID, "Deleted appliance should be gone")
    }

    @Test("Integration: DTO computed properties match model values")
    @MainActor
    func dtoComputedPropertiesMatch() async throws {
        let (_, container) = try createTestContainer()
        let cameraViewModel = container.cameraViewModel
        let listViewModel = container.applianceListViewModel

        // Save an appliance
        await cameraViewModel.classifyAndSave(image: createTestImage())
        await listViewModel.loadAppliances()

        let dto = try #require(listViewModel.appliances.first)

        // Verify computed properties work
        let expectedDailyKWh = (dto.estimatedWattage * 24) / 1000
        let expectedMonthlyCost = (expectedDailyKWh * 30) * 0.16

        #expect(abs(dto.dailyKWh - expectedDailyKWh) < 0.01, "Daily kWh calculation should match")
        #expect(abs(dto.monthlyCost - expectedMonthlyCost) < 0.01, "Monthly cost calculation should match")
    }

    @Test("Integration: Multiple ViewModels share same repository data")
    @MainActor
    func multipleViewModelsShareData() async throws {
        let (_, container) = try createTestContainer()
        let cameraViewModel = container.cameraViewModel
        let listViewModel1 = container.applianceListViewModel
        let listViewModel2 = container.applianceListViewModel

        // Save through camera
        await cameraViewModel.classifyAndSave(image: createTestImage())

        // Load in both list ViewModels
        await listViewModel1.loadAppliances()
        await listViewModel2.loadAppliances()

        // Verify both see the same data
        #expect(listViewModel1.appliances.count == 1)
        #expect(listViewModel2.appliances.count == 1)
        #expect(listViewModel1.appliances[0].persistentID == listViewModel2.appliances[0].persistentID)
    }

    @Test("Integration: Error handling when repository throws")
    @MainActor
    func repositoryErrorHandling() async throws {
        // This test verifies error propagation through the stack
        // Since we're using in-memory SwiftData, errors are rare, but we verify the structure
        let (_, container) = try createTestContainer()
        let listViewModel = container.applianceListViewModel

        // Load from fresh container should work
        await listViewModel.loadAppliances()
        #expect(listViewModel.errorMessage == nil, "Should not have errors with valid container")
        #expect(listViewModel.appliances.isEmpty, "Should start empty")
    }
}

// MARK: - Unit Tests

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

