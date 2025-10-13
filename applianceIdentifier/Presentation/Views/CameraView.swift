//
//  CameraView.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import SwiftUI
import PhotosUI
import ImageIO

struct CameraView: View {
    @Environment(AppDependencyContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CameraViewModel?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: CGImage?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Scan Appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = container.cameraViewModel
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                   let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                    selectedImage = image
                    await viewModel?.classifyAndSave(image: image)
                }
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: CameraViewModel) -> some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ContentUnavailableView(
                    "Select a Photo",
                    systemImage: "photo",
                    description: Text("Choose a photo of an appliance to identify")
                )
            }

            if viewModel.isProcessing {
                ProgressView("Analyzing appliance...")
            } else if let appliance = viewModel.classifiedAppliance {
                VStack(spacing: 12) {
                    Text("Identified!")
                        .font(.headline)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Name:")
                                .fontWeight(.semibold)
                            Text(appliance.name)
                        }

                        HStack {
                            Text("Category:")
                                .fontWeight(.semibold)
                            Text(appliance.category)
                        }

                        HStack {
                            Text("Estimated Power:")
                                .fontWeight(.semibold)
                            Text("\(Int(appliance.estimatedWattage))W")
                        }

                        HStack {
                            Text("Monthly Cost:")
                                .fontWeight(.semibold)
                            Text("$\(appliance.monthlyCost, specifier: "%.2f")")
                        }

                        HStack {
                            Text("Confidence:")
                                .fontWeight(.semibold)
                            Text("\(Int(appliance.confidence * 100))%")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.isProcessing && viewModel.classifiedAppliance == nil {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    CameraView()
}
