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
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.computingCorrelations)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.hasSufficientData {
                    insufficientDataView
                } else {
                    correlationList
                }
            }
            .navigationTitle(L10n.trendsTitle)
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
                    Text(L10n.noSignificantCorrelation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            } else {
                Section(L10n.correlationsCount(viewModel.filteredCorrelations.count)) {
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
                Text(L10n.disclaimerTrends(viewModel.selectedWindow))
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
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                Text(L10n.learningInProgress)
                    .font(.title3.weight(.semibold))
                Text(L10n.insufficientDataMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if viewModel.daysUntilReady > 0 {
                    Text(L10n.daysUntilReady(viewModel.daysUntilReady))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }

            ProgressView(value: Double(max(0, 7 - viewModel.daysUntilReady)), total: 7)
                .tint(Color.accentColor)
                .padding(.horizontal, 48)
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
                            Text(L10n.visualization)
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
                    Button(L10n.close) { selectedCorrelation = nil }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func metaSection(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.details)
                .font(.headline)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(result.pearsonR > 0 ? Color.green : Color.red)
                        .frame(width: abs(result.pearsonR) * geo.size.width, height: 8)
                }
            }
            .frame(height: 8)

            infoRow(L10n.coefficientR, value: String(format: "%+.4f", result.pearsonR))
            infoRow(L10n.strengthLabel, value: result.strength.localizedLabel)
            infoRow(L10n.sample, value: L10n.sampleDays(result.sampleSize))
            infoRow(L10n.lag, value: result.lagDays == 0 ? L10n.sameDay : L10n.lagDays(result.lagDays))
            infoRow(L10n.window, value: L10n.windowDays(result.windowDays))
            infoRow(L10n.computedOn, value: result.generatedAt.shortDateString)
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
