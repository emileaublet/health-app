import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct MC_SanteApp: App {
    // MARK: Services — declared without default values to avoid double-init
    @State private var healthKit: HealthKitService
    @State private var weatherService: WeatherDataService
    @State private var notifications: NotificationService
    @State private var snapshotService: SnapshotService

    init() {
        let hk = HealthKitService()
        let ws = WeatherDataService()
        hk.checkAuthorizationStatus()
        _healthKit       = State(initialValue: hk)
        _weatherService  = State(initialValue: ws)
        _notifications   = State(initialValue: NotificationService())
        _snapshotService = State(initialValue: SnapshotService(healthKit: hk, weather: ws))
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
                let context = container.mainContext
                SeedDataService.seedIfNeeded(context: context)
            }
        }
        .backgroundTask(.appRefresh("com.mcsante.snapshot")) {
            // Daily background snapshot — runs once per day via BackgroundTasks
            // Services are not available in background tasks via @State,
            // so we create ephemeral instances here
            let success = await Self.performBackgroundSnapshot()
            if success {
                await Self.scheduleNextBackgroundRefresh(hoursFromNow: 24)
            } else {
                // Retry in 1 hour if snapshot failed
                await Self.scheduleNextBackgroundRefresh(hoursFromNow: 1)
            }
        }
    }

    /// Attempts to build a daily snapshot in the background. Returns true on success.
    private static func performBackgroundSnapshot() async -> Bool {
        let hk = HealthKitService()
        let ws = await WeatherDataService()
        let svc = SnapshotService(healthKit: hk, weather: ws)

        guard let container = try? ModelContainer(
            for: DailySnapshot.self, DailyEntry.self,
            TrackingCategory.self, CorrelationResult.self
        ) else { return false }

        let ctx = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)

        await svc.buildSnapshot(for: .now, context: ctx)

        // Verify the snapshot was actually saved
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        let saved = (try? ctx.fetch(descriptor))?.first
        return saved?.isComplete == true
    }

    private static func scheduleNextBackgroundRefresh(hoursFromNow: Int) {
        let request = BGAppRefreshTaskRequest(identifier: "com.mcsante.snapshot")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: hoursFromNow, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }
}
