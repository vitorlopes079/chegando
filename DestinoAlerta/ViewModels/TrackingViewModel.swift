//
//  TrackingViewModel.swift
//  DestinoAlerta
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
final class TrackingViewModel: ObservableObject {
    // Map state
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var isFollowingUser: Bool = true

    // Distance tracking
    @Published var distanceToDestination: Double = 0 // meters
    @Published var formattedDistance: String = "Calculando..."

    private var cancellables = Set<AnyCancellable>()

    init() {}

    // MARK: - Setup

    func startTracking(
        destination: Destination,
        locationService: LocationService
    ) {
        // Center map to show both user and destination
        if let userLocation = locationService.currentLocation {
            centerMapOnRoute(userLocation: userLocation, destination: destination)
            updateDistance(from: userLocation, to: destination)
        }

        // Subscribe to location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateDistance(from: location, to: destination)
                if self?.isFollowingUser == true {
                    self?.updateCameraToFollowUser(location, destination: destination)
                }
            }
            .store(in: &cancellables)

        // Start location updates
        locationService.startUpdatingLocation()
    }

    func stopTracking(locationService: LocationService) {
        cancellables.removeAll()
        locationService.stopUpdatingLocation()
    }

    // MARK: - Distance Calculation

    private func updateDistance(from userLocation: CLLocation, to destination: Destination) {
        let destinationLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        distanceToDestination = userLocation.distance(from: destinationLocation)
        formattedDistance = formatDistance(distanceToDestination)
    }

    func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return String(format: "%.1f km", km)
        } else {
            return "\(Int(meters)) m"
        }
    }

    // MARK: - Camera Control

    private func centerMapOnRoute(userLocation: CLLocation, destination: Destination) {
        let destCoord = CLLocationCoordinate2D(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        // Calculate center point between user and destination
        let centerLat = (userLocation.coordinate.latitude + destCoord.latitude) / 2
        let centerLon = (userLocation.coordinate.longitude + destCoord.longitude) / 2

        // Calculate span to fit both points with padding
        let latDelta = abs(userLocation.coordinate.latitude - destCoord.latitude) * 1.5
        let lonDelta = abs(userLocation.coordinate.longitude - destCoord.longitude) * 1.5

        // Minimum span
        let minDelta = 0.01

        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, minDelta),
                longitudeDelta: max(lonDelta, minDelta)
            )
        ))
    }

    private func updateCameraToFollowUser(_ location: CLLocation, destination: Destination) {
        // Keep both user and destination visible
        centerMapOnRoute(userLocation: location, destination: destination)
    }

    func centerOnUser(_ location: CLLocation) {
        isFollowingUser = true
        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func centerOnDestination(_ destination: Destination) {
        isFollowingUser = false
        cameraPosition = .region(MKCoordinateRegion(
            center: destination.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    // MARK: - Progress

    var progressPercentage: Double {
        // This would require knowing the starting distance
        // For now, we'll just show distance
        return 0
    }

    var isNearDestination: Bool {
        distanceToDestination < 1000 // Less than 1km
    }

    var isVeryClose: Bool {
        distanceToDestination < 300 // Less than 300m
    }
}
