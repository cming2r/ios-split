import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private static let adUnitID = "ca-app-pub-5238540470214596/4736522869"
    @Binding var isAdLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isAdLoaded: $isAdLoaded)
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = Self.adUnitID
        bannerView.adSize = AdSizeBanner
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    class Coordinator: NSObject, BannerViewDelegate {
        @Binding var isAdLoaded: Bool

        init(isAdLoaded: Binding<Bool>) {
            _isAdLoaded = isAdLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            withAnimation { isAdLoaded = true }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            isAdLoaded = false
        }
    }
}
