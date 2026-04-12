import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<TrackingCategory> { $0.isActive == true },
        sort: [SortDescriptor(\TrackingCategory.sortOrder)]
    )
    private var activeCategories: [TrackingCategory]

    @State private var viewModel = LogViewModel()
    @State private var showingAddSheet = false
    @State private var editingCategory: TrackingCategory?

    var body: some View {
        List {
            Section {
                ForEach(activeCategories) { category in
                    categoryRow(category)
                }
                .onMove { from, to in
                    var reordered = activeCategories
                    reordered.move(fromOffsets: from, toOffset: to)
                    viewModel.updateSortOrder(reordered)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.archiveCategory(activeCategories[index])
                    }
                }
            } header: {
                Text("Actives (\(activeCategories.count) / 15)")
            } footer: {
                Text("Glissez pour réordonner. Balayez à gauche pour archiver.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Catégories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(activeCategories.count >= 15)
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryEditorSheet(viewModel: viewModel)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(viewModel: viewModel, existing: category)
        }
        .onAppear {
            viewModel.configure(context: modelContext)
        }
    }

    private func categoryRow(_ category: TrackingCategory) -> some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.callout.weight(.medium))
                Text(category.dataType.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if category.isBuiltIn {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !category.isBuiltIn { editingCategory = category }
        }
    }
}
