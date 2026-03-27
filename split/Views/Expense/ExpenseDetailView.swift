import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var expense: SplitExpense
    let trip: SplitTrip
    var onExpenseUpdated: (() -> Void)?
    @State private var showingEditExpense = false
    @State private var showingDeleteAlert = false
    @State private var showingFullScreenImage = false
    @State private var selectedImageIndex: Int = 0
    @State private var cachedImages: [UIImage] = []

    var hasItemAssignments: Bool {
        !expense.items.isEmpty && expense.items.contains { $0.assignedParticipantIds != nil && !($0.assignedParticipantIds!.isEmpty) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expense.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let sub = expense.subtitle, !sub.isEmpty {
                            Text(sub)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let addr = expense.address, !addr.isEmpty {
                            Text(addr)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let category = expense.staticCategory {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                Text(category.localizedName)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(expense.amount, code: expense.currencyCode))
                            .font(.title)
                            .fontWeight(.bold)
                        if expense.currencyCode != trip.baseCurrencyCode {
                            Text("≈ \(formatCurrency(expense.amountInBaseCurrency(from: trip), code: trip.baseCurrencyCode))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("details") {
                LabeledContent("date", value: formatDate(expense.date))
                LabeledContent("time", value: formatTime(expense.date))

                if let payer = expense.paidBy(from: trip) {
                    LabeledContent("paidBy") {
                        Text(payer.name)
                    }
                }

                LabeledContent("orderedBy") {
                    if hasItemAssignments {
                        HStack(spacing: 4) {
                            Text("orderBy.byItems")
                            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        }
                        .foregroundColor(.secondary)
                    } else {
                        Text("splitMethod.even")
                            .foregroundColor(.secondary)
                    }
                }

                if expense.currencyCode != trip.baseCurrencyCode,
                   let rate = trip.exchangeRate[expense.currencyCode] {
                    LabeledContent("exchangeRate") {
                        Text("1 \(expense.currencyCode) = \(String(format: "%.4f", rate)) \(trip.baseCurrencyCode)")
                    }
                }

            }

            if !expense.items.isEmpty {
                Section("scannedItems") {
                    ForEach(expense.items.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                if item.quantity > 1 {
                                    Text("\(Int(item.quantity))")
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                Spacer()
                                if let price = item.totalPrice ?? item.unitPrice {
                                    Text(formatCurrency(price, code: expense.currencyCode))
                                        .foregroundColor(.secondary)
                                }
                            }
                            if let ids = item.assignedParticipantIds, !ids.isEmpty {
                                let names = trip.participants.filter { ids.contains($0.id) }.map { $0.name }
                                if !names.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.crop.circle")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(names.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if !expense.receiptImagePaths.isEmpty {
                Section("receiptPhoto") {
                    if cachedImages.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(cachedImages.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImageIndex = index
                                    showingFullScreenImage = true
                                }
                        }
                    }
                }
                .task {
                    await loadReceiptImages()
                }
            }

            if !expense.notes.isEmpty {
                Section("notes") {
                    Text(expense.notes)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("expenseDetails")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingEditExpense = true }) {
                        Label("edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditExpense, onDismiss: {
            // Reload expense after edit
            Task {
                if let expenses = try? await SplitService.shared.fetchExpenses(tripId: trip.id),
                   let updated = expenses.first(where: { $0.id == expense.id }) {
                    expense = updated
                    cachedImages = []
                    onExpenseUpdated?()
                }
            }
        }) {
            ExpenseEditView(trip: trip, mode: .edit(expense))
        }
        .alert("deleteExpense.confirmation", isPresented: $showingDeleteAlert) {
            Button("cancel", role: .cancel) {}
            Button("delete", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("cannotUndo")
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if selectedImageIndex < cachedImages.count {
                FullScreenImageView(image: cachedImages[selectedImageIndex])
            }
        }
    }

    private func formatCurrency(_ amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "en_US")
        if amount == amount.rounded(.towardZero) {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = trip.timeZone
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = trip.timeZone
        return formatter.string(from: date)
    }

    private func loadReceiptImages() async {
        var loaded: [UIImage] = []
        for urlString in expense.receiptImagePaths {
            if let image = await ImageCacheService.shared.loadImage(for: urlString) {
                loaded.append(image)
            }
        }
        cachedImages = loaded
    }

    private func deleteExpense() {
        Task {
            do {
                try await SplitService.shared.deleteExpense(id: expense.id)
                onExpenseUpdated?()
                dismiss()
            } catch {
                print("Failed to delete expense: \(error)")
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: SplitExpense
    let trip: SplitTrip
    let baseCurrencyCode: String

    var body: some View {
        HStack {
            if let category = expense.staticCategory {
                Image(systemName: category.icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
            } else {
                Image(systemName: "circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)

                HStack {
                    Text(formatTime(expense.date))
                    if let payer = expense.paidBy(from: trip), !payer.isMe {
                        Text("• \(payer.name)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if expense.currencyCode != baseCurrencyCode {
                    Text(formatCurrency(expense.amount, code: expense.currencyCode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(formatCurrency(expense.amountInBaseCurrency(from: trip), code: baseCurrencyCode))
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "en_US")
        if amount == amount.rounded(.towardZero) {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = trip.timeZone
        return formatter.string(from: date)
    }
}

// MARK: - 全螢幕圖片檢視
struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = lastScale * value.magnification
                        }
                        .onEnded { _ in
                            lastScale = max(scale, 1.0)
                            scale = max(scale, 1.0)
                            if scale == 1.0 {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 3.0
                            lastScale = 3.0
                        }
                    }
                }
        }
        .onTapGesture {
            dismiss()
        }
        .statusBarHidden()
    }
}

#Preview {
    NavigationStack {
        ExpenseDetailView(
            expense: SplitExpense(tripId: UUID(), title: "午餐", amount: 500),
            trip: SplitTrip(name: "測試行程")
        )
    }
}
