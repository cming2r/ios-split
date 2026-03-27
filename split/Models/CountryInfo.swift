import Foundation

// 國家與幣值對應 - 使用系統 Locale API
struct CountryInfo: Identifiable, Hashable {
    let id: String // 使用 regionCode 作為 id
    let regionCode: String
    let currencyCode: String

    // 自動本地化的國家名稱
    var name: String {
        Locale.current.localizedString(forRegionCode: regionCode) ?? regionCode
    }

    // 從 regionCode 生成國旗 emoji
    var flag: String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in regionCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }

    // 國家主要時區
    var timeZoneIdentifier: String {
        Self.timeZoneMapping[regionCode] ?? TimeZone.current.identifier
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }

    // 常見國家時區對照
    private static let timeZoneMapping: [String: String] = [
        "TW": "Asia/Taipei",
        "JP": "Asia/Tokyo",
        "KR": "Asia/Seoul",
        "CN": "Asia/Shanghai",
        "HK": "Asia/Hong_Kong",
        "SG": "Asia/Singapore",
        "MY": "Asia/Kuala_Lumpur",
        "TH": "Asia/Bangkok",
        "VN": "Asia/Ho_Chi_Minh",
        "PH": "Asia/Manila",
        "ID": "Asia/Jakarta",
        "US": "America/New_York",
        "GB": "Europe/London",
        "FR": "Europe/Paris",
        "DE": "Europe/Berlin",
        "IT": "Europe/Rome",
        "ES": "Europe/Madrid",
        "AU": "Australia/Sydney",
        "NZ": "Pacific/Auckland",
        "CA": "America/Toronto",
        "MX": "America/Mexico_City",
        "BR": "America/Sao_Paulo",
        "IN": "Asia/Kolkata",
        "AE": "Asia/Dubai",
        "TR": "Europe/Istanbul",
        "RU": "Europe/Moscow",
        "EG": "Africa/Cairo",
        "ZA": "Africa/Johannesburg",
        "KH": "Asia/Phnom_Penh",
        "MM": "Asia/Yangon",
        "LA": "Asia/Vientiane",
        "NP": "Asia/Kathmandu",
        "LK": "Asia/Colombo",
        "MV": "Indian/Maldives",
    ]

    init(regionCode: String, currencyCode: String) {
        self.id = regionCode
        self.regionCode = regionCode
        self.currencyCode = currencyCode
    }

    // 從 regionCode 建立，自動取得貨幣
    init?(regionCode: String) {
        self.id = regionCode
        self.regionCode = regionCode

        // 使用 Locale 取得該國家的貨幣
        let locale = Locale(identifier: "en_\(regionCode)")
        if let currency = locale.currency?.identifier {
            self.currencyCode = currency
        } else {
            return nil
        }
    }

    // 所有支援的國家（從系統取得）
    static let countries: [CountryInfo] = {
        Locale.Region.isoRegions
            .filter { $0.subRegions.isEmpty } // 只取國家，不取區域
            .compactMap { region -> CountryInfo? in
                let code = region.identifier
                // 確保有本地化名稱
                guard Locale.current.localizedString(forRegionCode: code) != nil else {
                    return nil
                }
                return CountryInfo(regionCode: code)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }()

    // 根據國家名稱查找（支援多語言）
    static func find(byName name: String) -> CountryInfo? {
        // 先嘗試精確匹配
        if let country = countries.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            return country
        }

        // 嘗試用不同語言的 Locale 匹配
        let locales = ["en", "zh-Hant", "zh-Hans", "ja", "ko"]
        for localeId in locales {
            let locale = Locale(identifier: localeId)
            if let country = countries.first(where: {
                locale.localizedString(forRegionCode: $0.regionCode)?.localizedCaseInsensitiveCompare(name) == .orderedSame
            }) {
                return country
            }
        }

        // 模糊匹配
        return countries.first { country in
            name.localizedCaseInsensitiveContains(country.name) ||
            country.name.localizedCaseInsensitiveContains(name)
        }
    }

    // 根據貨幣代碼查找
    static func find(byCurrencyCode code: String) -> CountryInfo? {
        countries.first { $0.currencyCode == code }
    }
}
