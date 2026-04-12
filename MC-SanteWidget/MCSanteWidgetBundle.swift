import WidgetKit
import SwiftUI

// MARK: - Widget definitions

struct MCSanteSmallWidget: Widget {
    let kind: String = "MCSanteSmallWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RefreshWidgetIntent.self,
            provider: MCSanteProvider()
        ) { entry in
            MCSanteSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("MC Santé — Résumé")
        .description("Sommeil, cafés et exercice d'aujourd'hui.")
        .supportedFamilies([.systemSmall])
    }
}

struct MCSanteMediumWidget: Widget {
    let kind: String = "MCSanteMediumWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RefreshWidgetIntent.self,
            provider: MCSanteProvider()
        ) { entry in
            MCSanteMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("MC Santé — Insight du jour")
        .description("Métriques + dernière corrélation détectée.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Bundle

@main
struct MCSanteWidgetBundle: WidgetBundle {
    var body: some Widget {
        MCSanteSmallWidget()
        MCSanteMediumWidget()
    }
}
