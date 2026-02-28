//
//  LiveTrackingView.swift
//  DestinoAlerta
//

import SwiftUI
import MapKit

struct LiveTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var geofenceService: GeofenceService

    @StateObject private var viewModel = TrackingViewModel()

    let destination: Destination

    var body: some View {
        ZStack {
            // Map
            mapView

            // Top bar
            VStack {
                topBar
                Spacer()
            }

            // Distance card overlay
            VStack {
                Spacer()
                distanceCard
            }
        }
        .ignoresSafeArea(edges: .all)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startTracking(
                destination: destination,
                locationService: locationService
            )
        }
        .onDisappear {
            viewModel.stopTracking(locationService: locationService)
        }
    }

    // MARK: - Map View

    @ViewBuilder
    private var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            // User location
            UserAnnotation()

            // Destination pin
            Annotation("Destino", coordinate: destination.coordinate) {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 44, height: 44)
                            .glow(Theme.accent, radius: 5)

                        Image(systemName: "flag.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.background)
                    }

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                        .offset(y: -6)
                }
            }

            // Alarm radius circle
            MapCircle(center: destination.coordinate, radius: destination.radius)
                .foregroundStyle(Theme.accent.opacity(0.15))
                .stroke(Theme.accent, lineWidth: 2)
        }
        .mapStyle(.standard(pointsOfInterest: .all))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private var topBar: some View {
        HStack(spacing: 16) {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(Theme.backgroundSecondary)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                    )
            }

            Spacer()

            // Title
            VStack(spacing: 2) {
                Text("RASTREANDO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)
                    .tracking(1.5)

                Text(destination.name.isEmpty ? "Destino" : destination.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.backgroundSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
            )

            Spacer()

            // Center on user button
            Button {
                if let location = locationService.currentLocation {
                    viewModel.centerOnUser(location)
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(12)
                    .background(Theme.backgroundSecondary)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.top, 52)
    }

    // MARK: - Distance Card

    @ViewBuilder
    private var distanceCard: some View {
        VStack(spacing: 16) {
            // Distance display
            HStack(spacing: 16) {
                // Distance icon with pulse when close
                ZStack {
                    if viewModel.isVeryClose {
                        Circle()
                            .fill(Theme.alarm.opacity(0.3))
                            .frame(width: 60, height: 60)

                        Circle()
                            .fill(Theme.alarm)
                            .frame(width: 48, height: 48)
                            .glow(Theme.alarm, radius: 8)
                    } else {
                        Circle()
                            .fill(Theme.accent.opacity(0.2))
                            .frame(width: 48, height: 48)
                    }

                    Image(systemName: viewModel.isVeryClose ? "bell.fill" : "location.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.isVeryClose ? .white : Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Você está a")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    Text(viewModel.formattedDistance)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.isVeryClose ? Theme.alarm : Theme.accent)
                        .glow(viewModel.isVeryClose ? Theme.alarm : Theme.accent, radius: 3)

                    Text("do destino")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()
            }

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isVeryClose ? Theme.alarm : Theme.accent)
                    .frame(width: 8, height: 8)
                    .glow(viewModel.isVeryClose ? Theme.alarm : Theme.accent, radius: 2)

                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                // Radius info
                Text("Raio: \(Int(destination.radius))m")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.backgroundTertiary)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    viewModel.isVeryClose
                        ? Theme.alarm.opacity(0.3)
                        : Theme.accent.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var statusText: String {
        if viewModel.isVeryClose {
            return "Quase lá! Prepare-se para descer"
        } else if viewModel.isNearDestination {
            return "Aproximando-se do destino"
        } else {
            return "Monitorando em tempo real"
        }
    }
}

#Preview {
    LiveTrackingView(
        destination: Destination(
            name: "Estação Sé",
            latitude: -23.5505,
            longitude: -46.6333,
            radius: 500
        )
    )
    .environmentObject(LocationService())
    .environmentObject(GeofenceService())
}
