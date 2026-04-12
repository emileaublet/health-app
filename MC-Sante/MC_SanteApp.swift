import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct MC_SanteApp: App {
    // MARK: Services (singleton instances shared across the app)
    @State private var healthKit      = HealthKitService()
    @State private var weatherService = WeatherDataService()
    @State private var notifications  = NotificationService()
    @State private var snapshotService: SnapshotService

    init() {
        let hk = HealthKitService()
        let ws = WeatherDataService()
        _healthKit       = State(initialValue: hk)
        _weatherService  = State(initialValue: ws)
        _notifications   = State(initialValue: NotificationService())
        _snapshotService = State(initialValue: SnapshotService(healthKit: hk, weather: ws))

        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.mcsante.snapshot",
            using: nil
        ) { task in
            // Handled in AppDelegate or SwiftUI background task modifier
            task.setTaskCompleted(success: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                healthKit: healthKit,
                weather: weatherService,
                notifications: notifications,
                snapshotService: snapshotService
            )
            .task {
                // Seed default categories on first launch
                // Note: modelContext not available here; done inside ContentView via onAppear
            }
        }
        .modelContainer(for: [
            TrackingCategory.self,
            DailyEntry.self,
            DailySnapshot.self,
            CorrelationResult.self,
        ], inMemory: false) { result in
            if case .success(let container) = result {
                // Seed default categories if needed
                let context = container.mainContext
                SeedDataService.seedIfNeeded(context: context)
            }
        }
        .backgroundTask(.appRefresh("com.mcsante.snapshot")) {
            // Daily background snapshot — runs once per day via BackgroundTasks
            // Services are not available in background tasks via @State,
            // so we create ephemeral instances here
            let hk   = HealthKitService()
            let ws   = WeatherDataService()
            let svc  = SnapshotService(healthKit: hk, weather: ws)
            guard let container = try? ModelContainer(for: DailySnapshot.self, DailyEntry.self, TrackingCategory.self, CorrelationResult.self)
            else { return }
            let ctx = ModelContext(container)
            await svc.buildSnapshot(for: .now, context: ctx)
            scheduleNextBackgroundRefresh()
        }
    }

    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.mcsante.snapshot")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 24, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }
}
