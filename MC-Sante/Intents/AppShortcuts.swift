import AppIntents

struct MCHealthShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogCounterIntent(),
            phrases: [
                "Log a counter in \(.applicationName)",
                "Add a metric in \(.applicationName)",
            ],
            shortTitle: "Log Counter",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: LogBooleanIntent(),
            phrases: [
                "Log a yes or no in \(.applicationName)",
                "Toggle a metric in \(.applicationName)",
            ],
            shortTitle: "Log Yes/No",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: LogScaleIntent(),
            phrases: [
                "Rate a metric in \(.applicationName)",
                "Log a scale in \(.applicationName)",
            ],
            shortTitle: "Log Scale",
            systemImageName: "slider.horizontal.3"
        )
    }
}
