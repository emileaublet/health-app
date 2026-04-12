import SwiftData
import Foundation

struct SeedDataService {

    /// Insère les catégories par défaut si elles n'existent pas encore.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, cat) in TrackingCategory.defaultCategories.enumerated() {
            let category = TrackingCategory(
                name: cat.0,
                emoji: cat.1,
                dataType: cat.2,
                isBuiltIn: true,
                sortOrder: index
            )
            context.insert(category)
        }
        try? context.save()
    }
}
