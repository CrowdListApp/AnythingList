import SwiftUI
import CloudKit
import AnythingSyncEngine

struct AnythingListSettingsView: View {
    let listCount: Int
    let itemCount: Int
    let hasSelectedCollection: Bool
    let onExportAppBackup: () -> Void
    let onImportAppBackup: () -> Void
    let onExportTemplate: () -> Void
    let onImportTemplate: () -> Void
    let onExportListData: () -> Void
    let onImportListData: () -> Void
    let onClearAllLocalLists: () -> Void
    let onCheckConsistency: () -> String

    @Environment(\.dismiss) private var dismiss
    @AppStorage(CloudSyncConfig.LocalState.bindingAccountID) private var bindingAccountIDStorage = ""
    @State private var showClearConfirm = false
    @State private var showDeleteServerConfirm = false
    @State private var showSwitchAccountConfirm = false
    @State private var isBusy = false
    @State private var currentAccountID: String?
    @State private var boundAccountID: String?
    @State private var pendingSwitchPreview: AnythingSyncBindingSwitchPreview?
    @State private var infoMessage: String?
    @State private var errorMessage: String?

    private let container = CKContainer(identifier: CloudSyncConfig.Container.identifier)

    private var bindingState: AnythingSyncBindingState {
        AnythingSyncBindingState(
            currentAccountID: currentAccountID,
            boundAccountID: boundAccountID
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Overview") {
                    LabeledContent("Lists") { Text("\(listCount)") }
                    LabeledContent("Items") { Text("\(itemCount)") }
                }

                Section("Account Binding") {
                    LabeledContent("Current iCloud Account") {
                        Text(currentAccountID ?? "Not signed in")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Bound Account") {
                        Text(boundAccountID ?? "Unbound")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Sync Gate") {
                        Text(bindingState.canSyncWithCurrentAccount ? "Enabled" : "Disabled")
                            .foregroundStyle(bindingState.canSyncWithCurrentAccount ? .green : .orange)
                    }

                    Button("Refresh Account Status") {
                        Task { await refreshAccountState() }
                    }
                    .disabled(isBusy)

                    if bindingState.isBoundAccountMismatch {
                        Button("Switch To Current iCloud Account", role: .destructive) {
                            Task { await previewSwitchBindingToCurrentAccount() }
                        }
                        .disabled(isBusy)
                    }

                    Button("Check Consistency") {
                        runConsistencyCheck()
                    }
                    .disabled(isBusy)
                }

                Section("Backup") {
                    Button("Export App Backup") {
                        onExportAppBackup()
                    }
                    Button("Import App Backup (Replace Local Data)") {
                        onImportAppBackup()
                    }
                }

                Section("Template") {
                    Button("Export Selected List Template") {
                        onExportTemplate()
                    }
                    .disabled(!hasSelectedCollection)
                }

                Section("List Data") {
                    Button("Export Selected List Data") {
                        onExportListData()
                    }
                    .disabled(!hasSelectedCollection)
                }

                Section("Lab") {
                    Button("Import Template JSON") {
                        onImportTemplate()
                    }
                    Button("Import List Data JSON") {
                        onImportListData()
                    }
                }

                Section("Danger Zone") {
                    Button("Delete Server Data", role: .destructive) {
                        showDeleteServerConfirm = true
                    }
                    .disabled(isBusy)
                    Button("Clear All Local Lists", role: .destructive) {
                        showClearConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await refreshAccountState()
            }
            .confirmationDialog(
                "Clear All Local Lists",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    onClearAllLocalLists()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all local lists and items on this device.")
            }
            .confirmationDialog(
                "Switch Account Binding",
                isPresented: $showSwitchAccountConfirm,
                titleVisibility: .visible
            ) {
                Button("Confirm Switch", role: .destructive) {
                    Task { await switchBindingToCurrentAccount() }
                }
                Button("Cancel", role: .cancel) {
                    pendingSwitchPreview = nil
                }
            } message: {
                Text(switchPreviewMessage)
            }
            .confirmationDialog(
                "Delete Server Data",
                isPresented: $showDeleteServerConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Server Data", role: .destructive) {
                    Task { await deleteServerData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear CloudKit data in the app zone. Other active devices may re-upload data.")
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(errorMessage ?? "") }
            )
            .alert(
                "Info",
                isPresented: Binding(
                    get: { infoMessage != nil },
                    set: { if !$0 { infoMessage = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(infoMessage ?? "") }
            )
        }
#if os(macOS)
        .frame(minWidth: 520, minHeight: 460)
#endif
    }

    private func refreshAccountState() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let state = try await makeBindingTool().fetchBindingState()
            currentAccountID = state.currentAccountID
            boundAccountID = state.boundAccountID
        } catch {
            currentAccountID = nil
            boundAccountID = nil
            errorMessage = "Failed to refresh account status: \(error.localizedDescription)"
        }
    }

    private func previewSwitchBindingToCurrentAccount() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let preview = try await makeBindingTool().previewSwitchToCurrentAccount()
            guard preview.currentAccountID != nil else {
                errorMessage = "No signed-in iCloud account available."
                return
            }
            pendingSwitchPreview = preview
            showSwitchAccountConfirm = true
        } catch {
            errorMessage = "Failed to preview account switch: \(error.localizedDescription)"
        }
    }

    private func switchBindingToCurrentAccount() async {
        isBusy = true
        defer { isBusy = false }

        do {
            let preview = try await makeBindingTool().switchBindingToCurrentAccount()
            pendingSwitchPreview = preview
            await refreshAccountState()
            infoMessage = "Bound account switched to current iCloud account."
        } catch {
            errorMessage = "Switch failed: \(error.localizedDescription)"
        }
    }

    private func deleteServerData() async {
        isBusy = true
        defer { isBusy = false }

        do {
            try await resetServerZone()
            infoMessage = "Server data deleted."
        } catch {
            errorMessage = "Delete server data failed: \(error.localizedDescription)"
        }
    }

    private func resetServerZone() async throws {
        let database = container.privateCloudDatabase
        let zoneID = CloudSyncConfig.Zone.id

        do {
            try await modifyZones(
                in: database,
                recordZonesToSave: nil,
                recordZoneIDsToDelete: [zoneID]
            )
        } catch {
            let ckError = error as? CKError
            if ckError?.code != .zoneNotFound {
                throw error
            }
        }

        try await modifyZones(
            in: database,
            recordZonesToSave: [CKRecordZone(zoneID: zoneID)],
            recordZoneIDsToDelete: nil
        )
    }

    private func modifyZones(
        in database: CKDatabase,
        recordZonesToSave: [CKRecordZone]?,
        recordZoneIDsToDelete: [CKRecordZone.ID]?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordZonesOperation(
                recordZonesToSave: recordZonesToSave,
                recordZoneIDsToDelete: recordZoneIDsToDelete
            )
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func runConsistencyCheck() {
        let summary = onCheckConsistency()
        infoMessage = summary
    }

    private var switchPreviewMessage: String {
        guard let preview = pendingSwitchPreview else { return "No preview data." }
        let current = preview.currentAccountID ?? "Not signed in"
        let previous = preview.previousBoundAccountID ?? "Unbound"
        let target = preview.targetBoundAccountID ?? "Unbound"
        let gate = preview.willEnableSync ? "Enabled" : "Disabled"
        return """
        Current: \(current)
        Bound: \(previous)
        After switch: \(target)
        Sync Gate after switch: \(gate)
        """
    }

    private func makeBindingTool() -> AnythingSyncAccountBindingTool {
        AnythingSyncAccountBindingTool(
            containerIdentifier: CloudSyncConfig.Container.identifier,
            loadBoundAccountID: {
                let trimmed = bindingAccountIDStorage.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            },
            saveBoundAccountID: { newValue in
                bindingAccountIDStorage = newValue ?? ""
            }
        )
    }
}
