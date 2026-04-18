//
//  LocationAddressService.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Contacts
import CoreLocation
import Foundation

protocol LocationAddressService {
    func requestCurrentAddress() async throws -> AddressSuggestion
    func resolveAddress(roadAddress: String, detailText: String) async throws -> AddressSuggestion
}

enum LocationAddressError: LocalizedError {
    case servicesDisabled
    case permissionDenied
    case locationUnavailable
    case addressUnavailable

    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            return "기기의 위치 서비스가 꺼져 있어요."
        case .permissionDenied:
            return "앱에 위치 권한이 없어요. 설정에서 위치 접근을 허용해 주세요."
        case .locationUnavailable:
            return "현재 위치를 가져오지 못했어요. 잠시 후 다시 시도해 주세요."
        case .addressUnavailable:
            return "현재 위치의 주소를 확인하지 못했어요."
        }
    }
}

final class AppleLocationAddressService: NSObject, LocationAddressService {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentAddress() async throws -> AddressSuggestion {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationAddressError.servicesDisabled
        }

        try await ensureAuthorization()
        let location = try await requestLocation()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw LocationAddressError.addressUnavailable
        }

        let address = formattedAddress(from: placemark)
        guard address.isEmpty == false else {
            throw LocationAddressError.addressUnavailable
        }
        return makeSuggestion(
            roadAddress: address,
            detailText: "현재 위치",
            coordinate: location.coordinate
        )
    }

    func resolveAddress(roadAddress: String, detailText: String) async throws -> AddressSuggestion {
        let placemarks = try await geocoder.geocodeAddressString(roadAddress)
        guard let placemark = placemarks.first else {
            throw LocationAddressError.addressUnavailable
        }

        let coordinate = placemark.location?.coordinate
        return makeSuggestion(
            roadAddress: roadAddress,
            detailText: detailText,
            coordinate: coordinate
        )
    }

    private func ensureAuthorization() async throws {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .notDetermined:
            try await withCheckedThrowingContinuation { continuation in
                authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            throw LocationAddressError.permissionDenied
        @unknown default:
            throw LocationAddressError.permissionDenied
        }
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    private func formattedAddress(from placemark: CLPlacemark) -> String {
        if let postalAddress = placemark.postalAddress {
            let components: [String] = [
                postalAddress.state,
                postalAddress.city,
                postalAddress.subLocality,
                postalAddress.street
            ].filter { $0.isEmpty == false }
            if components.isEmpty == false {
                return components.joined(separator: " ")
            }
        }

        let rawComponents: [String?] = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare
        ]
        let components: [String] = rawComponents.compactMap { value in
            guard let value, value.isEmpty == false else { return nil }
            return value
        }

        if components.isEmpty == false {
            return components.joined(separator: " ")
        }

        return placemark.name ?? ""
    }

    private func makeSuggestion(
        roadAddress: String,
        detailText: String,
        coordinate: CLLocationCoordinate2D?
    ) -> AddressSuggestion {
        let normalizedID = roadAddress
            .lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.isEmpty == false }
            .joined(separator: "-")

        return AddressSuggestion(
            id: normalizedID.isEmpty ? UUID().uuidString : "address-\(normalizedID)",
            roadAddress: roadAddress,
            detailText: detailText,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )
    }
}

extension AppleLocationAddressService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let authorizationContinuation else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            self.authorizationContinuation = nil
            authorizationContinuation.resume()
        case .denied, .restricted:
            self.authorizationContinuation = nil
            authorizationContinuation.resume(throwing: LocationAddressError.permissionDenied)
        case .notDetermined:
            break
        @unknown default:
            self.authorizationContinuation = nil
            authorizationContinuation.resume(throwing: LocationAddressError.permissionDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationContinuation else { return }
        self.locationContinuation = nil

        if let location = locations.last {
            locationContinuation.resume(returning: location)
        } else {
            locationContinuation.resume(throwing: LocationAddressError.locationUnavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard let locationContinuation else { return }
        self.locationContinuation = nil
        locationContinuation.resume(throwing: error)
    }
}
