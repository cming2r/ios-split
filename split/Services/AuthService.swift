import Foundation
import Supabase
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var userId: UUID?
    @Published var isReady = false

    private let client: SupabaseClient

    private init() {
        self.client = FeedbackService.shared.client
    }

    // MARK: - Session Restore

    func restoreSession() async {
        do {
            let session = try await client.auth.session
            applySession(session)
        } catch {
            clearSession()
        }
        isReady = true
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        applySession(session)
        await claimDeviceData()
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        guard let clientID = googleClientID else {
            throw AuthError.missingGoogleClientID
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingGoogleIDToken
        }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        )
        applySession(session)
        await claimDeviceData()
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
        clearSession()
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let userId else { throw AuthError.notAuthenticated }
        let deviceId = FeedbackService.getDeviceId()

        // 1. 取得所有 trips 的 expenses（收集圖片 URL）
        let tripsData = try await client.from("split_trips")
            .select()
            .eq("user_id", value: userId)
            .execute().data
        let trips: [SplitTrip] = try SplitService.decode([SplitTrip].self, from: tripsData)
        let tripIds = trips.map { $0.id }

        let expenses: [SplitExpense]
        if tripIds.isEmpty {
            expenses = []
        } else {
            let expensesData = try await client.from("split_expenses")
                .select()
                .in("trip_id", values: tripIds.map { $0.uuidString })
                .execute().data
            expenses = try SplitService.decode([SplitExpense].self, from: expensesData)
        }

        // 2. 刪除 R2 圖片
        let imageUrls = expenses.flatMap { $0.receiptImagePaths }
        if !imageUrls.isEmpty {
            await SplitService.deleteR2Images(imageUrls)
        }

        // 3. 刪除 expenses
        let expenseTripIds = Set(expenses.map { $0.tripId })
        for tripId in expenseTripIds {
            _ = try? await client.from("split_expenses")
                .delete()
                .eq("trip_id", value: tripId)
                .execute()
        }

        // 4. 刪除 trips
        _ = try? await client.from("split_trips")
            .delete()
            .eq("user_id", value: userId)
            .execute()

        // 也刪除未登入時的 device trips
        _ = try? await client.from("split_trips")
            .delete()
            .eq("device_id", value: deviceId)
            .is("user_id", value: nil)
            .execute()

        // 5. 登出
        try await client.auth.signOut()
        clearSession()
    }

    // MARK: - Claim Device Data

    /// Assign current device's trips to the authenticated user
    private func claimDeviceData() async {
        guard let userId else { return }
        let deviceId = FeedbackService.getDeviceId()

        do {
            _ = try await client
                .from("split_trips")
                .update(["user_id": userId.uuidString])
                .eq("device_id", value: deviceId)
                .is("user_id", value: nil)
                .execute()
        } catch {
            print("Failed to claim device data: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func applySession(_ session: Session) {
        isAuthenticated = true
        userId = session.user.id
        userEmail = session.user.email
    }

    private func clearSession() {
        isAuthenticated = false
        userId = nil
        userEmail = nil
    }

    private var googleClientID: String? {
        guard let path = Bundle.main.path(forResource: "APICredentials", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let google = dict["Google"] as? [String: String] else { return nil }
        return google["ClientID"]
    }

    // MARK: - Apple Nonce Helpers

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingGoogleClientID
    case missingGoogleIDToken
    case noRootViewController
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .missingGoogleClientID:
            return String(localized: "auth.error.missingGoogleClientID")
        case .missingGoogleIDToken:
            return String(localized: "auth.error.missingGoogleIDToken")
        case .noRootViewController:
            return String(localized: "auth.error.noRootViewController")
        case .notAuthenticated:
            return String(localized: "auth.error.notAuthenticated")
        }
    }
}
