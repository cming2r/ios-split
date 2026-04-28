import SwiftUI
import PhotosUI

enum ExpenseEditMode {
    case add
    case edit(SplitExpense)
}

struct ExpenseEditView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: SplitTrip
    let mode: ExpenseEditMode

    private let categories = StaticCategory.all
    private let currencies = StaticCurrency.all
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var address: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: String?
    @State private var currencyCode: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var paidById: UUID?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var receiptImageData: Data?
    @State private var receiptImagePaths: [String] = []
    @State private var cachedReceiptImage: UIImage?
    @State private var isSaving = false
    @State private var editableItems: [OCRItem] = []
    @State private var showItemAssignments = false
    @State private var itemAssignments: [UUID: Set<UUID>] = [:]
    @State private var showingValidationAlert = false

    var participants: [Participant] {
        trip.sortedParticipants
    }

    var itemsMismatch: Bool {
        guard !editableItems.isEmpty else { return false }
        let itemsTotal = editableItems.reduce(0.0) { $0 + ($1.totalPrice ?? $1.unitPrice ?? 0) }
        let amountValue = Double(amount) ?? 0
        return abs(amountValue - itemsTotal) > 0.01
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0 &&
        !itemsMismatch
    }

    var validationMessage: String {
        var missing: [String] = []
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            missing.append(String(localized: "item"))
        }
        if Double(amount) == nil || Double(amount)! <= 0 {
            missing.append(String(localized: "amount"))
        }
        if itemsMismatch {
            missing.append(String(localized: "itemsMismatch"))
        }
        return String(localized: "pleaseEnter") + missing.joined(separator: ", ")
    }

    var hasReceiptImage: Bool {
        receiptImageData != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("basicInfo") {
                    TextField("item", text: $title)
                    TextField("subtitle", text: $subtitle)
                    TextField("address", text: $address)
                }

                Section {
                    if editableItems.isEmpty {
                        Button {
                            editableItems.append(OCRItem(name: "", quantity: 1, unitPrice: nil, totalPrice: nil))
                        } label: {
                            Label(String(localized: "addItem"), systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }
                }

                if !editableItems.isEmpty {
                    Section {
                        ForEach($editableItems) { $item in
                            VStack(spacing: 6) {
                                HStack {
                                    TextField(String(localized: "itemName"), text: $item.name)
                                        .font(.subheadline)
                                    if let assigned = itemAssignments[item.id], !assigned.isEmpty {
                                        HStack(spacing: 2) {
                                            Image(systemName: "person.crop.circle")
                                                .font(.caption)
                                            let names = participants.filter { assigned.contains($0.id) }.map { $0.name }
                                            Text(names.joined(separator: ", "))
                                                .font(.caption2)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                }
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Text(String(localized: "qty"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("1", text: Binding(
                                            get: {
                                                if let q = item.quantity, q != 1 { return String(format: "%g", q) }
                                                return ""
                                            },
                                            set: { item.quantity = Double($0) }
                                        ))
                                        .font(.subheadline)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 40)
                                    }
                                    HStack(spacing: 4) {
                                        Text(String(localized: "unitPrice"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("0", text: Binding(
                                            get: {
                                                if let p = item.unitPrice { return String(format: "%g", p) }
                                                return ""
                                            },
                                            set: { item.unitPrice = Double($0) }
                                        ))
                                        .font(.subheadline)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                        if let unit = item.unitPrice, let total = item.totalPrice,
                                           abs(total - (item.quantity ?? 1) * unit) > 0.01 {
                                            Button {
                                                item.unitPrice = total / (item.quantity ?? 1)
                                            } label: {
                                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        if let unit = item.unitPrice, let total = item.totalPrice,
                                           abs(total - (item.quantity ?? 1) * unit) > 0.01 {
                                            Button {
                                                item.totalPrice = (item.quantity ?? 1) * unit
                                            } label: {
                                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        Text(String(localized: "totalPrice"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("0", text: Binding(
                                            get: {
                                                if let p = item.totalPrice { return String(format: "%g", p) }
                                                return ""
                                            },
                                            set: { item.totalPrice = Double($0) }
                                        ))
                                        .font(.subheadline)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                    }
                                }
                                if showItemAssignments {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(participants) { p in
                                                let isAssigned = itemAssignments[item.id]?.contains(p.id) ?? false
                                                LabelChip(
                                                    name: p.name,
                                                    isSelected: isAssigned
                                                ) {
                                                    var current = itemAssignments[item.id] ?? []
                                                    if current.contains(p.id) {
                                                        current.remove(p.id)
                                                    } else {
                                                        current.insert(p.id)
                                                    }
                                                    itemAssignments[item.id] = current
                                                }
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    HStack(spacing: 4) {
                                        Text("orderedBy")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        if let assigned = itemAssignments[item.id], !assigned.isEmpty {
                                            let names = participants.filter { assigned.contains($0.id) }.map { $0.name }
                                            Text(names.joined(separator: ", "))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("everyone")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            editableItems.remove(atOffsets: indexSet)
                        }

                        let itemsTotal = editableItems.reduce(0.0) { $0 + ($1.totalPrice ?? $1.unitPrice ?? 0) }
                        let amountValue = Double(amount) ?? 0
                        let diff = amountValue - itemsTotal
                        if abs(diff) > 0.01 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("itemsMismatch")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("itemsTotal \(formatAmount(itemsTotal)) amount \(formatAmount(amountValue)) diff \(formatAmount(diff))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    amount = String(format: "%.2f", itemsTotal)
                                } label: {
                                    Text("updateAmount")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    } header: {
                        HStack {
                            Text("scannedItems")
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showItemAssignments.toggle()
                                }
                            } label: {
                                let hasAnyAssignment = itemAssignments.values.contains { !$0.isEmpty }
                                Image(systemName: hasAnyAssignment ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                                    .foregroundColor(hasAnyAssignment ? .accentColor : .secondary)
                            }
                        }
                    } footer: {
                        Button {
                            editableItems.append(OCRItem(name: "", quantity: 1, unitPrice: nil, totalPrice: nil))
                        } label: {
                            Label(String(localized: "addItem"), systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }
                }

                Section("amount") {
                    HStack {
                        TextField("amount", text: $amount)
                            .keyboardType(.decimalPad)

                        Picker("currency", selection: $currencyCode) {
                            ForEach(currencies, id: \.code) { currency in
                                Text(currency.symbol).tag(currency.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                }

                Section("category") {
                    Picker("category", selection: $selectedCategory) {
                        Text("selectCategory").tag(nil as String?)
                        ForEach(categories) { category in
                            Label(category.localizedName, systemImage: category.icon)
                                .tag(category.id as String?)
                        }
                    }
                }

                Section("paidBy") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(participants) { participant in
                                LabelChip(
                                    name: participant.name,
                                    isSelected: paidById == participant.id
                                ) {
                                    paidById = participant.id
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

Section("details") {
                    DatePicker("date", selection: $date, displayedComponents: .date)
                    DatePicker("time", selection: $date, displayedComponents: .hourAndMinute)
                }

                Section("receiptPhoto") {
                    if let imageData = receiptImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)

                        Button(role: .destructive) {
                            receiptImageData = nil
                            selectedPhotoItem = nil
                        } label: {
                            Label("removePhoto", systemImage: "trash")
                        }
                    } else if !receiptImagePaths.isEmpty {
                        if let image = cachedReceiptImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        } else {
                            ProgressView()
                                .frame(maxHeight: 100)
                                .task {
                                    await loadCachedImage()
                                }
                        }
                    }

                    let hasImage = hasReceiptImage || !receiptImagePaths.isEmpty
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(hasImage ? String(localized: "changePhoto") : String(localized: "choosePhoto"), systemImage: "photo")
                    }
                }

                Section("notes") {
                    TextField("notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(isEditMode ? String(localized: "editExpense") : String(localized: "addExpense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if isValid {
                            saveExpense()
                        } else {
                            showingValidationAlert = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("save")
                        }
                    }
                    .disabled(isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        receiptImageData = data
                    }
                }
            }
            .alert("missingInfo", isPresented: $showingValidationAlert) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func loadExistingData() {
        currencyCode = trip.baseCurrencyCode

        if let me = participants.first(where: { $0.isMe }) {
            paidById = me.id
        }

        if case .edit(let expense) = mode {
            title = expense.title
            subtitle = expense.subtitle ?? ""
            address = expense.address ?? ""
            amount = String(expense.amount)
            selectedCategory = expense.category
            currencyCode = expense.currencyCode
            date = expense.date
            notes = expense.notes
            if let pid = expense.paidById { paidById = UUID(uuidString: pid) }
            receiptImagePaths = expense.receiptImagePaths

            // Load existing items
            editableItems = expense.items.sorted(by: { $0.sortOrder < $1.sortOrder }).map { item in
                OCRItem(
                    name: item.name,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    totalPrice: item.totalPrice
                )
            }
            // Load item assignments
            for item in expense.items {
                if let ids = item.assignedParticipantIds, !ids.isEmpty {
                    // Match by index since we created new OCRItems
                    let sortedItems = expense.items.sorted(by: { $0.sortOrder < $1.sortOrder })
                    if let idx = sortedItems.firstIndex(where: { $0.id == item.id }),
                       idx < editableItems.count {
                        itemAssignments[editableItems[idx].id] = Set(ids)
                    }
                }
            }
        }
    }

    private func loadCachedImage() async {
        guard let urlString = receiptImagePaths.first else { return }
        cachedReceiptImage = await ImageCacheService.shared.loadImage(for: urlString)
    }

    private func buildExpenseItems() -> [ExpenseItemData] {
        var expenseItems: [ExpenseItemData] = []
        for (index, item) in editableItems.enumerated() {
            guard !item.name.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let assignedIds: [UUID]? = {
                if let ids = itemAssignments[item.id], !ids.isEmpty {
                    return Array(ids)
                }
                return nil
            }()
            expenseItems.append(ExpenseItemData(
                name: item.name,
                quantity: item.quantity ?? 1,
                unitPrice: item.unitPrice,
                totalPrice: item.totalPrice,
                sortOrder: index,
                assignedParticipantIds: assignedIds
            ))
        }
        return expenseItems
    }

    @MainActor
    private func saveExpense() {
        guard !isSaving else { return }
        guard let amountValue = Double(amount) else { return }
        isSaving = true

        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)
        let expenseItems = buildExpenseItems()

        Task {
            do {
                switch mode {
                case .add:
                    var expense = SplitExpense(
                        tripId: trip.id,
                        title: title.trimmingCharacters(in: .whitespaces),
                        amount: amountValue,
                        currencyCode: currencyCode,
                        date: date,
                        category: selectedCategory ?? "other",
                        paidById: paidById?.uuidString,
                        items: expenseItems,
                        subtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle,
                        address: trimmedAddress.isEmpty ? nil : trimmedAddress,
                        receiptImagePaths: receiptImagePaths,
                        notes: notes
                    )
                    let created = try await SplitService.shared.createExpense(expense)

                    // 手動加照片：create 後上傳到 R2，再 update URL
                    if let imageData = receiptImageData, receiptImagePaths.isEmpty {
                        expense = created
                        let url = try await R2UploadService.shared.uploadReceiptImage(
                            imageData: imageData, tripId: trip.id, expenseId: expense.id
                        )
                        expense.receiptImagePaths = [url]
                        _ = try await SplitService.shared.updateExpense(expense)
                        ImageCacheService.shared.save(imageData, for: url)
                    }

                case .edit(var expense):
                    expense.title = title.trimmingCharacters(in: .whitespaces)
                    expense.subtitle = trimmedSubtitle.isEmpty ? nil : trimmedSubtitle
                    expense.address = trimmedAddress.isEmpty ? nil : trimmedAddress
                    expense.amount = amountValue
                    expense.currencyCode = currencyCode
                    expense.date = date
                    expense.notes = notes
                    expense.category = selectedCategory ?? "other"
                    expense.paidById = paidById?.uuidString
                    expense.items = expenseItems

                    // 手動換照片：上傳到 R2
                    if let imageData = receiptImageData {
                        let url = try await R2UploadService.shared.uploadReceiptImage(
                            imageData: imageData, tripId: trip.id, expenseId: expense.id
                        )
                        expense.receiptImagePaths = [url]
                        ImageCacheService.shared.save(imageData, for: url)
                    }

                    _ = try await SplitService.shared.updateExpense(expense)
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save expense: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

struct CategoryChip: View {
    let category: StaticCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                Text(category.localizedName)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct LabelChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct TagChip: View {
    let tag: StaticTag
    let isSelected: Bool
    let action: () -> Void

    private var tagColor: Color {
        Color(hex: tag.colorHex)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                Text(tag.localizedName)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? tagColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? tagColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExpenseEditView(trip: SplitTrip(name: "測試行程"), mode: .add)
}
