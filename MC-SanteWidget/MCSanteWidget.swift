import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline entry

struct MCSanteEntry: TimelineEntry {
    let date: Date
    let sleepHours: Double?
    let exerciseMinutes: Double?
    let coffeCount: Int
    let insightText: String?
    let streakDays: Int
}

// MARK: - Intent

struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Rafraîchir le widget MC Santé"
    static var description: IntentDescription? = "Actualise les données affichées dans le widget."

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Provider

struct MCSanteProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> MCSanteEntry {
        MCSanteEntry(
            date: .now,
            sleepHours: 7.5,
            exerciseMinutes: 35,
            coffeCount: 2,
            insightText: "Café ↑ → Sommeil ↓",
            streakDays: 5
        )
    }

    func snapshot(for configuration: RefreshWidgetIntent, in context: Context) async -> MCSanteEntry {
        await fetchEntry()
    }

    func timeline(for configuration: RefreshWidgetIntent, in context: Context) async -> Timeline<MCSanteEntry> {
        let entry = await fetchEntry()
        // Rafraîchir une fois par jour au lendemain matin
        let nextUpdate = Calendar.current.date(
            bySettingHour: 7, minute: 0, second: 0,
            of: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: Fetch from shared SwiftData store

    private func fetchEntry() async -> MCSanteEntry {
        guard let modelContainer = try? ModelContainer(for: DailySnapshot.self, DailyEntry.self, TrackingCategory.self, CorrelationResult.self)
        else {
            return MCSanteEntry(date: .now, sleepHours: nil, exerciseMinutes: nil, coffeCount: 0, insightText: nil, streakDays: 0)
        }

        let context = ModelContext(modelContainer)
        let today = Calendar.current.startOfDay(for: .now)

        // Snapshot du jour
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        let snapshot = (try? context.fetch(snapshotDescriptor))?.first

        // Nombre de cafés
        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today }
        )
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        let cafeCategory = {
            let catDesc = FetchDescriptor<TrackingCategory>(
                predicate: #Predicate { $0.name == "Café" }
            )
            return (try? context.fetch(catDesc))?.first
        }()
        let cafeEntry = entries.first { $0.category?.id == cafeCategory?.id }

        // Top insight
        let correlationDescriptor = FetchDescriptor<CorrelationResult>()
        let correlations = (try? context.fetch(correlationDescriptor)) ?? []
        let topInsight = correlations.max(by: { abs($0.pearsonR) < abs($1.pearsonR) })

        // Streak
        let allSnapshotsDesc = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allSnapshots = (try? context.fetch(allSnapshotsDesc)) ?? []
        var streak = 0
        var checkDate = today
        for snap in allSnapshots {
            if snap.date == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }

        return MCSanteEntry(
            date: .now,
            sleepHours: snapshot?.sleepDurationHours,
            exerciseMinutes: snapshot?.exerciseMinutes,
            coffeCount: Int(cafeEntry?.value ?? 0),
            insightText: topInsight.map { "\($0.emojiA)\($0.emojiB) \($0.isPositive ? "↑" : "↓") r=\(String(format: "%.2f", $0.pearsonR))" },
            streakDays: streak
        )
    }
}

// MARK: - Small Widget

struct MCSanteSmallWidgetView: View {
    let entry: MCSanteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("MC Santé")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.streakDays > 1 {
                    Text("🔥\(entry.streakDays)")
                        .font(.caption2.weight(.medium))
                }
            }

            Spacer()

            if let sleep = entry.sleepHours {
                HStack(spacing: 4) {
                    Text("😴")
                    Text(sleep.hoursMinutesString)
                        .font(.callout.weight(.semibold))
                }
            }

            HStack(spacing: 4) {
                Text("☕")
                Text("\(entry.coffeCount)")
                    .font(.callout.weight(.semibold))
            }

            if let min = entry.exerciseMinutes, min > 0 {
                HStack(spacing: 4) {
                    Text("🏃")
                    Text("\(Int(min)) min")
                        .font(.callout.weight(.semibold))
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MCSanteMediumWidgetView: View {
    let entry: MCSanteEntry

    var body: some View {
        HStack {
            // Gauche : métriques du jour
            VStack(alignment: .leading, spacing: 8) {
                Text("Aujourd'hui")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let sleep = entry.sleepHours {
                    Label(sleep.hoursMinutesString, systemImage: "moon.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.indigo)
                }

                Label("\(entry.coffeCount) café\(entry.coffeCount > 1 ? "s" : "")", systemImage: "cup.and.saucer.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.brown)

                if let min = entry.exerciseMinutes, min > 0 {
                    Label("\(Int(min)) min", systemImage: "figure.run")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }

            Divider()

            // Droite : streak + insight
            VStack(alignment: .leading, spacing: 8) {
                if entry.streakDays > 1 {
                    Label("\(entry.streakDays) jours", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                if let insight = entry.insightText {
                    Text("✨ \(insight)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                } else {
                    Text("Continue à logger pour découvrir tes corrélations !")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
