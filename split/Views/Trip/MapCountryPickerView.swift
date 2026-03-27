import SwiftUI
import MapKit
import CoreLocation

struct MapCountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: CountryInfo?

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var detectedCountryName: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let coordinate = tappedCoordinate {
                            Marker("", coordinate: coordinate)
                                .tint(.red)
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            handleMapTap(coordinate: coordinate)
                        }
                    }
                }

                // 提示文字
                VStack {
                    Text("tapToSelectCountry")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.top, 8)

                    Spacer()

                    // 選中的國家資訊
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("detecting")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 20)
                    } else if let countryName = detectedCountryName {
                        VStack(spacing: 8) {
                            if let matchedCountry = findMatchingCountry(name: countryName) {
                                HStack {
                                    Text(matchedCountry.flag)
                                        .font(.largeTitle)
                                    Text(matchedCountry.name)
                                        .font(.headline)
                                }

                                Button {
                                    selectedCountry = matchedCountry
                                    dismiss()
                                } label: {
                                    Text("selectThisCountry")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Text("countryNotSupported \(countryName)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("selectCountryFromMap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                let coord = initialCoordinate()
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
                ))
            }
        }
    }

    private func initialCoordinate() -> CLLocationCoordinate2D {
        // 已選國家優先
        if let country = selectedCountry,
           let coord = Self.countryCoordinates[country.regionCode] {
            return coord
        }
        // 使用者所在國家
        let home = Locale.current.region?.identifier ?? "US"
        if let coord = Self.countryCoordinates[home] {
            return coord
        }
        return CLLocationCoordinate2D(latitude: 39.8, longitude: -98.6)
    }

    private static let countryCoordinates: [String: CLLocationCoordinate2D] = [
        "TW": CLLocationCoordinate2D(latitude: 25.0, longitude: 121.5),
        "JP": CLLocationCoordinate2D(latitude: 36.2, longitude: 138.3),
        "KR": CLLocationCoordinate2D(latitude: 35.9, longitude: 127.8),
        "CN": CLLocationCoordinate2D(latitude: 35.9, longitude: 104.2),
        "HK": CLLocationCoordinate2D(latitude: 22.3, longitude: 114.2),
        "US": CLLocationCoordinate2D(latitude: 39.8, longitude: -98.6),
        "CA": CLLocationCoordinate2D(latitude: 56.1, longitude: -106.3),
        "MX": CLLocationCoordinate2D(latitude: 23.6, longitude: -102.6),
        "GB": CLLocationCoordinate2D(latitude: 55.4, longitude: -3.4),
        "FR": CLLocationCoordinate2D(latitude: 46.2, longitude: 2.2),
        "DE": CLLocationCoordinate2D(latitude: 51.2, longitude: 10.5),
        "IT": CLLocationCoordinate2D(latitude: 41.9, longitude: 12.6),
        "ES": CLLocationCoordinate2D(latitude: 40.5, longitude: -3.7),
        "PT": CLLocationCoordinate2D(latitude: 39.4, longitude: -8.2),
        "NL": CLLocationCoordinate2D(latitude: 52.1, longitude: 5.3),
        "AT": CLLocationCoordinate2D(latitude: 47.5, longitude: 14.6),
        "CH": CLLocationCoordinate2D(latitude: 46.8, longitude: 8.2),
        "AU": CLLocationCoordinate2D(latitude: -25.3, longitude: 133.8),
        "NZ": CLLocationCoordinate2D(latitude: -40.9, longitude: 174.9),
        "TH": CLLocationCoordinate2D(latitude: 15.9, longitude: 100.9),
        "SG": CLLocationCoordinate2D(latitude: 1.4, longitude: 103.8),
        "MY": CLLocationCoordinate2D(latitude: 4.2, longitude: 101.9),
        "VN": CLLocationCoordinate2D(latitude: 14.1, longitude: 108.3),
        "PH": CLLocationCoordinate2D(latitude: 12.9, longitude: 121.8),
        "ID": CLLocationCoordinate2D(latitude: -0.8, longitude: 113.9),
        "IN": CLLocationCoordinate2D(latitude: 20.6, longitude: 79.0),
        "AE": CLLocationCoordinate2D(latitude: 23.4, longitude: 53.8),
        "TR": CLLocationCoordinate2D(latitude: 39.0, longitude: 35.2),
        "BR": CLLocationCoordinate2D(latitude: -14.2, longitude: -51.9),
        "ZA": CLLocationCoordinate2D(latitude: -30.6, longitude: 22.9),
        "EG": CLLocationCoordinate2D(latitude: 26.8, longitude: 30.8),
    ]

    @State private var detectedCountry: CountryInfo?

    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        tappedCoordinate = coordinate
        detectedCountryName = nil
        detectedCountry = nil
        errorMessage = nil
        isLoading = true

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = String(localized: "error.geocodeFailed \(error.localizedDescription)")
                    return
                }

                if let placemark = placemarks?.first {
                    // 優先使用 ISO 國家代碼直接匹配
                    if let isoCode = placemark.isoCountryCode,
                       let country = CountryInfo.countries.first(where: { $0.regionCode == isoCode }) {
                        detectedCountryName = placemark.country
                        detectedCountry = country
                    } else if let countryName = placemark.country {
                        // 回退到名稱匹配
                        detectedCountryName = countryName
                        detectedCountry = CountryInfo.find(byName: countryName)
                    } else {
                        errorMessage = String(localized: "error.countryNotFound")
                    }
                } else {
                    errorMessage = String(localized: "error.countryNotFound")
                }
            }
        }
    }

    private func findMatchingCountry(name: String) -> CountryInfo? {
        // 如果已經透過 ISO code 找到，直接返回
        if let country = detectedCountry {
            return country
        }
        // 否則用名稱查找
        return CountryInfo.find(byName: name)
    }
}

#Preview {
    MapCountryPickerView(selectedCountry: .constant(nil))
}
