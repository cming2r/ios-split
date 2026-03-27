import SwiftUI

enum AppAppearance: String, CaseIterable {
    case light
    case system
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .light: return "appearance.light"
        case .system: return "appearance.system"
        case .dark: return "appearance.dark"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        }
    }
}

struct SettingsView: View {
    @AppStorage("userCurrencyCode") private var userCurrencyCode: String = ""
    @AppStorage("appAppearance") private var appAppearance: String = AppAppearance.light.rawValue

    private let currencies = StaticCurrency.all

    var currentCurrency: StaticCurrency? {
        currencies.first { $0.code == userCurrencyCode }
    }

var body: some View {
        NavigationStack {
            List {
                SignInView()

                Section {
                    NavigationLink(destination: CurrencyManagementView()) {
                        HStack {
                            Label("myCurrency", systemImage: "dollarsign.circle")
                            Spacer()
                            if let currency = currentCurrency {
                                Text("\(currency.symbol) \(currency.code)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    NavigationLink(destination: ExchangeRateView()) {
                        Label("exchangeRates", systemImage: "arrow.left.arrow.right")
                    }
                }

                Section {
                    HStack {
                        Label("appearance", systemImage: "paintbrush")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { AppAppearance(rawValue: appAppearance) ?? .light },
                            set: { appAppearance = $0.rawValue }
                        )) {
                            ForEach(AppAppearance.allCases, id: \.self) { mode in
                                Label(mode.label, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

Section {
                    NavigationLink(destination: ContactView()) {
                        Label("feedback.title", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("tab.settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CurrencyManagementView: View {
    @AppStorage("userCurrencyCode") private var userCurrencyCode: String = ""

    private let currencies = StaticCurrency.all

    var body: some View {
        List {
            Section {
                ForEach(currencies, id: \.code) { currency in
                    Button {
                        userCurrencyCode = currency.code
                    } label: {
                        HStack {
                            Text(currency.symbol)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text(currency.name)
                                    .foregroundColor(.primary)
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if userCurrencyCode == currency.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } footer: {
                Text("myCurrency.footer")
            }
        }
        .navigationTitle("myCurrency")
        .onAppear {
            if userCurrencyCode.isEmpty {
                userCurrencyCode = getDefaultCurrencyCode()
            }
        }
    }

    private func getDefaultCurrencyCode() -> String {
        let locale = Locale.current
        if let currencyCode = locale.currency?.identifier {
            if currencies.contains(where: { $0.code == currencyCode }) {
                return currencyCode
            }
        }
        return "USD"
    }
}

struct ExchangeRateView: View {
    @AppStorage("userCurrencyCode") private var userCurrencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @State private var rates: [ExchangeRateData] = []
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var selectedCurrencyCode: String?
    @State private var leftAmount: String = "1"
    @State private var rightAmount: String = ""
    @FocusState private var focusedField: ConverterField?

    enum ConverterField {
        case left, right
    }

    private let currencies = StaticCurrency.all

    var userCurrency: StaticCurrency? {
        currencies.first { $0.code == userCurrencyCode }
    }

    var otherCurrencies: [StaticCurrency] {
        currencies.filter { $0.code != userCurrencyCode }
    }

    var body: some View {
        List {
            Section {
                Button(action: refreshRates) {
                    HStack {
                        Label("updateRates", systemImage: "arrow.clockwise")
                        if isRefreshing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isRefreshing)
            }

            if !rates.isEmpty {
                Section("currentRates") {
                    ForEach(otherCurrencies, id: \.code) { currency in
                        if let rate = ExchangeRateData.getRate(from: userCurrencyCode, to: currency.code, rates: rates) {
                            VStack(spacing: 0) {
                                Button {
                                    withAnimation {
                                        if selectedCurrencyCode == currency.code {
                                            selectedCurrencyCode = nil
                                        } else {
                                            selectedCurrencyCode = currency.code
                                            leftAmount = "1"
                                            rightAmount = formatRate(rate)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("1 \(userCurrencyCode)")
                                            .foregroundColor(.secondary)
                                        Text("=")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatRate(rate))
                                        Text(currency.code)
                                            .fontWeight(.medium)
                                        Image(systemName: selectedCurrencyCode == currency.code ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if selectedCurrencyCode == currency.code {
                                    CurrencyConverterRow(
                                        leftAmount: $leftAmount,
                                        rightAmount: $rightAmount,
                                        leftCode: userCurrencyCode,
                                        rightCode: currency.code,
                                        rate: rate,
                                        focusedField: $focusedField
                                    )
                                    .padding(.top, 12)
                                }
                            }
                        }
                    }
                }

                if let lastUpdate = rates.first?.updatedAt {
                    Section {
                        HStack {
                            Text("lastUpdated")
                            Spacer()
                            Text(formatDate(lastUpdate))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Section {
                    Text("exchangeRates.emptyState")
                        .foregroundColor(.secondary)
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("exchangeRates")
        .onAppear {
            refreshRates()
        }
    }

    private func refreshRates() {
        isRefreshing = true
        errorMessage = nil

        Task {
            do {
                let service = ExchangeRateService.shared
                let newRates = try await service.fetchRates()

                rates = newRates.map { ExchangeRateData(currencyCode: $0.key, rateToUSD: $0.value) }
            } catch {
                errorMessage = error.localizedDescription
            }

            isRefreshing = false
        }
    }

    private func formatRate(_ rate: Double) -> String {
        if rate >= 100 {
            return String(format: "%.0f", rate)
        } else if rate >= 1 {
            return String(format: "%.2f", rate)
        } else {
            return String(format: "%.4f", rate)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 匯率計算機
struct CurrencyConverterRow: View {
    @Binding var leftAmount: String
    @Binding var rightAmount: String
    let leftCode: String
    let rightCode: String
    let rate: Double
    var focusedField: FocusState<ExchangeRateView.ConverterField?>.Binding

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                TextField("0", text: $leftAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospacedDigit())
                    .focused(focusedField, equals: .left)
                    .onChange(of: leftAmount) { _, newValue in
                        if focusedField.wrappedValue == .left {
                            calculateRight(from: newValue)
                        }
                    }
                Text(leftCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Button {
                swapValues()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                TextField("0", text: $rightAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospacedDigit())
                    .focused(focusedField, equals: .right)
                    .onChange(of: rightAmount) { _, newValue in
                        if focusedField.wrappedValue == .right {
                            calculateLeft(from: newValue)
                        }
                    }
                Text(rightCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private func calculateRight(from leftValue: String) {
        guard let value = Double(leftValue.replacingOccurrences(of: ",", with: "")) else {
            rightAmount = ""
            return
        }
        let result = value * rate
        rightAmount = formatResult(result)
    }

    private func calculateLeft(from rightValue: String) {
        guard let value = Double(rightValue.replacingOccurrences(of: ",", with: "")) else {
            leftAmount = ""
            return
        }
        let result = value / rate
        leftAmount = formatResult(result)
    }

    private func swapValues() {
        rightAmount = "1"
        leftAmount = formatResult(1.0 / rate)
    }

    private func formatResult(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.4f", value)
        }
    }
}

#Preview {
    SettingsView()
}
