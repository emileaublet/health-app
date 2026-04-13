import SwiftUI

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.french.rawValue
        self.language = AppLanguage(rawValue: saved) ?? .french
    }
}

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .french:  return "fr_CA"
        case .english: return "en_CA"
        }
    }

    var displayName: String {
        switch self {
        case .french:  return "Français"
        case .english: return "English"
        }
    }
}

// MARK: - Localized strings

enum L10n {
    private static var lang: AppLanguage { LocalizationManager.shared.language }

    // MARK: Tabs
    static var tabHome: String { lang == .french ? "Accueil" : "Home" }
    static var tabLog: String { lang == .french ? "Saisie" : "Log" }
    static var tabTrends: String { lang == .french ? "Tendances" : "Trends" }
    static var tabSettings: String { lang == .french ? "Réglages" : "Settings" }

    // MARK: Home
    static var today: String { lang == .french ? "Aujourd'hui" : "Today" }
    static var yesterday: String { lang == .french ? "Hier" : "Yesterday" }

    static func streakDays(_ count: Int) -> String {
        if lang == .french {
            return "🔥 \(count) jour\(count > 1 ? "s" : "") de suite"
        } else {
            return "🔥 \(count) day\(count > 1 ? "s" : "") in a row"
        }
    }

    // Section headers
    static var sectionSleep: String { lang == .french ? "Sommeil" : "Sleep" }
    static var sectionCardiac: String { lang == .french ? "Cardiaque" : "Cardiac" }
    static var sectionActivity: String { lang == .french ? "Activité" : "Activity" }
    static var sectionEnvironment: String { lang == .french ? "Environnement" : "Environment" }
    static var sectionMood: String { lang == .french ? "Humeur" : "Mood" }
    static var sectionCycle: String { lang == .french ? "Cycle" : "Cycle" }
    static var sectionDisplayed: String { lang == .french ? "Sections affichées" : "Displayed Sections" }
    // Metric titles
    static var totalDuration: String { lang == .french ? "Durée totale" : "Total Duration" }
    static var remSleep: String { lang == .french ? "Sommeil REM" : "REM Sleep" }
    static var deepSleep: String { lang == .french ? "Sommeil profond" : "Deep Sleep" }
    static var lightSleep: String { lang == .french ? "Sommeil léger" : "Light Sleep" }
    static var restingHR: String { lang == .french ? "FC repos" : "Resting HR" }
    static var activeCalories: String { lang == .french ? "Calories actives" : "Active Calories" }
    static var exercise: String { lang == .french ? "Exercice" : "Exercise" }
    static var steps: String { lang == .french ? "Pas" : "Steps" }
    static var distance: String { lang == .french ? "Distance" : "Distance" }
    static var temperature: String { lang == .french ? "Température" : "Temperature" }
    static var pressure: String { lang == .french ? "Pression" : "Pressure" }
    static var humidity: String { lang == .french ? "Humidité" : "Humidity" }
    static var menstrualFlow: String { lang == .french ? "Flux menstruel" : "Menstrual Flow" }
    static var flowNone: String { lang == .french ? "Aucun" : "None" }
    static var flowUnspecified: String { lang == .french ? "Non précisé" : "Unspecified" }
    static var flowLight: String { lang == .french ? "Léger" : "Light" }
    static var flowMedium: String { lang == .french ? "Moyen" : "Medium" }
    static var flowHeavy: String { lang == .french ? "Abondant" : "Heavy" }
    static var valence: String { lang == .french ? "Valence" : "Valence" }

    static func scoreLabel(_ value: Double) -> String {
        lang == .french ? String(format: "Score : %+.2f", value) : String(format: "Score: %+.2f", value)
    }

    // Mood labels
    static var moodVeryPositive: String { lang == .french ? "Très positif" : "Very Positive" }
    static var moodPositive: String { lang == .french ? "Positif" : "Positive" }
    static var moodNeutral: String { lang == .french ? "Neutre" : "Neutral" }
    static var moodNegative: String { lang == .french ? "Négatif" : "Negative" }
    static var moodVeryNegative: String { lang == .french ? "Très négatif" : "Very Negative" }

    static var disclaimerHome: String {
        lang == .french
            ? "⚠️ Ces données sont indicatives. Elles ne remplacent pas un avis médical professionnel."
            : "⚠️ This data is for informational purposes only. It does not replace professional medical advice."
    }

    // MARK: Log
    static var logTitle: String { lang == .french ? "Saisie" : "Log" }
    static var addCategory: String { lang == .french ? "Ajouter une catégorie" : "Add a category" }
    static var dayNote: String { lang == .french ? "Note du jour" : "Day note" }
    static var dayNotePlaceholder: String { lang == .french ? "Note libre pour cette journée…" : "Free note for this day…" }
    static var yes: String { lang == .french ? "Oui" : "Yes" }
    static var no: String { lang == .french ? "Non" : "No" }

    // MARK: Trends
    static var trendsTitle: String { lang == .french ? "Tendances" : "Trends" }
    static var close: String { lang == .french ? "Fermer" : "Close" }

    // MARK: Settings
    static var settingsTitle: String { lang == .french ? "Réglages" : "Settings" }
    static var sectionTracking: String { lang == .french ? "Suivi" : "Tracking" }
    static var activeCategories: String { lang == .french ? "Catégories actives" : "Active categories" }
    static func archivedCategoriesCount(_ count: Int) -> String {
        lang == .french ? "Catégories archivées (\(count))" : "Archived categories (\(count))"
    }
    static var sectionDataSources: String { lang == .french ? "Sources de données" : "Data Sources" }
    static var healthKitWeather: String { lang == .french ? "HealthKit & Météo" : "HealthKit & Weather" }
    static var sectionDailyReminder: String { lang == .french ? "Rappel quotidien" : "Daily Reminder" }
    static var enableReminder: String { lang == .french ? "Activer le rappel" : "Enable reminder" }
    static var reminderTime: String { lang == .french ? "Heure" : "Time" }
    static var sectionLanguage: String { lang == .french ? "Langue" : "Language" }
    static var sectionData: String { lang == .french ? "Données" : "Data" }
    static var exportCSV: String { lang == .french ? "Exporter en CSV" : "Export as CSV" }
    static var exportEmptyTitle: String { lang == .french ? "Aucune donnée" : "No Data" }
    static var exportEmptyMessage: String {
        lang == .french
            ? "Aucune donnée à exporter. Commence à logger pour générer un export."
            : "No data to export yet. Start logging to generate an export."
    }
    static var ok: String { "OK" }
    static var removeAllData: String { lang == .french ? "Supprimer toutes les données" : "Remove all data" }
    static var removeAllDataConfirmTitle: String { lang == .french ? "Supprimer toutes les données ?" : "Remove all data?" }
    static var removeAllDataConfirmMessage: String { lang == .french ? "Cette action est irréversible. Toutes vos données de santé, entrées et catégories personnalisées seront supprimées." : "This action cannot be undone. All your health data, entries, and custom categories will be deleted." }
    static var delete: String { lang == .french ? "Supprimer" : "Delete" }
    static var sectionAbout: String { lang == .french ? "À propos" : "About" }
    static var version: String { lang == .french ? "Version" : "Version" }
    static var build: String { lang == .french ? "Build" : "Build" }
    static var aboutDescription: String {
        lang == .french
            ? "Développé pour Marie-Claude. Aucune donnée envoyée en dehors de l'appareil."
            : "Built for Marie-Claude. No data sent outside the device."
    }
    static var reactivate: String { lang == .french ? "Réactiver" : "Reactivate" }
    static var archives: String { lang == .french ? "Archives" : "Archives" }

    // MARK: Categories
    static var categoriesTitle: String { lang == .french ? "Catégories" : "Categories" }
    static func activeCategoriesCount(_ count: Int) -> String {
        lang == .french ? "Actives (\(count) / 15)" : "Active (\(count) / 15)"
    }
    static var reorderHint: String {
        lang == .french
            ? "Glissez pour réordonner. Balayez à gauche pour archiver."
            : "Drag to reorder. Swipe left to archive."
    }

    // Category editor
    static var nameAndIcon: String { lang == .french ? "Nom et icône" : "Name and icon" }
    static var categoryNamePlaceholder: String { lang == .french ? "Nom de la catégorie" : "Category name" }
    static var dataTypeSection: String { lang == .french ? "Type de donnée" : "Data type" }
    static var archiveCategory: String { lang == .french ? "Archiver cette catégorie" : "Archive this category" }
    static var editCategory: String { lang == .french ? "Modifier" : "Edit" }
    static var newCategory: String { lang == .french ? "Nouvelle catégorie" : "New Category" }
    static var cancel: String { lang == .french ? "Annuler" : "Cancel" }
    static var create: String { lang == .french ? "Créer" : "Create" }

    // Data type labels
    static var dataTypeCounter: String { lang == .french ? "Compteur" : "Counter" }
    static var dataTypeBoolean: String { lang == .french ? "Oui / Non" : "Yes / No" }
    static var dataTypeScale: String { lang == .french ? "Échelle 1–5" : "Scale 1–5" }

    // Type hints
    static var hintCounter: String { lang == .french ? "Ex : 2 cafés, 3 verres d'eau…" : "E.g.: 2 coffees, 3 glasses of water…" }
    static var hintBoolean: String { lang == .french ? "Ex : A mangé du gluten ? Oui / Non" : "E.g.: Had gluten? Yes / No" }
    static var hintScale: String { lang == .french ? "Ex : Stress de 1 (très bas) à 5 (très élevé)" : "E.g.: Stress from 1 (very low) to 5 (very high)" }

    // MARK: Data Sources
    static var dataSourcesTitle: String { lang == .french ? "Sources de données" : "Data Sources" }
    static var appleHealth: String { lang == .french ? "Apple Santé" : "Apple Health" }
    static var authorized: String { lang == .french ? "Autorisé" : "Authorized" }
    static var notAuthorized: String { lang == .french ? "Non autorisé" : "Not authorized" }
    static var updatePermissions: String { lang == .french ? "Mettre à jour les permissions" : "Update permissions" }
    static var authorizeAccess: String { lang == .french ? "Autoriser l'accès" : "Authorize access" }
    static var openAppleHealth: String { lang == .french ? "Ouvrir Santé" : "Open Apple Health" }
    static var weatherSection: String { lang == .french ? "Météo" : "Weather" }
    static var authorizeLocation: String { lang == .french ? "Autoriser la localisation" : "Authorize location" }
    static var latestWeatherData: String { lang == .french ? "Dernières données météo :" : "Latest weather data:" }
    static var aboutSection: String { lang == .french ? "À propos" : "About" }
    static var weatherAttributionLabel: String {
        lang == .french ? "Données météo fournies par" : "Weather data provided by"
    }

    // Location statuses
    static var locationNotDetermined: String { lang == .french ? "Non demandé" : "Not requested" }
    static var locationRestricted: String { lang == .french ? "Restreint" : "Restricted" }
    static var locationDenied: String { lang == .french ? "Refusé" : "Denied" }
    static var locationAuthorizedAlways: String { lang == .french ? "Autorisé (toujours)" : "Authorized (always)" }
    static var locationAuthorized: String { lang == .french ? "Autorisé" : "Authorized" }
    static var locationUnknown: String { lang == .french ? "Inconnu" : "Unknown" }

    // MARK: Onboarding
    static var welcomeTitle: String { lang == .french ? "Bienvenue, Marie-Claude" : "Welcome, Marie-Claude" }
    static var welcomeDescription: String {
        lang == .french
            ? "Cette app t'aide à comprendre ce qui influence ta santé, en croisant automatiquement tes données Apple Watch avec tes habitudes quotidiennes."
            : "This app helps you understand what influences your health, by automatically cross-referencing your Apple Watch data with your daily habits."
    }
    static var startButton: String { lang == .french ? "Commencer" : "Get Started" }
    static var healthDataTitle: String { lang == .french ? "Données de santé" : "Health Data" }
    static var healthDataDescription: String {
        lang == .french
            ? "MC Santé lit ton sommeil, ta fréquence cardiaque, ton activité et ton humeur depuis Apple Santé. Tes données ne quittent jamais ton iPhone."
            : "MC Santé reads your sleep, heart rate, activity and mood from Apple Health. Your data never leaves your iPhone."
    }
    static var maybeLater: String { lang == .french ? "Peut-être plus tard" : "Maybe later" }
    static var authorizeAccessButton: String { lang == .french ? "Autoriser l'accès" : "Authorize Access" }
    static var weatherTitle: String { lang == .french ? "Données météo" : "Weather Data" }
    static var weatherDescription: String {
        lang == .french
            ? "MC Santé utilise ta position pour récupérer la pression atmosphérique et la température. Idéal pour détecter si la météo influence ton énergie ou tes migraines."
            : "MC Santé uses your location to get atmospheric pressure and temperature. Ideal for detecting if weather influences your energy or migraines."
    }
    static var skip: String { lang == .french ? "Passer" : "Skip" }
    static var authorizeLocationButton: String { lang == .french ? "Autoriser la localisation" : "Authorize Location" }

    // MARK: Notifications
    static var notificationTitle: String { "MC Santé" }
    static var notificationBody: String {
        lang == .french
            ? "Comment s'est passée ta journée ? 30 secondes pour logger."
            : "How was your day? 30 seconds to log."
    }
    static var notificationDescription: String {
        lang == .french
            ? "Reçois un rappel quotidien pour ne pas oublier de logger ta journée."
            : "Get a daily reminder so you never forget to log your day."
    }
    static var authorizeNotificationsButton: String {
        lang == .french ? "Activer les notifications" : "Enable Notifications"
    }

    // MARK: Formatting helpers
    static func booleanDisplay(_ value: Double) -> String {
        value == 1 ? yes : no
    }

    // Time window picker
    static var windowPickerLabel: String { lang == .french ? "Fenêtre" : "Window" }
    static func daysSuffix(_ days: Int) -> String {
        lang == .french ? "\(days) j" : "\(days) d"
    }

    // MARK: Emoji Picker
    static var chooseEmoji: String { lang == .french ? "Choisir un emoji" : "Choose an emoji" }
    static var searchEmoji: String { lang == .french ? "Rechercher un emoji…" : "Search for an emoji…" }
    static var emojiRecents: String { lang == .french ? "Récents" : "Recents" }
    static var emojiHealth: String { lang == .french ? "Santé" : "Health" }
    static var emojiFood: String { lang == .french ? "Alimentation" : "Food" }
    static var emojiActivity: String { lang == .french ? "Activité" : "Activity" }
    static var emojiEmotions: String { lang == .french ? "Émotions" : "Emotions" }
    static var emojiNature: String { lang == .french ? "Nature" : "Nature" }
    static var emojiMisc: String { lang == .french ? "Divers" : "Misc" }
}
