//
//  ApplianceRow.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/15/25.
//

import SwiftUI

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
