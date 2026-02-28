//
//  LocationService.swift
//  DestinoAlerta
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var locationError: Error?
    @Published var isUpdatingLocation: Bool = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permission Requests

    /// Request "When In Use" permission - call this first
    func requestWhenInUsePermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Request "Always" permission - iOS will show upgrade prompt if user already granted WhenInUse
    func requestAlwaysPermission() {
        // iOS requires WhenInUse to be granted before requesting Always
        // If not determined, request WhenInUse first
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse {
            // User already granted WhenInUse, now request upgrade to Always
            locationManager.requestAlwaysAuthorization()
        }
        // If already .authorizedAlways, nothing to do
    }

    /// Request the appropriate permission based on current state
    func requestPermissionForGeofencing() {
        switch authorizationStatus {
        case .notDetermined:
            // First request WhenInUse
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Then request Always for background geofencing
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // Already have the permission we need
            break
        default:
            break
        }
    }

    // MARK: - Location Updates

    func startUpdatingLocation() {
        guard isAuthorizedForWhenInUse else { return }
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }

    /// Request a single location update
    func requestCurrentLocation() {
        guard isAuthorizedForWhenInUse else { return }
        locationManager.requestLocation()
    }

    // MARK: - Status Checks

    var isAuthorizedForAlwaysLocation: Bool {
        authorizationStatus == .authorizedAlways
    }

    var isAuthorizedForWhenInUse: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    var needsAlwaysPermission: Bool {
        authorizationStatus == .authorizedWhenInUse
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var canRequestAlwaysUpgrade: Bool {
        authorizationStatus == .authorizedWhenInUse
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
            // Don't stop on error, just log it
            print("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let newStatus = manager.authorizationStatus
            self.authorizationStatus = newStatus

            // Auto-start location updates when permission is granted
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                if self.isUpdatingLocation {
                    manager.startUpdatingLocation()
                }
            }
        }
    }
}
