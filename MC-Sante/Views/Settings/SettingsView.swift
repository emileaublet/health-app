import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel
    let healthKit: HealthKitService
    let weather: WeatherDataService

    @Query(
        filter: #Predicate<TrackingCategory> { $0.isActive == false },
        sort: [SortDescriptor(\TrackingCategory.name)]
    )
    private var archivedCategories: [TrackingCategory]

    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingDeleteConfirmation = false

    init(
        notificationService: NotificationService,
        healthKit: HealthKitService,
        weather: WeatherDataService
    ) {
        _viewModel = State(wrappedValue: SettingsViewModel(notificationService: notificationService))
        self.healthKit = healthKit
        self.weather = weather
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Catégories
                Section(L10n.sectionTracking) {
                    NavigationLink {
                        CategoryListView()
                    } label: {
                        Label(L10n.activeCategories, systemImage: "list.bullet")
                    }

                    if !archivedCategories.isEmpty {
                        NavigationLink {
                            archivedCategoriesView
                        } label: {
                            Label(
                                L10n.archivedCategoriesCount(archivedCategories.count),
                                systemImage: "archivebox"
                            )
                        }
                    }
                }

                // MARK: Sources
                Section(L10n.sectionDataSources) {
                    NavigationLink {
                        DataSourcesView(healthKit: healthKit, weather: weather)
                    } label: {
                        Label(L10n.healthKitWeather, systemImage: "iphone.and.arrow.forward.outward")
                    }
                }

                // MARK: Rappel
                Section(L10n.sectionDailyReminder) {
                    Toggle(L10n.enableReminder, isOn: $viewModel.reminderEnabled)
                        .onChange(of: viewModel.reminderEnabled) { _, _ in
                            Task { await viewModel.applyReminderSettings() }
                        }

                    if viewModel.reminderEnabled {
                        DatePicker(
                            L10n.reminderTime,
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: viewModel.reminderHour) { _, _ in
                            Task { await viewModel.applyReminderSettings() }
                        }
                    }
                }

                // MARK: Langue
                Section(L10n.sectionLanguage) {
                    Picker(L10n.sectionLanguage, selection: Binding(
                        get: { LocalizationManager.shared.language },
                        set: { LocalizationManager.shared.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: Export & Data
                Section(L10n.sectionData) {
                    Button {
                        exportURL = viewModel.exportCSV(context: modelContext)
                        if exportURL != nil { showingExportSheet = true }
                    } label: {
                        Label(L10n.exportCSV, systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(Color.accentColor)

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(L10n.removeAllData, systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                // MARK: À propos
                Section(L10n.sectionAbout) {
                    LabeledContent(L10n.version, value: appVersion)
                    LabeledContent(L10n.build, value: buildNumber)
                    Text(L10n.aboutDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert(L10n.removeAllDataConfirmTitle, isPresented: $showingDeleteConfirmation) {
                Button(L10n.delete, role: .destructive) {
                    deleteAllData()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.removeAllDataConfirmMessage)
            }
        }
        .onAppear {
            viewModel.configure(context: modelContext)
        }
    }

    // MARK: Archived categories

    private var archivedCategoriesView: some View {
        List {
            ForEach(archivedCategories) { category in
                HStack {
                    Text(category.emoji)
                    Text(category.name)
                    Spacer()
                    Button(L10n.reactivate) {
                        viewModel.reactivate(category)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle(L10n.archives)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Helpers

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: viewModel.reminderHour,
                    minute: viewModel.reminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                viewModel.reminderHour   = components.hour ?? 21
                viewModel.reminderMinute = components.minute ?? 0
            }
        )
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: DailySnapshot.self)
            try modelContext.delete(model: DailyEntry.self)
            try modelContext.delete(model: CorrelationResult.self)
            try modelContext.delete(model: TrackingCategory.self)
            try modelContext.save()
            // Re-seed built-in categories
            SeedDataService.seedIfNeeded(context: modelContext)
        } catch {
            // Silently fail — non-fatal
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
