import SwiftUI
import GoogleMobileAds

final class AdBannerState: ObservableObject {
    static let shared = AdBannerState()
    @Published var isLoaded = false
    private init() {}
}

struct BannerAdView: UIViewRepresentable {
    private static let adUnitID = "ca-app-pub-5238540470214596/4736522869"
    @Binding var isAdLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isAdLoaded: $isAdLoaded)
    }

    func makeUIView(context: Context) -> BannerContainerView {
        BannerContainerView(adUnitID: Self.adUnitID, delegate: context.coordinator)
    }

    func updateUIView(_ uiView: BannerContainerView, context: Context) {}

    class Coordinator: NSObject, BannerViewDelegate {
        @Binding var isAdLoaded: Bool

        init(isAdLoaded: Binding<Bool>) {
            _isAdLoaded = isAdLoaded
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            withAnimation { isAdLoaded = true }
            AdBannerState.shared.isLoaded = true
            if let container = bannerView.superview as? BannerContainerView {
                container.resetRetry()
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            isAdLoaded = false
            AdBannerState.shared.isLoaded = false
            if let container = bannerView.superview as? BannerContainerView {
                container.scheduleRetry()
            }
        }
    }
}

final class BannerContainerView: UIView {
    private let bannerView = BannerView()
    private var hasLoaded = false
    private var retryCount = 0
    private let maxRetries = 3

    init(adUnitID: String, delegate: BannerViewDelegate) {
        super.init(frame: .zero)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = delegate
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadAdIfNeeded()
    }

    private func loadAdIfNeeded() {
        guard !hasLoaded, bounds.width > 0 else { return }
        hasLoaded = true
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first?.rootViewController
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: bounds.width)
        bannerView.load(Request())
    }

    func resetRetry() {
        retryCount = 0
    }

    func scheduleRetry() {
        guard retryCount < maxRetries else { return }
        retryCount += 1
        let delay = TimeInterval(30 * (1 << (retryCount - 1)))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.bounds.width > 0 else { return }
            self.bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: self.bounds.width)
            self.bannerView.load(Request())
        }
    }
}
