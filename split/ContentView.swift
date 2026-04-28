//
//  ContentView.swift
//  split
//
//  Created by 涂阿銘 on 2026/1/16.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var quickActionManager: QuickActionManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0

    @State private var adRefreshID = UUID().uuidString
    @State private var isAdLoaded = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TripListView(switchToScanTab: { selectedTab = 1 })
                    .tabItem {
                        Image(systemName: "airplane")
                        Text("tab.trips")
                    }
                    .tag(0)

                ScannerView()
                    .tabItem {
                        Image(systemName: "doc.text.viewfinder")
                        Text("tab.scan")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("tab.settings")
                    }
                    .tag(2)
            }

            VStack(spacing: 0) {
                Spacer()
                BannerAdView(isAdLoaded: $isAdLoaded)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .id(adRefreshID)
                    .padding(.bottom, 49)
                    .opacity(isAdLoaded ? 1 : 0)
            }
            .ignoresSafeArea(.keyboard)
        }
        .onChange(of: selectedTab) {
            adRefreshID = UUID().uuidString
        }
        .onChange(of: quickActionManager.selectedAction) { _, newAction in
            handleQuickAction(newAction)
        }
        .onAppear {
            // 處理 App 啟動時的快捷動作
            if let action = quickActionManager.selectedAction {
                handleQuickAction(action)
            }
        }
    }

    private func handleQuickAction(_ action: QuickAction?) {
        guard action != nil else { return }
        // 切換到掃描頁面，具體動作由 ScannerView 處理
        selectedTab = 1
    }
}

#Preview {
    ContentView()
        .environmentObject(QuickActionManager.shared)
}
