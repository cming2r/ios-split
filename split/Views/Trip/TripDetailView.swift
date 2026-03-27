import SwiftUI
import AVFoundation

struct TripDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var quickActionManager: QuickActionManager
    @AppStorage("defaultTripId") private var defaultTripIdString: String = ""

    @State var trip: SplitTrip
    @State private var expenses: [SplitExpense] = []
    @State private var showingEditTrip = false
    @State private var showingAddExpense = false
    @State private var showingSettlement = false
    @State private var showingDeleteAlert = false
    @State private var selectedCategoryId: String?
    let switchToScanTab: () -> Void
    var onTripUpdated: (() -> Void)?

    // Camera & Photo scanning
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingCameraPermissionAlert = false
    @State private var selectedImages: [UIImage] = []
    @State private var newlySelectedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var ocrResult: OCRResult?
    @State private var showingScanResult = false
    @State private var showingScanError = false
    @State private var scanErrorMessage: String?
    @State private var showingScanPreview = false
    @State private var showingNoDataView = false

    private let categories = StaticCategory.all

    var body: some View {
        VStack(spacing: 0) {
            TripSummaryCard(trip: trip, expenses: expenses)
                .padding()

            // 類別篩選
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterChip(
                        name: String(localized: "all"),
                        icon: "list.bullet",
                        isSelected: selectedCategoryId == nil
                    ) {
                        selectedCategoryId = nil
                    }

                    ForEach(categories) { category in
                        CategoryFilterChip(
                            name: category.localizedName,
                            icon: category.icon,
                            isSelected: selectedCategoryId == category.id
                        ) {
                            selectedCategoryId = category.id
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            ExpenseListForTripView(
                trip: trip,
                expenses: expenses,
                selectedCategoryId: selectedCategoryId,
                switchToScanTab: switchToScanTab,
                onExpenseDeleted: { loadExpenses() }
            )
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingEditTrip = true }) {
                        Label("editTrip", systemImage: "pencil")
                    }
                    Divider()
                    Section("scan") {
                        Button(action: { checkCameraPermission() }) {
                            Label("takePhoto", systemImage: "camera")
                        }
                        Button(action: { showingPhotoLibrary = true }) {
                            Label("chooseFromPhotos", systemImage: "photo.on.rectangle")
                        }
                        Button(action: { showingAddExpense = true }) {
                            Label("manualEntry", systemImage: "keyboard")
                        }
                    }
                    Divider()
                    Button(action: { showingSettlement = true }) {
                        Label("settlement", systemImage: "arrow.left.arrow.right")
                    }
                    Divider()
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("deleteTrip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditTrip, onDismiss: {
            // Reload trip after edit
            Task {
                if let trips = try? await SplitService.shared.fetchTrips(),
                   let updated = trips.first(where: { $0.id == trip.id }) {
                    trip = updated
                    onTripUpdated?()
                }
            }
        }) {
            TripEditView(mode: .edit(trip))
        }
        .sheet(isPresented: $showingAddExpense, onDismiss: { loadExpenses() }) {
            ExpenseEditView(trip: trip, mode: .add)
        }
        .sheet(isPresented: $showingSettlement) {
            NavigationStack {
                SettlementView(trip: trip, expenses: expenses)
                    .navigationTitle("settlement")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("done") {
                                showingSettlement = false
                            }
                        }
                    }
            }
        }
        .alert("confirmDelete", isPresented: $showingDeleteAlert) {
            Button("cancel", role: .cancel) {}
            Button("delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("deleteTrip.message \(trip.name)")
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(capturedImage: Binding(
                get: { nil as UIImage? },
                set: { (newImage: UIImage?) in
                    if let image = newImage {
                        selectedImages = [image]
                        showingScanPreview = true
                    }
                }
            )) {
                showingPhotoLibrary = true
            }
        }
        .fullScreenCover(isPresented: $showingPhotoLibrary) {
            PhotoPicker(images: $newlySelectedImages, selectionLimit: 1)
                .onDisappear {
                    if !newlySelectedImages.isEmpty {
                        selectedImages = newlySelectedImages
                        newlySelectedImages = []
                        showingScanPreview = true
                    }
                }
        }
        .sheet(isPresented: $showingScanPreview) {
            ScanPreviewSheet(
                image: selectedImages.first,
                isProcessing: $isProcessing,
                onStartScan: { processImages() },
                onCancel: { clearScan() }
            )
            .interactiveDismissDisabled(isProcessing)
        }
        .sheet(isPresented: $showingScanResult, onDismiss: {
            clearScan()
            loadExpenses()
        }) {
            ScanResultExpenseView(
                trip: trip,
                ocrResult: ocrResult,
                imagesData: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
            )
        }
        .alert("cameraAccessRequired", isPresented: $showingCameraPermissionAlert) {
            Button("openSettings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("camera.pleaseAllowAccess")
        }
        .sheet(isPresented: $showingNoDataView, onDismiss: clearScan) {
            NoDataDetectedView(image: selectedImages.first)
        }
        .alert("error", isPresented: $showingScanError) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(scanErrorMessage ?? String(localized: "error.unknown"))
        }
        .overlay(alignment: .bottom) {
            if isProcessing {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Text("recognizing")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.9))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessing)
            }
        }
        .task {
            loadExpenses()
        }
    }

    private func loadExpenses() {
        Task {
            do {
                expenses = try await SplitService.shared.fetchExpenses(tripId: trip.id)
            } catch {
                print("Failed to load expenses: \(error)")
            }
        }
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingCameraPermissionAlert = true
        @unknown default:
            showingCameraPermissionAlert = true
        }
    }

    private func processImages() {
        guard !selectedImages.isEmpty else { return }
        withAnimation { isProcessing = true }
        ocrResult = nil

        Task {
            do {
                let geminiResult = try await GeminiOCRService.shared.recognizeReceipts(from: selectedImages, currencyCode: trip.baseCurrencyCode)
                let tripTimeZone = trip.timeZone
                let result = GeminiOCRService.shared.convertToOCRResult(geminiResult, timeZone: tripTimeZone)
                withAnimation { isProcessing = false }
                showingScanPreview = false

                if result.merchantName == nil && result.amount == nil && result.items.isEmpty {
                    ocrResult = result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingNoDataView = true
                    }
                } else {
                    ocrResult = result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingScanResult = true
                    }
                }
            } catch {
                withAnimation { isProcessing = false }
                showingScanPreview = false
                scanErrorMessage = String(localized: "error.recognitionFailed \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingScanError = true
                }
            }
        }
    }

    private func clearScan() {
        selectedImages = []
        newlySelectedImages = []
        ocrResult = nil
        scanErrorMessage = nil
    }

    private func deleteTrip() {
        Task {
            do {
                try await SplitService.shared.deleteTrip(id: trip.id)
                onTripUpdated?()
                dismiss()
            } catch {
                print("Failed to delete trip: \(error)")
            }
        }
    }
}

struct CategoryFilterChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TripSummaryCard: View {
    let trip: SplitTrip
    let expenses: [SplitExpense]
    @State private var showingDetails = false

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amountInBaseCurrency(from: trip) }
    }

    var localizedDestination: String {
        Locale.current.localizedString(forRegionCode: trip.destinationCountryCode) ?? trip.destinationCountryCode
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("totalExpenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalExpenses, code: trip.baseCurrencyCode))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("dailyAverage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let days = max(trip.duration, 1)
                    Text(formatCurrency(totalExpenses / Double(days), code: trip.baseCurrencyCode))
                        .font(.headline)
                }
            }

            Divider()

            HStack {
                if !trip.destinationCountryCode.isEmpty {
                    HStack(spacing: 4) {
                        if let country = CountryInfo.countries.first(where: { $0.regionCode == trip.destinationCountryCode }) {
                            Text(country.flag)
                        }
                        Text(localizedDestination)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Label("participants.count \(trip.participants.count)", systemImage: "person.2")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showingDetails ? -180 : 0))
                    }
                }
                .buttonStyle(.plain)
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if showingDetails {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("participants")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(trip.sortedParticipants) { participant in
                                    Text(participant.name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

Divider()

                    Label("expenses.count \(expenses.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
}

struct ExpenseListForTripView: View {
    @AppStorage("defaultTripId") private var defaultTripIdString: String = ""
    let trip: SplitTrip
    let expenses: [SplitExpense]
    let selectedCategoryId: String?
    let switchToScanTab: () -> Void
    var onExpenseDeleted: (() -> Void)?

    var filteredExpenses: [SplitExpense] {
        let sorted = expenses.sorted { $0.date > $1.date }
        if let categoryId = selectedCategoryId {
            return sorted.filter { $0.category == categoryId }
        }
        return sorted
    }

    private var groupedExpenses: [(key: String, expenses: [SplitExpense])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense -> String in
            let comps = calendar.dateComponents(in: trip.timeZone, from: expense.date)
            guard let date = calendar.date(from: comps) else { return "" }
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.timeZone = trip.timeZone
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMdEEE", options: 0, locale: Locale.current)
            return formatter.string(from: date)
        }
        return grouped
            .map { (key: $0.key, expenses: $0.value.sorted { $0.date < $1.date }) }
            .sorted { ($0.expenses.first?.date ?? .distantPast) > ($1.expenses.first?.date ?? .distantPast) }
    }

    var body: some View {
        Group {
            if expenses.isEmpty {
                ContentUnavailableView {
                    Label("noExpenses", systemImage: "receipt")
                } description: {
                    Text("expenses.emptyState")
                } actions: {
                    Button("scanReceipt") {
                        defaultTripIdString = trip.id.uuidString
                        switchToScanTab()
                    }
                }
            } else if filteredExpenses.isEmpty {
                ContentUnavailableView {
                    Label("noExpensesInCategory", systemImage: "tray")
                } description: {
                    Text("expenses.categoryEmpty")
                }
            } else {
                List {
                    ForEach(groupedExpenses, id: \.key) { group in
                        Section(header: Text(group.key)) {
                            ForEach(group.expenses) { expense in
                                NavigationLink(destination: ExpenseDetailView(
                                    expense: expense,
                                    trip: trip,
                                    onExpenseUpdated: { onExpenseDeleted?() }
                                )) {
                                    ExpenseRowView(expense: expense, trip: trip, baseCurrencyCode: trip.baseCurrencyCode)
                                }
                            }
                            .onDelete { offsets in
                                deleteExpenses(from: group.expenses, at: offsets)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func deleteExpenses(from groupExpenses: [SplitExpense], at offsets: IndexSet) {
        Task {
            for index in offsets {
                let expense = groupExpenses[index]
                try? await SplitService.shared.deleteExpense(id: expense.id)
            }
            onExpenseDeleted?()
        }
    }
}

struct SettlementView: View {
    let trip: SplitTrip
    let expenses: [SplitExpense]

    var participants: [Participant] {
        trip.sortedParticipants
    }

    var balances: [ParticipantBalance] {
        SettlementService.calculateBalances(for: expenses, trip: trip)
    }

    var transfers: [SuggestedTransfer] {
        SettlementService.calculateSuggestedTransfers(balances: balances)
    }

    var body: some View {
        Group {
            if balances.isEmpty {
                ContentUnavailableView {
                    Label("noExpenses", systemImage: "receipt")
                } description: {
                    Text("settlement.noData")
                }
            } else if transfers.isEmpty {
                ContentUnavailableView {
                    Label("allSettled", systemImage: "checkmark.circle")
                } description: {
                    Text("allAccountsSettled")
                }
            } else {
                List {
                    Section("balanceSummary") {
                        ForEach(balances) { balance in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(balance.participant.name)
                                            .font(.headline)
                                        if balance.participant.isMe {
                                            Text("me.parentheses")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text("paid \(formatCurrency(balance.totalPaid))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(formatCurrency(abs(balance.balance)))
                                        .font(.headline)
                                        .foregroundColor(balance.balance >= 0 ? .green : .red)
                                    Text(balance.balance >= 0 ? String(localized: "toReceive") : String(localized: "toPay"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Section("suggestedSettlements") {
                        ForEach(transfers) { transfer in
                            HStack {
                                Text(transfer.from.name)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                Text(transfer.to.name)
                                Spacer()
                                Text(formatCurrency(transfer.amount))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = trip.baseCurrencyCode
        formatter.locale = Locale(identifier: "en_US")
        if amount == amount.rounded(.towardZero) {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

#Preview {
    NavigationStack {
        TripDetailView(
            trip: SplitTrip(name: "日本旅行", destinationCountryCode: "JP"),
            switchToScanTab: {}
        )
    }
}
