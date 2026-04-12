import SwiftUI
import SwiftData

struct TrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TrendsViewModel()
    @State private var selectedCorrelation: CorrelationResult?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isComputing {
                    ProgressView("Calcul des corrélations…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.hasSufficientData {
                    insufficientDataView
                } else {
                    correlationList
                }
            }
            .navigationTitle("Tendances")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.recompute(context: modelContext) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $selectedCorrelation) { result in
                correlationDetailSheet(result)
            }
        }
        .task {
            await viewModel.recompute(context: modelContext)
        }
        .onChange(of: viewModel.selectedWindow) { _, _ in
            Task { await viewModel.recompute(context: modelContext) }
        }
    }

    // MARK: Correlation list

    private var correlationList: some View {
        List {
            Section {
                TimeWindowPicker(selectedDays: $viewModel.selectedWindow)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if viewModel.filteredCorrelations.isEmpty {
                Section {
                    Text("Aucune corrélation significative détectée sur cette fenêtre. Continue à logger !")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            } else {
                Section("Corrélations (\(viewModel.filteredCorrelations.count))") {
                    ForEach(viewModel.filteredCorrelations) { result in
                        Button {
                            selectedCorrelation = result
                        } label: {
                            CorrelationRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Text("⚠️ Ces corrélations sont statistiques et ne prouvent pas de causalité. Elles sont basées sur les données des \(viewModel.selectedWindow) derniers jours. Consultez un professionnel de santé pour toute décision médicale.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.recompute(context: modelContext)
        }
    }

    // MARK: Insufficient data

    private var insufficientDataView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("En cours d'apprentissage…")
                    .font(.title3.weight(.semibold))
                Text("Il faut au moins 7 jours de données pour calculer les premières corrélations.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if viewModel.daysUntilReady > 0 {
                    Text("Encore \(viewModel.daysUntilReady) jour\(viewModel.daysUntilReady > 1 ? "s" : "") !")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Detail sheet

    private func correlationDetailSheet(_ result: CorrelationResult) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary
                    InsightCard(insight: result)

                    // Chart
                    if let series = viewModel.seriesFor(result: result) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Visualisation")
                                .font(.headline)
                            CorrelationChartView(
                                result: result,
                                seriesA: series.a,
                                seriesB: series.b
                            )
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Metadata
                    metaSection(result)
                }
                .padding()
            }
            .navigationTitle("\(result.emojiA) ↔ \(result.emojiB)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { selectedCorrelation = nil }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func metaSection(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Détails")
                .font(.headline)

            infoRow("Coefficient r", value: String(format: "%+.4f", result.pearsonR))
            infoRow("Force", value: result.strength.label)
            infoRow("Échantillon", value: "\(result.sampleSize) jours")
            infoRow("Décalage", value: result.lagDays == 0 ? "Même jour" : "\(result.lagDays) j")
            infoRow("Fenêtre", value: "\(result.windowDays) jours")
            infoRow("Calculé le", value: result.generatedAt.shortDateString)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.weight(.medium))
                .monospacedDigit()
        }
    }
}
