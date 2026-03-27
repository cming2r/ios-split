import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: FeedbackCategory = .feature
    @State private var subject = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var myMessages: [ContactMessage] = []
    @State private var showMyMessages = false

    private let service = FeedbackService.shared

    var body: some View {
        Form {
            // 類別選擇
            Section("feedback.category") {
                Menu {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            // 主旨
            Section("feedback.subject") {
                TextField("feedback.subject.placeholder", text: $subject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 詳細內容
            Section("feedback.details") {
                TextEditor(text: $message)
                    .frame(minHeight: 150)
                    .overlay(
                        Group {
                            if message.isEmpty {
                                Text("feedback.details.placeholder")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            // 提交按鈕
            Section {
                Button(action: submitContact) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("feedback.submitting")
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("feedback.submit")
                        }
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isSubmitting)
                .listRowBackground(Color.clear)
            }

            // 查看我的回饋記錄
            Section {
                Button(action: loadMyMessages) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("feedback.myRecords")
                        Spacer()
                        if !myMessages.isEmpty {
                            Text("\(myMessages.count)")
                                .foregroundColor(.white)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .navigationTitle("feedback.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("feedback.submitSuccess", isPresented: $showSuccessAlert) {
            Button("ok") {
                dismiss()
            }
        } message: {
            Text("feedback.thankYou")
        }
        .alert("feedback.submitFailed", isPresented: $showErrorAlert) {
            Button("ok") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showMyMessages) {
            ContactRecordsView(messages: myMessages)
        }
    }

    // MARK: - Computed
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions
    private func submitContact() {
        guard isFormValid else { return }
        isSubmitting = true

        Task {
            do {
                let ipAddress = await FeedbackService.fetchIPAddress()

                let contactMessage = ContactMessage(
                    category: selectedCategory,
                    subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                    message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                    deviceId: FeedbackService.getDeviceId(),
                    appFrom: "WhoSplit",
                    clientInfo: FeedbackService.buildClientInfo(),
                    ipAddress: ipAddress,
                    countryCode: FeedbackService.getCountryCode()
                )

                _ = try await service.createContactMessage(contactMessage)

                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    private func loadMyMessages() {
        Task {
            do {
                let deviceId = FeedbackService.getDeviceId()
                let messages = try await service.fetchUserMessages(deviceId: deviceId)
                myMessages = messages
                showMyMessages = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Contact Records View
struct ContactRecordsView: View {
    @Environment(\.dismiss) var dismiss
    @State var messages: [ContactMessage]
    @State private var showDeleteAlert = false
    @State private var messageToDelete: ContactMessage?

    private let service = FeedbackService.shared

    var body: some View {
        NavigationStack {
            List {
                if messages.isEmpty {
                    Text("feedback.noRecords")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(messages) { msg in
                        messageRow(msg)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            let msg = messages[index]
                            if msg.status == .pending {
                                messageToDelete = msg
                                showDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("feedback.myRecords.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close") {
                        dismiss()
                    }
                }
            }
            .alert("feedback.deleteConfirmTitle", isPresented: $showDeleteAlert) {
                Button("cancel", role: .cancel) { }
                Button("delete", role: .destructive) {
                    if let msg = messageToDelete {
                        deleteMessage(msg)
                    }
                }
            } message: {
                Text("feedback.deleteConfirm")
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ msg: ContactMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(msg.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(msg.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(for: msg.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }

            Text(msg.subject)
                .font(.headline)

            Text(msg.message)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if let createdAt = msg.createdAt {
                Text(formatDate(createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let adminNotes = msg.adminNotes, !adminNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("feedback.officialReply")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(adminNotes)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteMessage(_ msg: ContactMessage) {
        Task {
            do {
                try await service.deleteMessage(id: msg.id)
                await MainActor.run {
                    messages.removeAll { $0.id == msg.id }
                }
            } catch {
                print("Delete failed: \(error.localizedDescription)")
            }
        }
    }

    private func statusColor(for status: FeedbackStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .read: return .blue
        case .replied: return .green
        case .closed: return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ContactView()
    }
}
