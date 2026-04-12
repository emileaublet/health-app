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

@Observable
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
        // Essai WeatherKit d'abord
        if let location = locationManager.location ?? cachedLocation {
            if let snapshot = await fetchFromWeatherKit(location: location) {
                await MainActor.run { lastSnapshot = snapshot }
                return snapshot
            }
            // Fallback Open-Meteo
            if let snapshot = await fetchFromOpenMeteo(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            ) {
                await MainActor.run { lastSnapshot = snapshot }
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

extension WeatherDataService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        cachedLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failure is non-fatal; fallback to Open-Meteo with last known location
    }
}
