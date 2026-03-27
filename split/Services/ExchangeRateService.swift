import Foundation

@MainActor
class ExchangeRateService {
    static let shared = ExchangeRateService()

    /// 支援的幣別（與 Currency.defaultCurrencies 對應）
    static let supportedCurrencies = [
        "TWD", "USD", "JPY", "EUR", "CNY", "KRW",
        "HKD", "GBP", "AUD", "SGD", "THB", "MYR", "VND"
    ]

    private init() {}

    /// 以 USD 為基準取得所有支援幣別的匯率
    func fetchRates() async throws -> [String: Double] {
        let urlString = "https://api.exchangerate-api.com/v4/latest/USD"
        guard let url = URL(string: urlString) else {
            throw ExchangeRateError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ExchangeRateError.requestFailed
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(ExchangeRateResponse.self, from: data)

        // 只回傳支援的幣別
        return result.rates.filter { Self.supportedCurrencies.contains($0.key) }
    }
}

struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

enum ExchangeRateError: LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.invalidURL")
        case .requestFailed:
            return String(localized: "error.requestFailed")
        case .decodingFailed:
            return String(localized: "error.decodingFailed")
        }
    }
}
