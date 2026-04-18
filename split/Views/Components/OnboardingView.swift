import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.viewfinder",
            iconColor: .blue,
            titleKey: "onboarding.scan.title",
            descriptionKey: "onboarding.scan.description"
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColor: .orange,
            titleKey: "onboarding.split.title",
            descriptionKey: "onboarding.split.description"
        ),
        OnboardingPage(
            icon: "arrow.triangle.swap",
            iconColor: .green,
            titleKey: "onboarding.settle.title",
            descriptionKey: "onboarding.settle.description"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(page.iconColor)
                            .padding(.bottom, 8)

                        Text(String(localized: String.LocalizationValue(page.titleKey)))
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(String(localized: String.LocalizationValue(page.descriptionKey)))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1
                     ? String(localized: "onboarding.next")
                     : String(localized: "onboarding.getStarted"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text(String(localized: "onboarding.skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
            } else {
                Spacer()
                    .frame(height: 52)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let titleKey: String
    let descriptionKey: String
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
