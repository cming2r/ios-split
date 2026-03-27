import SwiftUI

struct CountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: CountryInfo?
    @State private var searchText = ""
    @State private var showAllCountries = false

    // 依使用者所在地區動態排序的常用國家
    static var popularRegionCodes: [String] {
        let home = Locale.current.region?.identifier ?? "US"

        // 各地區的鄰近熱門旅遊國家
        let regionMap: [String: [String]] = [
            "JP": ["KR", "TW", "CN", "TH", "US", "HK", "SG", "VN", "PH", "ID", "MY", "AU"],
            "KR": ["JP", "TW", "CN", "TH", "US", "VN", "PH", "HK", "SG", "MY", "ID", "AU"],
            "TW": ["JP", "KR", "US", "CN", "TH", "VN", "SG", "MY", "HK", "PH", "ID", "AU"],
            "CN": ["JP", "KR", "TW", "TH", "SG", "MY", "US", "HK", "VN", "PH", "AU", "ID"],
            "HK": ["JP", "TW", "KR", "CN", "TH", "SG", "MY", "US", "VN", "PH", "ID", "AU"],
            "US": ["CA", "MX", "JP", "GB", "FR", "DE", "IT", "KR", "TW", "TH", "AU", "ES"],
            "CA": ["US", "MX", "GB", "FR", "JP", "DE", "IT", "AU", "KR", "TW", "TH", "ES"],
            "MX": ["US", "CA", "ES", "FR", "GB", "JP", "DE", "IT", "CO", "BR", "CU", "AU"],
            "GB": ["FR", "DE", "ES", "IT", "US", "NL", "IE", "PT", "AT", "CH", "JP", "AU"],
            "DE": ["AT", "FR", "IT", "ES", "NL", "CH", "GB", "US", "JP", "CZ", "PL", "TR"],
            "FR": ["ES", "IT", "DE", "GB", "PT", "NL", "CH", "BE", "US", "JP", "MA", "AT"],
            "IT": ["FR", "DE", "ES", "AT", "CH", "GB", "US", "GR", "NL", "JP", "HR", "PT"],
            "ES": ["FR", "PT", "IT", "DE", "GB", "NL", "US", "MA", "MX", "JP", "AT", "GR"],
            "AU": ["NZ", "JP", "ID", "TH", "SG", "US", "GB", "MY", "VN", "KR", "FJ", "PH"],
            "NZ": ["AU", "JP", "FJ", "ID", "TH", "SG", "US", "GB", "MY", "KR", "TW", "VN"],
            "TH": ["JP", "KR", "SG", "MY", "VN", "CN", "TW", "ID", "PH", "HK", "US", "AU"],
            "SG": ["MY", "JP", "TH", "KR", "ID", "TW", "AU", "VN", "CN", "HK", "US", "PH"],
            "MY": ["SG", "TH", "JP", "ID", "KR", "TW", "AU", "VN", "CN", "HK", "US", "PH"],
            "VN": ["JP", "KR", "TH", "SG", "TW", "MY", "CN", "ID", "PH", "HK", "US", "AU"],
            "PH": ["JP", "KR", "SG", "TH", "MY", "TW", "US", "HK", "AU", "VN", "ID", "CN"],
            "ID": ["SG", "MY", "JP", "AU", "TH", "KR", "TW", "VN", "PH", "CN", "HK", "US"],
            "IN": ["SG", "TH", "MY", "AE", "US", "GB", "JP", "AU", "LK", "NP", "HK", "ID"],
            "AE": ["IN", "GB", "US", "SA", "TH", "SG", "FR", "DE", "EG", "TR", "JP", "MY"],
            "TR": ["DE", "GB", "FR", "GR", "IT", "ES", "NL", "AE", "US", "EG", "JP", "AT"],
            "BR": ["US", "AR", "PT", "FR", "IT", "ES", "DE", "GB", "CL", "MX", "JP", "CO"],
        ]

        // 洲別 fallback
        let continentMap: [String: [String]] = [
            "asia":    ["JP", "KR", "TH", "SG", "TW", "CN", "VN", "MY", "ID", "PH", "HK", "IN"],
            "europe":  ["FR", "DE", "IT", "ES", "GB", "NL", "AT", "CH", "PT", "GR", "CZ", "TR"],
            "americas":["US", "CA", "MX", "BR", "AR", "CO", "CL", "PE", "CU", "CR", "JP", "GB"],
            "oceania": ["AU", "NZ", "FJ", "JP", "SG", "ID", "TH", "US", "GB", "KR", "MY", "PH"],
            "africa":  ["ZA", "EG", "MA", "KE", "TZ", "FR", "GB", "AE", "US", "DE", "ES", "IT"],
        ]

        let asiaCountries = Set(["JP","KR","TW","CN","HK","MO","TH","SG","MY","VN","PH","ID","IN","LK","NP","KH","MM","LA","BN","BD","PK","AE","SA","QA","BH","KW","OM","IL","JO","LB","TR"])
        let europeCountries = Set(["GB","FR","DE","IT","ES","PT","NL","BE","AT","CH","SE","NO","DK","FI","IE","PL","CZ","HU","GR","HR","RO","BG","SK","SI","LT","LV","EE","IS","LU","MT","CY","RS","BA","ME","MK","AL","XK","MD","UA","BY"])
        let oceaniaCountries = Set(["AU","NZ","FJ","PG","WS","TO","VU","SB","NC","PF"])

        if let neighbors = regionMap[home] {
            var result = [home]
            for code in neighbors where code != home {
                result.append(code)
            }
            return result
        }

        // 依洲別 fallback
        let continent: String
        if asiaCountries.contains(home) {
            continent = "asia"
        } else if europeCountries.contains(home) {
            continent = "europe"
        } else if oceaniaCountries.contains(home) {
            continent = "oceania"
        } else if Set(["ZA","EG","MA","KE","TZ","NG","GH","ET","DZ","TN","CI","SN","CM","UG","MZ"]).contains(home) {
            continent = "africa"
        } else {
            continent = "americas"
        }

        let fallback = continentMap[continent] ?? continentMap["asia"]!
        var result = [home]
        for code in fallback where code != home {
            result.append(code)
        }
        return result
    }

    var popularCountries: [CountryInfo] {
        Self.popularRegionCodes.compactMap { code in
            CountryInfo.countries.first { $0.regionCode == code }
        }
    }

    var otherCountries: [CountryInfo] {
        CountryInfo.countries.filter { country in
            !Self.popularRegionCodes.contains(country.regionCode)
        }
    }

    var filteredCountries: [CountryInfo] {
        if searchText.isEmpty {
            return []
        } else {
            return CountryInfo.countries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.currencyCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            if !searchText.isEmpty {
                // 搜尋結果
                ForEach(filteredCountries) { country in
                    countryRow(country)
                }
            } else {
                // 常用國家
                Section("popularCountries") {
                    ForEach(popularCountries) { country in
                        countryRow(country)
                    }
                }

                // 更多國家
                Section {
                    if showAllCountries {
                        ForEach(otherCountries) { country in
                            countryRow(country)
                        }
                    } else {
                        Button {
                            withAnimation {
                                showAllCountries = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.accentColor)
                                Text("moreCountries")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    if showAllCountries {
                        Text("allCountries")
                    }
                }
            }
        }
        .navigationTitle("selectCountry")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "searchCountry")
    }

    @ViewBuilder
    private func countryRow(_ country: CountryInfo) -> some View {
        Button {
            selectedCountry = country
            dismiss()
        } label: {
            HStack {
                Text(country.flag)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(country.name)
                        .foregroundColor(.primary)
                    Text(country.currencyCode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if selectedCountry?.id == country.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CountryPickerView(selectedCountry: .constant(nil))
    }
}
