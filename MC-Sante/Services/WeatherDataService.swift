import Foundation
import WeatherKit
import CoreLocation

// MARK: - Data transfer struct

struct WeatherSnapshot {
    let temperatureCelsius: Double
    let pressureHPa: Double
    let humidityPercent: Double
}

// MARK: - Open-Meteo response shapes

private struct OpenMeteoResponse: Decodable {
    let current: OpenMeteoCurrent
}

private struct OpenMeteoCurrent: Decodable {
    let temperature_2m: Double
    let surface_pressure: Double
    let relative_humidity_2m: Double
}

// MARK: - WeatherDataService
// @MainActor ensures that all property writes are on the main thread, which
// is required by the @Observable macro. CLLocationManager delegate callbacks
// on iOS are delivered on the main thread, so no extra hopping is needed.

@Observable
@MainActor
final class WeatherDataService: NSObject {
    private let weatherService = WeatherService()
    private let locationManager = CLLocationManager()
    private var cachedLocation: CLLocation?

    private(set) var lastSnapshot: WeatherSnapshot?
    private(set) var locationAuthStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    // MARK: Public

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchWeather() async -> WeatherSnapshot? {
        if let location = locationManager.location ?? cachedLocation {
            if let snapshot = await fetchFromWeatherKit(location: location) {
                lastSnapshot = snapshot
                return snapshot
            }
            if let snapshot = await fetchFromOpenMeteo(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            ) {
                lastSnapshot = snapshot
                return snapshot
            }
        }
        return lastSnapshot
    }

    // MARK: Private — WeatherKit

    private func fetchFromWeatherKit(location: CLLocation) async -> WeatherSnapshot? {
        do {
            let weather = try await weatherService.weather(for: location)
            return WeatherSnapshot(
                temperatureCelsius: weather.currentWeather.temperature.converted(to: .celsius).value,
                pressureHPa: weather.currentWeather.pressure.converted(to: .hectopascals).value,
                humidityPercent: weather.currentWeather.humidity * 100
            )
        } catch {
            return nil
        }
    }

    // MARK: Private — Open-Meteo fallback

    private func fetchFromOpenMeteo(lat: Double, lon: Double) async -> WeatherSnapshot? {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,surface_pressure,relative_humidity_2m"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return WeatherSnapshot(
                temperatureCelsius: result.current.temperature_2m,
                pressureHPa: result.current.surface_pressure,
                humidityPercent: result.current.relative_humidity_2m
            )
        } catch {
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate
// On iOS, location delegate callbacks are delivered on the main thread,
// which satisfies our @MainActor isolation requirement.

extension WeatherDataService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            locationAuthStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            cachedLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal — will fall back to Open-Meteo with last known location
    }
}
