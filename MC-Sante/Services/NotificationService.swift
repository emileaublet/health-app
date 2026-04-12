import Foundation
import UserNotifications

@Observable
final class NotificationService {
    private(set) var isAuthorized = false

    // MARK: Authorization

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
        } catch {
            await MainActor.run { isAuthorized = false }
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: Schedule daily reminder

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        // Supprimer les reminders précédents
        center.removePendingNotificationRequests(withIdentifiers: ["mc.sante.daily"])

        let content = UNMutableNotificationContent()
        content.title = "MC Santé"
        content.body = "Comment s'est passée ta journée ? 30 secondes pour logger."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "mc.sante.daily",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["mc.sante.daily"])
    }
}
