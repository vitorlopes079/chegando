//
//  MapPickerView.swift
//  DestinoAlerta
//

import SwiftUI
import MapKit

struct MapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var locationService: LocationService

    @StateObject private var viewModel = MapViewModel()
    @State private var hasCenteredOnUser = false

    let onDestinationSelected: (Destination) -> Void

    var body: some View {
        ZStack {
            // Map with dark style
            mapView

            // Top overlay
            VStack(spacing: 0) {
                // Header bar
                HStack(spacing: 16) {
                    closeButton

                    Spacer()

                    Text("Escolher Destino")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    // Invisible spacer for centering
                    Circle()
                        .fill(.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                Spacer()
            }
            .padding(.top, 44)

            // Bottom panel
            VStack {
                Spacer()
                bottomPanel
            }
        }
        .background(Theme.background)
        .ignoresSafeArea(edges: .all)
        .preferredColorScheme(.dark)
        .onAppear {
            setupLocation()
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            // Center map on user location when first received
            if let location = newLocation, !hasCenteredOnUser {
                hasCenteredOnUser = true
                viewModel.centerOnUserLocation(location)
            }
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            // Start location updates when permission is granted
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationService.startUpdatingLocation()
            }
        }
    }

    // MARK: - Map View

    @ViewBuilder
    private var mapView: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                if let coordinate = viewModel.selectedCoordinate {
                    // Radius circle
                    MapCircle(center: coordinate, radius: viewModel.selectedRadius)
                        .foregroundStyle(Theme.accent.opacity(0.15))
                        .stroke(Theme.accent, lineWidth: 2)

                    // Pin
                    Annotation("Destino", coordinate: coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.accent)
                                .glow(Theme.accent, radius: 4)

                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.accent)
                                .offset(y: -4)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .all))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    viewModel.selectLocation(coordinate)
                }
            }
        }
    }

    // MARK: - Search Bar

    @ViewBuilder
    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.accent)

                    TextField("Buscar endereço...", text: $viewModel.searchText)
                        .foregroundStyle(Theme.textPrimary)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.search()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                            viewModel.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding(14)
                .background(Theme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                )

                // Search button
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.search()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.background)
                        .padding(14)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Search results
            if !viewModel.searchResults.isEmpty {
                searchResultsList
            }

            // Loading
            if viewModel.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Theme.accent)
                    Text("Buscando...")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(10)
                .background(Theme.backgroundSecondary)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.selectSearchResult(item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Theme.accent)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Local")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Theme.textPrimary)

                                if let subtitle = item.placemark.title {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(Theme.textTertiary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(14)
                    }

                    Divider()
                        .background(Theme.backgroundTertiary)
                        .padding(.leading, 48)
                }
            }
        }
        .frame(maxHeight: 220)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.accent.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Bottom Panel

    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 20) {
            // Radius picker
            VStack(alignment: .leading, spacing: 10) {
                Text("RAIO DO ALARME")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                HStack(spacing: 10) {
                    ForEach(viewModel.radiusOptions, id: \.self) { radius in
                        Button {
                            viewModel.selectedRadius = radius
                        } label: {
                            Text(viewModel.radiusLabel(for: radius))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    viewModel.selectedRadius == radius
                                        ? Theme.accent
                                        : Theme.backgroundTertiary
                                )
                                .foregroundStyle(
                                    viewModel.selectedRadius == radius
                                        ? Theme.background
                                        : Theme.textSecondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.selectedRadius == radius
                                                ? Theme.accent
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }
            }

            // Confirm button
            Button {
                confirmSelection()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)

                    Text("Confirmar Destino")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    viewModel.selectedCoordinate != nil
                        ? Theme.accent
                        : Theme.backgroundTertiary
                )
                .foregroundStyle(
                    viewModel.selectedCoordinate != nil
                        ? Theme.background
                        : Theme.textTertiary
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.selectedCoordinate == nil)

            // Hint
            if viewModel.selectedCoordinate == nil {
                Text("Toque no mapa ou busque um endereço")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(20)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Close Button

    @ViewBuilder
    private var closeButton: some View {
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
    }

    // MARK: - Actions

    private func setupLocation() {
        if locationService.needsPermission {
            // Request permission - onChange will handle starting updates
            locationService.requestWhenInUsePermission()
        } else if locationService.isAuthorizedForWhenInUse {
            // Already authorized, start getting location
            locationService.startUpdatingLocation()

            // If we already have a location, center immediately
            if let location = locationService.currentLocation, !hasCenteredOnUser {
                hasCenteredOnUser = true
                viewModel.centerOnUserLocation(location)
            }
        }
    }

    private func confirmSelection() {
        guard let destination = viewModel.createDestination() else { return }

        locationService.stopUpdatingLocation()
        onDestinationSelected(destination)
        dismiss()
    }
}

#Preview {
    MapPickerView { _ in }
        .environmentObject(LocationService())
}
