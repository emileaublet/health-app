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
    @State private var showingRestoreConfirmation = false
    @State private var backupAlert: BackupAlertState?

    @AppStorage("section_sleep")    private var showSleep    = true
    @AppStorage("section_cardiac")  private var showCardiac  = true
    @AppStorage("section_activity") private var showActivity = true
    @AppStorage("section_bp")       private var showBP       = true
    @AppStorage("section_cycle")    private var showCycle    = true
    @AppStorage("section_weather")  private var showWeather  = true
    @AppStorage("section_mood")     private var showMood     = true

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

                // MARK: Sections affichées
                Section(L10n.sectionDisplayed) {
                    Toggle(isOn: $showSleep) {
                        Label("😴  \(L10n.sectionSleep)", systemImage: "moon.fill")
                    }
                    Toggle(isOn: $showCardiac) {
                        Label("❤️  \(L10n.sectionCardiac)", systemImage: "heart.fill")
                    }
                    Toggle(isOn: $showActivity) {
                        Label("🏃  \(L10n.sectionActivity)", systemImage: "figure.run")
                    }
                    Toggle(isOn: $showBP) {
                        Label("🫀  \(L10n.sectionBloodPressure)", systemImage: "heart.text.clipboard")
                    }
                    Toggle(isOn: $showCycle) {
                        Label("🩸  \(L10n.sectionCycle)", systemImage: "drop.fill")
                    }
                    Toggle(isOn: $showWeather) {
                        Label("🌡️  \(L10n.sectionEnvironment)", systemImage: "cloud.sun.fill")
                    }
                    Toggle(isOn: $showMood) {
                        Label("🧠  \(L10n.sectionMood)", systemImage: "brain.head.profile")
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

                // MARK: iCloud Backup
                Section(L10n.sectionBackup) {
                    Button {
                        performBackup()
                    } label: {
                        Label(L10n.backupNow, systemImage: "icloud.and.arrow.up")
                    }
                    .foregroundStyle(Color.accentColor)

                    Button {
                        showingRestoreConfirmation = true
                    } label: {
                        Label(L10n.restoreFromBackup, systemImage: "icloud.and.arrow.down")
                    }
                    .foregroundStyle(Color.accentColor)

                    LabeledContent(L10n.lastBackup) {
                        Text(lastBackupString)
                            .foregroundStyle(.secondary)
                    }

                    if !CloudBackupService.isICloudAvailable {
                        Text(L10n.icloudUnavailable)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            .alert(L10n.restoreConfirmTitle, isPresented: $showingRestoreConfirmation) {
                Button(L10n.restore, role: .destructive) {
                    performRestore()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.restoreConfirmMessage)
            }
            .alert(
                backupAlert?.title ?? "",
                isPresented: Binding(
                    get: { backupAlert != nil },
                    set: { if !$0 { backupAlert = nil } }
                )
            ) {
                Button(L10n.ok) { backupAlert = nil }
            } message: {
                Text(backupAlert?.message ?? "")
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

    private var lastBackupString: String {
        guard let date = CloudBackupService.lastBackupDate() else { return L10n.never }
        return date.shortDateString
    }

    private func performBackup() {
        do {
            let url = try CloudBackupService.backup(context: modelContext)
            let isICloud = url.path.contains("Mobile Documents")
            backupAlert = BackupAlertState(
                title: L10n.backupSuccess,
                message: isICloud ? L10n.backupSuccessMessage : L10n.backupLocalSuccess
            )
        } catch {
            backupAlert = BackupAlertState(
                title: L10n.backupError,
                message: error.localizedDescription
            )
        }
    }

    private func performRestore() {
        do {
            let count = try CloudBackupService.restore(context: modelContext)
            backupAlert = BackupAlertState(
                title: L10n.restoreSuccess,
                message: L10n.restoredItemsCount(count)
            )
        } catch {
            backupAlert = BackupAlertState(
                title: L10n.restoreError,
                message: error.localizedDescription
            )
        }
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

// MARK: - BackupAlertState

private struct BackupAlertState {
    let title: String
    let message: String
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
