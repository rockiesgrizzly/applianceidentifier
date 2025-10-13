//
//  ApplianceListView.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import SwiftUI
import ImageIO

struct ApplianceListView: View {
    @Environment(AppDependencyContainer.self) private var container
    @State private var viewModel: ApplianceListViewModel?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Appliances")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Scan Appliance", systemImage: "camera")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = container.applianceListViewModel
                await viewModel?.loadAppliances()
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: ApplianceListViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if viewModel.appliances.isEmpty {
            ContentUnavailableView(
                "No Appliances",
                systemImage: "lightbulb",
                description: Text("Tap the camera button to scan an appliance")
            )
        } else {
            List {
                ForEach(viewModel.appliances) { appliance in
                    ApplianceRow(appliance: appliance)
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.deleteAppliance(viewModel.appliances[index])
                        }
                    }
                }
            }
        }
    }
}

struct ApplianceRow: View {
    let appliance: ApplianceDTO

    var body: some View {
        HStack {
            if let imageData = appliance.imageData,
               let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appliance.name)
                    .font(.headline)

                Text(appliance.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("\(Int(appliance.estimatedWattage))W")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("$\(appliance.monthlyCost, specifier: "%.2f")/mo")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(Int(appliance.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ApplianceListView()
}
