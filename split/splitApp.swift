//
//  splitApp.swift
//  split
//
//  Created by 涂阿銘 on 2026/1/16.
//

import SwiftUI
import UIKit
import GoogleSignIn

// MARK: - 快捷動作類型
enum QuickAction: String {
    case scanReceipt = "ScanReceipt"
    case addExpense = "AddExpense"
}

// MARK: - 快捷動作管理器
@MainActor
class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    @Published var selectedAction: QuickAction?

    private init() {}

    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if let action = QuickAction(rawValue: shortcutItem.type) {
            selectedAction = action
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // 處理冷啟動時的快捷動作
        if let shortcutItem = options.shortcutItem {
            Task { @MainActor in
                QuickActionManager.shared.handleShortcutItem(shortcutItem)
            }
        }

        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 設定快捷動作
        setupQuickActions(for: application)
        return true
    }

    private func setupQuickActions(for application: UIApplication) {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickAction.scanReceipt.rawValue,
                localizedTitle: String(localized: "scanReceipt"),
                localizedSubtitle: String(localized: "quickAction.scanReceipt.subtitle"),
                icon: UIApplicationShortcutIcon(systemImageName: "doc.text.viewfinder"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickAction.addExpense.rawValue,
                localizedTitle: String(localized: "manualEntry"),
                localizedSubtitle: String(localized: "quickAction.addExpense.subtitle"),
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
                userInfo: nil
            )
        ]
    }
}

// MARK: - Scene Delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        Task { @MainActor in
            QuickActionManager.shared.handleShortcutItem(shortcutItem)
        }
        completionHandler(true)
    }
}

@main
struct splitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var quickActionManager = QuickActionManager.shared
    @AppStorage("appAppearance") private var appAppearance: String = AppAppearance.light.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(quickActionManager)
                .preferredColorScheme((AppAppearance(rawValue: appAppearance) ?? .light).colorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await AuthService.shared.restoreSession()
                }
        }
    }
}
