import SwiftUI
import PhotosUI
import AVFoundation

struct ScannerView: View {
    @EnvironmentObject var quickActionManager: QuickActionManager
    @State private var trips: [SplitTrip] = []

    @State private var selectedImages: [UIImage] = []
    @State private var ocrResult: OCRResult?
    @State private var scanResultItem: ScanResultItem?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingManualEntry = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingCameraPermissionAlert = false
    @State private var showingError = false
    @State private var showingNoDataView = false
    @AppStorage("defaultTripId") private var defaultTripIdString: String = ""
    @State private var selectedTripId: UUID?
    @State private var newlySelectedImages: [UIImage] = []
    @State private var hasHandledQuickAction = false
    @State private var isLoadingTrips = true
    @State private var showingAddTrip = false
    @State private var showingSampleTrip = false

    var selectedTrip: SplitTrip? {
        trips.first { $0.id == selectedTripId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoadingTrips {
                    ProgressView()
                } else if trips.isEmpty {
                    ContentUnavailableView {
                        Label("createTripFirst", systemImage: "airplane")
                    } description: {
                        Text("createTripBeforeScanning")
                    } actions: {
                        VStack(spacing: 24) {
                            Button("newTrip") {
                                showingAddTrip = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)

                            if !SampleDataService.shared.hasDismissed {
                                Button {
                                    showingSampleTrip = true
                                } label: {
                                    Label("sample.viewExample", systemImage: "eye")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                                .tint(.orange)
                            }
                        }
                    }
                } else {
                    if !selectedImages.isEmpty {
                        VStack(spacing: 16) {
                            // 上方說明文字
                            VStack(spacing: 6) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)
                                Text("receiptPreview")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)

                            // 置中大圖預覽
                            if let image = selectedImages.first {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 220, maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                            }

                            Spacer()

                            if !isProcessing {
                                VStack(spacing: 12) {
                                    Button(action: { processImages() }) {
                                        Label("startScan", systemImage: "doc.text.magnifyingglass")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button(action: { clearScan() }) {
                                        Text("back")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)

                            Text("scanReceipt")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)

                        Spacer()

                        VStack(spacing: 12) {
                            ScanOptionButton(
                                icon: "camera.fill",
                                title: String(localized: "openCamera"),
                                subtitle: String(localized: "scanReceipt"),
                                gradient: [Color.blue, Color.blue.opacity(0.7)]
                            ) {
                                checkCameraPermission()
                            }
                            .disabled(selectedTripId == nil)

                            Button(action: { showingPhotoLibrary = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("chooseFromPhotos")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(selectedTripId == nil)

                            Button(action: { showingManualEntry = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("manualEntry")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(selectedTripId == nil)
                        }
                        .padding(.horizontal)

                        Spacer()
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .navigationTitle("receiptScan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !trips.isEmpty {
                        Menu {
                            ForEach(trips) { trip in
                                Button {
                                    selectedTripId = trip.id
                                    defaultTripIdString = trip.id.uuidString
                                } label: {
                                    HStack {
                                        Text(trip.name)
                                        if selectedTripId == trip.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if let trip = selectedTrip,
                                   let country = CountryInfo.find(byCurrencyCode: trip.baseCurrencyCode) {
                                    Text(country.flag)
                                }
                                Text(selectedTrip?.name ?? String(localized: "selectTrip"))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: 120)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .task {
                while !AuthService.shared.isReady {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                await loadTrips()
            }
            .onAppear {
                handleQuickActionIfNeeded()
            }
            .onChange(of: quickActionManager.selectedAction) { _, _ in
                handleQuickActionIfNeeded()
            }
            .onChange(of: defaultTripIdString) { _, _ in
                Task { await loadTrips() }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(capturedImage: Binding(
                    get: { nil as UIImage? },
                    set: { (newImage: UIImage?) in
                        if let image = newImage {
                            selectedImages = [image]
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
                        }
                    }
            }
            .sheet(isPresented: $showingManualEntry, onDismiss: clearScan) {
                if let trip = selectedTrip {
                    ScanResultExpenseView(
                        trip: trip,
                        ocrResult: nil,
                        imagesData: []
                    )
                }
            }
            .sheet(item: $scanResultItem, onDismiss: handleExpenseEditorDismiss) { item in
                ScanResultExpenseView(
                    trip: item.trip,
                    ocrResult: item.result,
                    imagesData: item.imagesData
                )
            }
            .sheet(isPresented: $showingNoDataView, onDismiss: clearScan) {
                NoDataDetectedView(image: selectedImages.first)
            }
            .sheet(isPresented: $showingAddTrip, onDismiss: { Task { await loadTrips() } }) {
                TripEditView(mode: .add)
            }
            .sheet(isPresented: $showingSampleTrip) {
                NavigationStack {
                    TripDetailView(
                        trip: SampleDataService.shared.sampleTrip,
                        isSample: true,
                        sampleExpenses: SampleDataService.shared.sampleExpenses,
                        switchToScanTab: {},
                        onSampleDismissed: {
                            SampleDataService.shared.dismiss()
                            showingSampleTrip = false
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("close") {
                                showingSampleTrip = false
                            }
                        }
                    }
                }
            }
            .alert("error", isPresented: $showingError) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(errorMessage ?? String(localized: "error.unknown"))
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.clear
                        VStack {
                            Spacer()
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white)
                                Text("recognizing")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.orange))
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                            .padding(.bottom, 50)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isProcessing)
                    .zIndex(1)
                }
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
        }
    }

    private func loadTrips() async {
        do {
            let allTrips = try await SplitService.shared.fetchTrips()
            // 只顯示進行中 + 結束 7 天內的旅程，但預設旅程一定包含
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let defaultId = UUID(uuidString: defaultTripIdString)
            trips = allTrips.filter { $0.endDate >= cutoff || $0.id == defaultId }
            if selectedTripId == nil || !trips.contains(where: { $0.id == selectedTripId }) {
                if let defaultId = UUID(uuidString: defaultTripIdString),
                   trips.contains(where: { $0.id == defaultId }) {
                    selectedTripId = defaultId
                } else if let firstTrip = trips.first {
                    selectedTripId = firstTrip.id
                }
            }
        } catch {
            print("Failed to load trips: \(error)")
        }
        isLoadingTrips = false
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
        errorMessage = nil
        withAnimation { isProcessing = true }
        ocrResult = nil

        Task {
            do {
                let geminiResult = try await GeminiOCRService.shared.recognizeReceipts(from: selectedImages, currencyCode: selectedTrip?.baseCurrencyCode)
                let tripTimeZone = selectedTrip?.timeZone ?? .current
                let result = GeminiOCRService.shared.convertToOCRResult(geminiResult, timeZone: tripTimeZone)
                withAnimation { isProcessing = false }

                ocrResult = result
                if result.merchantName == nil && result.amount == nil && result.items.isEmpty {
                    showingNoDataView = true
                } else if let trip = selectedTrip {
                    scanResultItem = ScanResultItem(
                        trip: trip,
                        result: result,
                        imagesData: selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
                    )
                }
            } catch {
                withAnimation { isProcessing = false }
                errorMessage = String(localized: "error.recognitionFailed \(error.localizedDescription)")
                showingError = true
            }
        }
    }

    private func handleExpenseEditorDismiss() {
        clearScan()
    }

    private func clearScan() {
        selectedImages = []
        ocrResult = nil
        scanResultItem = nil
        errorMessage = nil
        newlySelectedImages = []
    }


    private func handleQuickActionIfNeeded() {
        guard let action = quickActionManager.selectedAction else { return }
        guard !trips.isEmpty else { return }
        guard selectedTripId != nil else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch action {
            case .scanReceipt:
                checkCameraPermission()
            case .addExpense:
                showingManualEntry = true
            }
            quickActionManager.selectedAction = nil
        }
    }
}

// MARK: - Scan Result Item

struct ScanResultItem: Identifiable {
    let id = UUID()
    let trip: SplitTrip
    let result: OCRResult
    let imagesData: [Data]
}

// MARK: - 掃描選項按鈕
struct ScanOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - 確認消費資訊
struct ScanResultExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: SplitTrip
    let ocrResult: OCRResult?
    let imagesData: [Data]

    private let categories = StaticCategory.all
    private let currencies = StaticCurrency.all

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var address: String = ""
    @State private var amount: String = ""
    @State private var currencyCode: String = ""
    @State private var selectedCategoryId: String?
    @State private var paidById: UUID?
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var editableItems: [OCRItem] = []
    @State private var showItemAssignments = false
    @State private var itemAssignments: [UUID: Set<UUID>] = [:]

    var participants: [Participant] {
        trip.sortedParticipants
    }

    var labelParticipants: [Participant] {
        trip.sortedParticipants
    }

    @State private var showingValidationAlert = false

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

    var body: some View {
        NavigationStack {
            Form {
                Section("basicInfo") {
                    TextField("item", text: $title)
                    TextField("subtitle", text: $subtitle)
                    TextField("address", text: $address)
                }

                if editableItems.isEmpty && ocrResult == nil {
                    Section {
                        Button {
                            editableItems.append(OCRItem(name: "", quantity: 1, unitPrice: nil, totalPrice: nil))
                        } label: {
                            Label(String(localized: "addItem"), systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }
                }

                if !editableItems.isEmpty || ocrResult != nil {
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
                                            let names = labelParticipants.filter { assigned.contains($0.id) }.map { $0.name }
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
                                            ForEach(labelParticipants) { p in
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
                                            let names = labelParticipants.filter { assigned.contains($0.id) }.map { $0.name }
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
                    Picker("category", selection: $selectedCategoryId) {
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

                if !imagesData.isEmpty {
                    Section("receiptPhoto") {
                        ForEach(Array(imagesData.enumerated()), id: \.offset) { _, data in
                            ZoomableImageView(imageData: data)
                                .frame(maxHeight: 150)
                        }
                    }
                }

                Section("notes") {
                    TextField("notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(trip.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        if isValid {
                            saveExpense()
                        } else {
                            showingValidationAlert = true
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
                loadOCRData()
            }
            .alert("missingInfo", isPresented: $showingValidationAlert) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private func loadOCRData() {
        currencyCode = trip.baseCurrencyCode

        if let me = participants.first(where: { $0.isMe }) {
            paidById = me.id
        }

        if let result = ocrResult {
            if let merchantName = result.merchantName {
                title = merchantName
            }
            if let sub = result.subtitle {
                subtitle = sub
            }
            if let addr = result.address {
                address = addr
            }
            if let amt = result.amount {
                amount = String(format: "%.2f", amt)
            }
            if let d = result.date {
                date = d
            }
            if let detectedCurrency = result.currency {
                currencyCode = detectedCurrency
            }
            if let suggestedCategoryId = result.suggestedCategoryName {
                if categories.contains(where: { $0.id == suggestedCategoryId }) {
                    selectedCategoryId = suggestedCategoryId
                }
            }
            editableItems = result.items
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    @MainActor
    private func saveExpense() {
        guard !isSaving else { return }
        guard let amountValue = Double(amount) else { return }
        isSaving = true

        // Build expense items from editable items
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

        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)

        let expense = SplitExpense(
            tripId: trip.id,
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amountValue,
            currencyCode: currencyCode,
            date: date,
            category: selectedCategoryId ?? "other",
            paidById: paidById?.uuidString,
            items: expenseItems,
            subtitle: trimmedSubtitle.isEmpty ? nil : trimmedSubtitle,
            address: trimmedAddress.isEmpty ? nil : trimmedAddress,
            isFromOCR: ocrResult != nil,
            receiptImagePaths: ocrResult?.imageUrls ?? [],
            notes: notes
        )

        Task {
            do {
                _ = try await SplitService.shared.createExpense(expense)

                // 快取收據圖片到本地
                if let imageUrls = ocrResult?.imageUrls {
                    for (index, imageUrl) in imageUrls.enumerated() {
                        if index < imagesData.count {
                            ImageCacheService.shared.save(imagesData[index], for: imageUrl)
                        }
                    }
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
}

// MARK: - 圖片縮圖（帶刪除按鈕）
struct ImageThumbnailWithDelete: View {
    let image: UIImage
    let index: Int
    let isCurrentProcessing: Bool
    let isProcessed: Bool
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentProcessing ? Color.accentColor : Color.clear, lineWidth: 3)
                )

            VStack {
                HStack {
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(isProcessed ? Color.green : (isCurrentProcessing ? Color.accentColor : Color.black.opacity(0.6)))
                        .clipShape(Circle())
                    Spacer()

                    if !isProcessed {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .background(Color.red.clipShape(Circle()))
                        }
                    }
                }
                Spacer()
            }
            .padding(4)

            if isProcessed {
                ZStack {
                    Color.black.opacity(0.4)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 80, height: 80)
    }
}


// MARK: - 圖片縮圖（基本版）
struct ImageThumbnail: View {
    let image: UIImage
    let index: Int
    let isCurrentProcessing: Bool
    let isProcessed: Bool

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrentProcessing ? Color.accentColor : Color.clear, lineWidth: 3)
                )

            VStack {
                HStack {
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(isProcessed ? Color.green : (isCurrentProcessing ? Color.accentColor : Color.black.opacity(0.6)))
                        .clipShape(Circle())
                    Spacer()
                }
                Spacer()
            }
            .padding(4)

            if isProcessed {
                ZStack {
                    Color.black.opacity(0.4)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 80, height: 80)
    }
}


// MARK: - Scan Preview Sheet（供 TripDetailView 使用）
struct ScanPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?
    @Binding var isProcessing: Bool
    let onStartScan: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 上方說明
                VStack(spacing: 6) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    Text("receiptPreview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // 照片預覽
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }

                Spacer()

                // 按鈕
                if isProcessing {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("recognizing")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                } else {
                    VStack(spacing: 12) {
                        Button(action: { onStartScan() }) {
                            Label("startScan", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            onCancel()
                            dismiss()
                        }) {
                            Text("back")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .navigationTitle("receiptScan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - No Data Detected View
struct NoDataDetectedView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // 照片縮圖
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        .padding(.bottom, 24)
                }

                // 警告卡片
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)

                    Text("noData.title")
                        .font(.headline)

                    VStack(alignment: .center, spacing: 6) {
                        Text("noData.description")
                            .foregroundColor(.secondary)
                        Text("noData.tips")
                            .foregroundColor(.secondary)
                        Text("noData.tip1")
                            .foregroundColor(.secondary)
                        Text("noData.tip2")
                            .foregroundColor(.secondary)
                        Text("noData.tip3")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()
                Spacer()
            }
            .navigationTitle("noData.navTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScannerView()
}
