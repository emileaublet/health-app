import SwiftUI

struct TrendsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                VStack(spacing: 8) {
                    Text(L10n.trendsTitle)
                        .font(.title2.weight(.semibold))
                    Text(LocalizationManager.shared.language == .french
                         ? "Bientôt disponible"
                         : "Coming soon")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(L10n.trendsTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
