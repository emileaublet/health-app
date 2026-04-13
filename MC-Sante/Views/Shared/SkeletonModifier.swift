import SwiftUI

// MARK: - Skeleton card (matches MetricCard layout)

struct SkeletonCard: View {
    var height: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 28, height: 28)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 72, height: 22)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 6)
        }
        .padding(14)
        .frame(minHeight: height)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Skeleton section (matches a typical section with header + 2-column grid)

struct SkeletonSection: View {
    var icon: String = "circle"
    var cardCount: Int = 2
    var columns: Int = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Color(.systemGray4))
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 14)
            }
    
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: columns),
                spacing: 10
            ) {
                ForEach(0..<cardCount, id: \.self) { _ in
                    SkeletonCard()
                }
            }
        }
    }
}

// MARK: - Skeleton row (for Log screen category rows)

struct SkeletonRow: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 14)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
