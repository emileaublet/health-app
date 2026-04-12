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
                Section("Suivi") {
                    NavigationLink {
                        CategoryListView()
                    } label: {
                        Label("Catégories actives", systemImage: "list.bullet")
                    }

                    if !archivedCategories.isEmpty {
                        NavigationLink {
                            archivedCategoriesView
                        } label: {
                            Label(
                                "Catégories archivées (\(archivedCategories.count))",
                                systemImage: "archivebox"
                            )
                        }
                    }
                }

                // MARK: Sources
                Section("Sources de données") {
                    NavigationLink {
                        DataSourcesView(healthKit: healthKit, weather: weather)
                    } label: {
                        Label("HealthKit & Météo", systemImage: "iphone.and.arrow.forward.outward")
                    }
                }

                // MARK: Rappel
                Section("Rappel quotidien") {
                    Toggle("Activer le rappel", isOn: $viewModel.reminderEnabled)
                        .onChange(of: viewModel.reminderEnabled) { _, _ in
                            Task { await viewModel.applyReminderSettings() }
                        }

                    if viewModel.reminderEnabled {
                        DatePicker(
                            "Heure",
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: viewModel.reminderHour) { _, _ in
                            Task { await viewModel.applyReminderSettings() }
                        }
                    }
                }

                // MARK: Export
                Section("Données") {
                    Button {
                        exportURL = viewModel.exportCSV(context: modelContext)
                        if exportURL != nil { showingExportSheet = true }
                    } label: {
                        Label("Exporter en CSV", systemImage: "square.and.arrow.up")
                    }
                    .foregroundStyle(.accentColor)
                }

                // MARK: À propos
                Section("À propos") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                    Text("Développé pour Marie-Claude. Aucune donnée envoyée en dehors de l'appareil.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
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
                    Button("Réactiver") {
                        viewModel.reactivate(category)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.accentColor)
                }
            }
        }
        .navigationTitle("Archives")
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
