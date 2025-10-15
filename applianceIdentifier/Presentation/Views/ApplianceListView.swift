//
//  ApplianceListView.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import SwiftUI
import ImageIO

struct ApplianceListView: View {
    @Environment(PresentationFactory.self) private var presentation
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
                viewModel = presentation.applianceListViewModel
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

#Preview {
    ApplianceListView()
}
