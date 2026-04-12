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
                    title: "Apple Santé",
                    status: healthKit.isAuthorized ? "Autorisé" : "Non autorisé",
                    isOk: healthKit.isAuthorized
                )

                if let error = healthKit.authorizationError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await healthKit.requestAuthorization() }
                } label: {
                    Label(
                        healthKit.isAuthorized ? "Mettre à jour les permissions" : "Autoriser l'accès",
                        systemImage: "lock.open.fill"
                    )
                }
                .foregroundStyle(.accentColor)
            }

            Section("Météo") {
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
                    Label("Autoriser la localisation", systemImage: "location.fill")
                }
                .foregroundStyle(.accentColor)
                .disabled(weather.locationAuthStatus == .authorizedWhenInUse)

                if let snap = weather.lastSnapshot {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dernières données météo :")
                            .font(.caption.weight(.medium))
                        Text("\(snap.temperatureCelsius.oneDecimal) °C · \(Int(snap.pressureHPa)) hPa · \(Int(snap.humidityPercent)) %")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("À propos") {
                LabeledContent("WeatherKit", value: "Apple Inc. — inclus avec Developer Program")
                LabeledContent("Open-Meteo", value: "open-meteo.com — gratuit, sans clé")
                Text("⚠️ Attribution WeatherKit requise : logo Weather + lien légal Apple.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sources de données")
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
        case .notDetermined:      return "Non demandé"
        case .restricted:         return "Restreint"
        case .denied:             return "Refusé"
        case .authorizedAlways:   return "Autorisé (toujours)"
        case .authorizedWhenInUse: return "Autorisé"
        @unknown default:         return "Inconnu"
        }
    }
}
