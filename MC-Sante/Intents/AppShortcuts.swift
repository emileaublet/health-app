import AppIntents

struct MCHealthShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogCounterIntent(),
            phrases: [
                "Log \(\.$value) \(\.$categoryName) in \(.applicationName)",
                "Add \(\.$value) \(\.$categoryName) in \(.applicationName)",
                "\(\.$value) \(\.$categoryName) in \(.applicationName)",
            ],
            shortTitle: "Log Counter",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: LogBooleanIntent(),
            phrases: [
                "Log \(\.$categoryName) in \(.applicationName)",
                "Did I have \(\.$categoryName) in \(.applicationName)",
            ],
            shortTitle: "Log Yes/No",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: LogScaleIntent(),
            phrases: [
                "Rate \(\.$categoryName) \(\.$value) in \(.applicationName)",
                "Set \(\.$categoryName) to \(\.$value) in \(.applicationName)",
            ],
            shortTitle: "Log Scale",
            systemImageName: "slider.horizontal.3"
        )
    }
}
