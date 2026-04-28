import SwiftUI

enum TripEditMode {
    case add
    case edit(SplitTrip)
}

struct TripEditView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: TripEditMode

    @State private var name: String = ""
    @State private var destinationCountryCode: String = ""
    @State private var selectedCountry: CountryInfo? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var baseCurrencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @State private var exchangeRateEntries: [(code: String, rate: String)] = []
    @State private var notes: String = ""
    @State private var showingCurrencyPicker = false
    @State private var participantNames: [String] = [String(localized: "participant.me")]

    @State private var existingParticipantIds: [UUID] = []
    @State private var isSaving = false
    @State private var isFetchingRate = false
    @State private var hasLoadedData = false

    @State private var showingMapPicker = false

    private let currencies = StaticCurrency.all

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedCountry != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("basicInfo") {
                    TextField("tripName", text: $name)
                }

                Section("destinationCountry") {
                    NavigationLink {
                        CountryPickerView(selectedCountry: $selectedCountry)
                    } label: {
                        HStack {
                            Text("country")
                            Button {
                                showingMapPicker = true
                            } label: {
                                Image(systemName: "map")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            if let country = selectedCountry {
                                Text("\(country.flag) \(country.name)")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("selectCountry")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: selectedCountry) { _, newCountry in
                        if let country = newCountry {
                            destinationCountryCode = country.regionCode
                            baseCurrencyCode = country.currencyCode
                            // Auto-add home currency exchange rate
                            let homeCurrency = Locale.current.currency?.identifier ?? "TWD"
                            if homeCurrency != country.currencyCode,
                               !exchangeRateEntries.contains(where: { $0.code == homeCurrency }) {
                                exchangeRateEntries.append((code: homeCurrency, rate: ""))
                                fetchExchangeRate(for: homeCurrency)
                            }
                        }
                    }

                    if let country = selectedCountry {
                        if baseCurrencyOptions.count > 1 {
                            Picker("baseCurrency", selection: $baseCurrencyCode) {
                                ForEach(baseCurrencyOptions, id: \.self) { code in
                                    let name = Locale.current.localizedString(forCurrencyCode: code) ?? code
                                    Text(name).tag(code)
                                }
                            }
                            .onChange(of: baseCurrencyCode) { oldCode, newCode in
                                guard oldCode != newCode else { return }
                                for i in exchangeRateEntries.indices {
                                    fetchExchangeRate(for: exchangeRateEntries[i].code)
                                }
                                exchangeRateEntries.removeAll { $0.code == newCode }
                            }
                        } else {
                            HStack {
                                Text("baseCurrency")
                                Spacer()
                                Text(Locale.current.localizedString(forCurrencyCode: baseCurrencyCode) ?? baseCurrencyCode)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("timeZone")
                            Spacer()
                            Text(country.timeZone.abbreviation() ?? country.timeZoneIdentifier)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if selectedCountry != nil {
                    Section("exchangeRates") {
                        ForEach(Array(exchangeRateEntries.enumerated()), id: \.offset) { index, entry in
                            HStack {
                                Text("1 \(entry.code) =")
                                    .foregroundColor(.secondary)
                                TextField("0.00", text: Binding(
                                    get: { exchangeRateEntries[index].rate },
                                    set: { exchangeRateEntries[index].rate = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                Text(baseCurrencyCode)
                                    .foregroundColor(.secondary)
                                Button(role: .destructive) {
                                    exchangeRateEntries.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                            }
                        }

                        Button {
                            showingCurrencyPicker = true
                        } label: {
                            Label("addCurrency", systemImage: "plus")
                        }
                        .disabled(isFetchingRate)

                        if isFetchingRate {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("fetchingRate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("date") {
                    DatePicker("startDate", selection: $startDate, displayedComponents: .date)
                    DatePicker("endDate", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("participants") {
                    Stepper("participantCount \(participantNames.count)", onIncrement: {
                        addParticipant()
                    }, onDecrement: {
                        removeLastParticipant()
                    })
                    .disabled(participantNames.count >= 10)

                    ForEach(Array(participantNames.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            TextField("participantName", text: $participantNames[index])
                            if index == 0 {
                                Text("me.tag")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

Section("notes") {
                    TextField("notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(isEditMode ? String(localized: "editTrip") : String(localized: "newTrip"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveTrip()
                    } label: {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("save")
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                guard !hasLoadedData else { return }
                hasLoadedData = true
                loadExistingData()
            }
            .sheet(isPresented: $showingMapPicker) {
                MapCountryPickerView(selectedCountry: $selectedCountry)
            }
            .sheet(isPresented: $showingCurrencyPicker) {
                currencyPickerSheet
            }
        }
    }

    // European non-EUR countries where EUR is widely accepted
    private static let eurAlternativeRegions: Set<String> = [
        "CZ", "HU", "PL", "CH", "SE", "DK", "NO", "HR", "RO", "BG", "GB", "IS"
    ]
    // Countries where USD is commonly used alongside local currency
    private static let usdAlternativeRegions: Set<String> = [
        "KH", "VN", "LA", "MM", "PA", "EC", "SV", "BZ", "ZW"
    ]

    private var baseCurrencyOptions: [String] {
        guard let country = selectedCountry else { return [baseCurrencyCode] }
        let local = country.currencyCode
        let region = country.regionCode
        var options = [local]
        if Self.eurAlternativeRegions.contains(region), local != "EUR" {
            options.append("EUR")
        }
        if Self.usdAlternativeRegions.contains(region), local != "USD" {
            options.append("USD")
        }
        return options
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func addParticipant() {
        guard participantNames.count < 10 else { return }
        let newIndex = participantNames.count + 1
        participantNames.append(String(localized: "participant.person \(newIndex)"))
    }

    private func removeLastParticipant() {
        guard participantNames.count > 1 else { return }
        participantNames.removeLast()
    }

    private func fetchExchangeRate(for currencyCode: String) {
        guard currencyCode != baseCurrencyCode else { return }
        isFetchingRate = true
        Task {
            defer { isFetchingRate = false }
            do {
                guard let url = URL(string: "https://open.er-api.com/v6/latest/\(currencyCode)") else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let rates = json?["rates"] as? [String: Double],
                   let rate = rates[baseCurrencyCode] {
                    if let index = exchangeRateEntries.firstIndex(where: { $0.code == currencyCode }) {
                        exchangeRateEntries[index].rate = String(format: "%.4f", rate)
                    }
                }
            } catch {
                print("Failed to fetch exchange rate: \(error)")
            }
        }
    }

    @ViewBuilder
    private var currencyPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(currencies, id: \.code) { currency in
                    let alreadyAdded = exchangeRateEntries.contains { $0.code == currency.code }
                    let isBase = currency.code == baseCurrencyCode
                    Button {
                        if !alreadyAdded && !isBase {
                            exchangeRateEntries.append((code: currency.code, rate: ""))
                            fetchExchangeRate(for: currency.code)
                        }
                        showingCurrencyPicker = false
                    } label: {
                        HStack {
                            Text("\(currency.symbol) \(currency.name)")
                                .foregroundColor(alreadyAdded || isBase ? .secondary : .primary)
                            Spacer()
                            if isBase {
                                Text("baseCurrency")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if alreadyAdded {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .disabled(alreadyAdded || isBase)
                }
            }
            .navigationTitle("addCurrency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { showingCurrencyPicker = false }
                }
            }
        }
    }

    private func buildExchangeRates() -> [String: Double] {
        var rates: [String: Double] = [:]
        for entry in exchangeRateEntries {
            if let rate = Double(entry.rate), rate > 0 {
                rates[entry.code] = rate
            }
        }
        return rates
    }

    private func loadExistingData() {
        if case .edit(let trip) = mode {
            name = trip.name
            destinationCountryCode = trip.destinationCountryCode
            startDate = trip.startDate
            endDate = trip.endDate
            baseCurrencyCode = trip.baseCurrencyCode
            // Load exchange rates
            exchangeRateEntries = trip.exchangeRate.map { (code: $0.key, rate: String(format: "%.4f", $0.value)) }
            notes = trip.notes
            if !trip.destinationCountryCode.isEmpty {
                selectedCountry = CountryInfo.countries.first { $0.regionCode == trip.destinationCountryCode }
            } else {
                selectedCountry = CountryInfo.find(byCurrencyCode: trip.baseCurrencyCode)
            }

            // Load participants
            let sortedP = trip.sortedParticipants
            participantNames = sortedP.map { $0.name }
            existingParticipantIds = sortedP.map { $0.id }

        }
    }

    private func saveTrip() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                switch mode {
                case .add:
                    // Build participants
                    var tripParticipants: [Participant] = []
                    for (i, pName) in participantNames.enumerated() {
                        let participantName = pName.trimmingCharacters(in: .whitespaces)
                        let finalName = participantName.isEmpty ? String(localized: "participant.person \(i + 1)") : participantName
                        tripParticipants.append(Participant(
                            name: finalName,
                            isMe: i == 0,
                            sortOrder: i
                        ))
                    }

                    let trip = SplitTrip(
                        name: name.trimmingCharacters(in: .whitespaces),
                        destinationCountryCode: destinationCountryCode,
                        startDate: startDate,
                        endDate: endDate,
                        baseCurrencyCode: baseCurrencyCode,
                        exchangeRate: buildExchangeRates(),
                        timeZoneIdentifier: selectedCountry?.timeZoneIdentifier ?? TimeZone.current.identifier,
                        notes: notes,
                        participants: tripParticipants
                    )
                    _ = try await SplitService.shared.createTrip(trip)

                case .edit(var trip):
                    trip.name = name.trimmingCharacters(in: .whitespaces)
                    trip.destinationCountryCode = destinationCountryCode
                    trip.startDate = startDate
                    trip.endDate = endDate
                    trip.baseCurrencyCode = baseCurrencyCode
                    trip.exchangeRate = buildExchangeRates()
                    trip.notes = notes

                    // Build participants (preserve existing UUIDs)
                    var tripParticipants: [Participant] = []
                    for (i, pName) in participantNames.enumerated() {
                        let participantName = pName.trimmingCharacters(in: .whitespaces)
                        let finalName = participantName.isEmpty ? String(localized: "participant.person \(i + 1)") : participantName
                        let id = i < existingParticipantIds.count ? existingParticipantIds[i] : UUID()
                        tripParticipants.append(Participant(
                            id: id,
                            name: finalName,
                            isMe: i == 0,
                            sortOrder: i
                        ))
                    }
                    trip.participants = tripParticipants

_ = try await SplitService.shared.updateTrip(trip)
                }
                dismiss()
            } catch {
                print("Failed to save trip: \(error)")
            }
        }
    }
}

#Preview {
    TripEditView(mode: .add)
}
