import SwiftUI

// Budget functionality is temporarily disabled (no Supabase table for budgets).
// This file is kept as a placeholder for future implementation.

struct BudgetListView: View {
    let trip: SplitTrip

    var body: some View {
        ContentUnavailableView {
            Label("noBudget", systemImage: "dollarsign.circle")
        } description: {
            Text("budget.emptyState")
        }
        .navigationTitle("budget")
    }
}

#Preview {
    NavigationStack {
        BudgetListView(trip: SplitTrip(name: "測試行程"))
    }
}
