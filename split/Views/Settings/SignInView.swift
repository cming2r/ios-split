import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var currentNonce: String?
    @State private var errorMessage: String?

    var body: some View {
        if auth.isAuthenticated {
            signedInSection
        } else {
            signInSection
        }
    }

    // MARK: - Signed In

    private var signedInSection: some View {
        Section {
            NavigationLink {
                AccountDetailView()
            } label: {
                Label(auth.userEmail ?? "", systemImage: "person.crop.circle.fill")
            }
        } header: {
            Text("account")
        }
    }

    // MARK: - Sign In

    private var signInSection: some View {
        Section {
            Button {
                performAppleSignIn()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                    Text("signInWithApple")
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)

            Button {
                Task {
                    do {
                        try await auth.signInWithGoogle()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    GoogleLogo(size: 20)
                    Text("signInWithGoogle")
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        } header: {
            Text("account")
        } footer: {
            Text("signInFooter")
        }
    }

    // MARK: - Apple Sign In

    private func performAppleSignIn() {
        let nonce = AuthService.randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = AuthService.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            handleAppleSignIn(result)
        }
        controller.delegate = delegate
        // Keep delegate alive
        objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        controller.performRequests()
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = String(localized: "auth.error.appleCredential")
                return
            }
            Task {
                do {
                    try await auth.signInWithApple(idToken: idToken, nonce: nonce)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let completion: (Result<ASAuthorization, any Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, any Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        completion(.failure(error))
    }
}

// MARK: - Account Detail View

struct AccountDetailView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Email")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(auth.userEmail ?? "")
                }
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("signOut")
                        Spacer()
                    }
                }
                .confirmationDialog("signOut", isPresented: $showSignOutConfirmation, titleVisibility: .hidden) {
                    Button("signOut", role: .destructive) {
                        Task {
                            try? await auth.signOut()
                            dismiss()
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if isDeleting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("deleteAccount")
                        Spacer()
                    }
                }
                .disabled(isDeleting)
                .confirmationDialog("deleteAccount.confirm", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("deleteAccount", role: .destructive) {
                        isDeleting = true
                        Task {
                            do {
                                try await auth.deleteAccount()
                                dismiss()
                            } catch {
                                deleteError = error.localizedDescription
                                isDeleting = false
                            }
                        }
                    }
                } message: {
                    Text("deleteAccount.message")
                }
            } footer: {
                Text("deleteAccount.footer")
                    .foregroundColor(.secondary)
            }

            if let deleteError {
                Section {
                    Text(deleteError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("account")
        .navigationBarTitleDisplayMode(.inline)
    }
}
