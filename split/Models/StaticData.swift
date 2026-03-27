import Foundation

// MARK: - Static Category
struct StaticCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let sortOrder: Int

    var localizedName: String {
        let key = "category." + id
        return String(localized: String.LocalizationValue(key))
    }

    static let all: [StaticCategory] = [
        StaticCategory(id: "food", name: "餐飲", icon: "fork.knife", colorHex: "#FF9500", sortOrder: 0),
        StaticCategory(id: "transport", name: "交通", icon: "car.fill", colorHex: "#007AFF", sortOrder: 1),
        StaticCategory(id: "shopping", name: "購物", icon: "bag.fill", colorHex: "#FF2D55", sortOrder: 2),
        StaticCategory(id: "tickets", name: "門票", icon: "ticket.fill", colorHex: "#FF3B30", sortOrder: 3),
        StaticCategory(id: "entertainment", name: "娛樂", icon: "gamecontroller.fill", colorHex: "#AF52DE", sortOrder: 4),
        StaticCategory(id: "accommodation", name: "住宿", icon: "bed.double.fill", colorHex: "#5856D6", sortOrder: 5),
        StaticCategory(id: "other", name: "其他", icon: "ellipsis.circle.fill", colorHex: "#8E8E93", sortOrder: 6),
    ]

    static func find(byId id: String?) -> StaticCategory? {
        guard let id = id else { return nil }
        return all.first { $0.id == id }
    }

}

// MARK: - Static Currency
struct StaticCurrency: Identifiable, Hashable {
    let code: String
    let symbol: String
    let sortOrder: Int

    var id: String { code }

    var name: String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    static let all: [StaticCurrency] = [
        // Americas
        StaticCurrency(code: "USD", symbol: "$", sortOrder: 0),
        // Europe
        StaticCurrency(code: "EUR", symbol: "€", sortOrder: 1),
        StaticCurrency(code: "GBP", symbol: "£", sortOrder: 2),
        // Asia-Pacific
        StaticCurrency(code: "CNY", symbol: "¥", sortOrder: 3),
        StaticCurrency(code: "JPY", symbol: "¥", sortOrder: 4),
        StaticCurrency(code: "TWD", symbol: "NT$", sortOrder: 5),
        StaticCurrency(code: "KRW", symbol: "₩", sortOrder: 6),
        StaticCurrency(code: "HKD", symbol: "HK$", sortOrder: 7),
        StaticCurrency(code: "AUD", symbol: "A$", sortOrder: 8),
        StaticCurrency(code: "SGD", symbol: "S$", sortOrder: 9),
        StaticCurrency(code: "THB", symbol: "฿", sortOrder: 10),
        StaticCurrency(code: "MYR", symbol: "RM", sortOrder: 11),
        StaticCurrency(code: "VND", symbol: "₫", sortOrder: 12),
    ]

    static func find(byCode code: String) -> StaticCurrency? {
        all.first { $0.code == code }
    }
}

// MARK: - Static Tag
struct StaticTag: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let sortOrder: Int

    var localizedName: String {
        let key = "tag." + id
        return String(localized: String.LocalizationValue(key))
    }

    static let all: [StaticTag] = [
        StaticTag(id: "personal", name: "個人", icon: "person.fill", colorHex: "#5856D6", sortOrder: 0),
        StaticTag(id: "group", name: "團體", icon: "person.3.fill", colorHex: "#FF9500", sortOrder: 1),
        StaticTag(id: "reimbursable", name: "可報銷", icon: "doc.text.fill", colorHex: "#34C759", sortOrder: 2),
    ]
}

// MARK: - Exchange Rate Helpers (static, no SwiftData)
struct ExchangeRateData: Identifiable {
    let id = UUID()
    let currencyCode: String
    let rateToUSD: Double
    let updatedAt: Date

    init(currencyCode: String, rateToUSD: Double, updatedAt: Date = Date()) {
        self.currencyCode = currencyCode
        self.rateToUSD = rateToUSD
        self.updatedAt = updatedAt
    }

    static func getRate(from: String, to: String, rates: [ExchangeRateData]) -> Double? {
        if from == to { return 1.0 }
        let fromRate = from == "USD" ? 1.0 : rates.first { $0.currencyCode == from }?.rateToUSD
        let toRate = to == "USD" ? 1.0 : rates.first { $0.currencyCode == to }?.rateToUSD
        guard let fromR = fromRate, let toR = toRate else { return nil }
        return toR / fromR
    }

    static func convert(amount: Double, from: String, to: String, rates: [ExchangeRateData]) -> Double? {
        guard let rate = getRate(from: from, to: to, rates: rates) else { return nil }
        return amount * rate
    }
}
