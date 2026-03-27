import SwiftUI

struct TripListView: View {
    @AppStorage("defaultTripId") private var defaultTripIdString: String = ""
    @AppStorage("lastViewedTripId") private var lastViewedTripIdString: String = ""
    @State private var trips: [SplitTrip] = []
    @State private var expenses: [UUID: [SplitExpense]] = [:]  // tripId -> expenses
    @State private var showingAddTrip = false
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var navigationPath = NavigationPath()
    @State private var hasRestoredNavigation = false
    let switchToScanTab: () -> Void

    var defaultTripId: UUID? {
        UUID(uuidString: defaultTripIdString)
    }

    var filteredTrips: [SplitTrip] {
        if searchText.isEmpty {
            return trips
        }
        return trips.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            (Locale.current.localizedString(forRegionCode: $0.destinationCountryCode) ?? "")
                .localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if trips.isEmpty && !isLoading {
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
                                    expenses: expenses[trip.id] ?? [],
                                    isDefault: trip.id == defaultTripId
                                )
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    setDefaultTrip(trip)
                                } label: {
                                    Label("default", systemImage: "star.fill")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: Text("searchTrips"))
                }
            }
            .navigationTitle("tab.trips")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { tripId in
                if let trip = trips.first(where: { $0.id == tripId }) {
                    TripDetailView(
                        trip: trip,
                        switchToScanTab: switchToScanTab,
                        onTripUpdated: { loadTrips() }
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
                loadTrips()
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
