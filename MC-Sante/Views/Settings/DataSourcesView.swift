import SwiftUI

struct DataSourcesView: View {
    let healthKit: HealthKitService
    let weather: WeatherDataService

    var body: some View {
        List {
            Section("HealthKit") {
                statusRow(
                    icon: "heart.fill",
                    color: .red,
                    title: L10n.appleHealth,
                    status: healthKit.isAuthorized ? L10n.authorized : L10n.notAuthorized,
                    isOk: healthKit.isAuthorized
                )

                if let error = healthKit.authorizationError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if healthKit.isAuthorized {
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label(L10n.updatePermissions, systemImage: "arrow.up.forward.app")
                    }
                    .foregroundStyle(Color.accentColor)
                } else {
                    Button {
                        Task { await healthKit.requestAuthorization() }
                    } label: {
                        Label(L10n.authorizeAccess, systemImage: "lock.open.fill")
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }

            Section(L10n.weatherSection) {
                statusRow(
                    icon: "cloud.sun.fill",
                    color: .orange,
                    title: "WeatherKit / Open-Meteo",
                    status: locationStatusLabel,
                    isOk: weather.locationAuthStatus == .authorizedWhenInUse ||
                          weather.locationAuthStatus == .authorizedAlways
                )

                Button {
                    weather.requestLocationPermission()
                } label: {
                    Label(L10n.authorizeLocation, systemImage: "location.fill")
                }
                .foregroundStyle(Color.accentColor)
                .disabled(weather.locationAuthStatus == .authorizedWhenInUse)

                if let snap = weather.lastSnapshot {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.latestWeatherData)
                            .font(.caption.weight(.medium))
                        Text("\(snap.temperatureCelsius.oneDecimal) °C · \(Int(snap.pressureHPa)) hPa · \(Int(snap.humidityPercent)) %")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(L10n.aboutSection) {
                LabeledContent("Open-Meteo", value: "open-meteo.com")
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(.blue)
                        Text(L10n.weatherAttributionLabel)
                            .font(.caption)
                        Text("Apple Weather")
                            .font(.caption.weight(.semibold))
                    }
                    Link("Legal Attribution", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                        .font(.caption2)
                }
            }
        }
        .navigationTitle(L10n.dataSourcesTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusRow(icon: String, color: Color, title: String, status: String, isOk: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                Text(status)
                    .font(.caption)
                    .foregroundStyle(isOk ? .green : .red)
            }
            Spacer()
            Image(systemName: isOk ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isOk ? .green : .red)
        }
    }

    private var locationStatusLabel: String {
        switch weather.locationAuthStatus {
        case .notDetermined:      return L10n.locationNotDetermined
        case .restricted:         return L10n.locationRestricted
        case .denied:             return L10n.locationDenied
        case .authorizedAlways:   return L10n.locationAuthorizedAlways
        case .authorizedWhenInUse: return L10n.locationAuthorized
        @unknown default:         return L10n.locationUnknown
        }
    }
}
