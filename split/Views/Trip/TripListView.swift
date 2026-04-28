import SwiftUI

struct TripListView: View {
    @AppStorage("defaultTripId") private var defaultTripIdString: String = ""
    @AppStorage("lastViewedTripId") private var lastViewedTripIdString: String = ""
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var adState = AdBannerState.shared
    @State private var trips: [SplitTrip] = []
    @State private var expenses: [UUID: [SplitExpense]] = [:]  // tripId -> expenses
    @State private var showingAddTrip = false
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var navigationPath = NavigationPath()
    @State private var hasRestoredNavigation = false
    let switchToScanTab: () -> Void

    var defaultTripId: UUID? {
        UUID(uuidString: defaultTripIdString)
    }

    private var allTrips: [SplitTrip] {
        if SampleDataService.shared.hasDismissed {
            return trips
        }
        return [SampleDataService.shared.sampleTrip] + trips
    }

    var filteredTrips: [SplitTrip] {
        if searchText.isEmpty {
            return allTrips
        }
        return allTrips.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            (Locale.current.localizedString(forRegionCode: $0.destinationCountryCode) ?? "")
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if allTrips.isEmpty && !isLoading {
                    ContentUnavailableView {
                        Label("noTrips", systemImage: "airplane")
                    } description: {
                        Text("trips.emptyState")
                    } actions: {
                        Button(action: { showingAddTrip = true }) {
                            Label("newTrip", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredTrips) { trip in
                            NavigationLink(value: trip.id) {
                                TripRowView(
                                    trip: trip,
                                    expenses: SampleDataService.isSampleTrip(trip.id)
                                        ? SampleDataService.shared.sampleExpenses
                                        : (expenses[trip.id] ?? []),
                                    isDefault: trip.id == defaultTripId
                                )
                            }
                            .swipeActions(edge: .leading) {
                                if !SampleDataService.isSampleTrip(trip.id) {
                                    Button {
                                        setDefaultTrip(trip)
                                    } label: {
                                        Label("default", systemImage: "star.fill")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if SampleDataService.isSampleTrip(trip.id) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            SampleDataService.shared.dismiss()
                                        }
                                    } label: {
                                        Label("delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: Text("searchTrips"))
                }
            }
            .navigationTitle("tab.trips")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { tripId in
                if let trip = allTrips.first(where: { $0.id == tripId }) {
                    TripDetailView(
                        trip: trip,
                        isSample: SampleDataService.isSampleTrip(tripId),
                        sampleExpenses: SampleDataService.isSampleTrip(tripId) ? SampleDataService.shared.sampleExpenses : nil,
                        switchToScanTab: switchToScanTab,
                        onTripUpdated: { loadTrips() },
                        onSampleDismissed: {
                            SampleDataService.shared.dismiss()
                            navigationPath = NavigationPath()
                        }
                    )
                    .onAppear {
                        lastViewedTripIdString = tripId.uuidString
                    }
                    .onDisappear {
                        lastViewedTripIdString = ""
                        loadTrips()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip, onDismiss: { loadTrips() }) {
                TripEditView(mode: .add)
            }
            .task {
                // 等待 AuthService 完成 session 恢復，避免在 userId 尚未就緒時查詢
                while !AuthService.shared.isReady {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                loadTrips()
            }
            .onChange(of: auth.isAuthenticated) { _, _ in
                isLoading = true
                expenses = [:]
                loadTrips()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: adState.isLoaded ? 60 : 0)
            }
        }
    }

    private func setDefaultTrip(_ trip: SplitTrip) {
        withAnimation {
            defaultTripIdString = trip.id.uuidString
        }
    }

    private func loadTrips() {
        Task {
            isLoading = true
            do {
                trips = try await SplitService.shared.fetchTrips()
                // Fetch expenses for each trip independently
                for trip in trips {
                    do {
                        let tripExpenses = try await SplitService.shared.fetchExpenses(tripId: trip.id)
                        expenses[trip.id] = tripExpenses
                    } catch {
                        print("Failed to load expenses for trip \(trip.id): \(error)")
                    }
                }
                // Restore last viewed trip on first load
                if !hasRestoredNavigation {
                    hasRestoredNavigation = true
                    if let lastId = UUID(uuidString: lastViewedTripIdString),
                       trips.contains(where: { $0.id == lastId }) {
                        navigationPath.append(lastId)
                    }
                }
            } catch {
                print("Failed to load trips: \(error)")
            }
            isLoading = false
        }
    }
}

struct TripRowView: View {
    let trip: SplitTrip
    let expenses: [SplitExpense]
    var isDefault: Bool = false

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amountInBaseCurrency(from: trip) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                if isDefault {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
                Text(formatCurrency(totalExpenses, code: trip.baseCurrencyCode))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                if !trip.destinationCountryCode.isEmpty {
                    HStack(spacing: 4) {
                        if let country = CountryInfo.countries.first(where: { $0.regionCode == trip.destinationCountryCode }) {
                            Text(country.flag)
                        }
                        Text(localizedDestination(trip))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatDateRange(trip.startDate, trip.endDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("expenses.count \(expenses.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
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

    private func localizedDestination(_ trip: SplitTrip) -> String {
        Locale.current.localizedString(forRegionCode: trip.destinationCountryCode) ?? trip.destinationCountryCode
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

#Preview {
    TripListView(switchToScanTab: {})
}
