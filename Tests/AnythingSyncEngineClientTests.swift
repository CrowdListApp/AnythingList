import CloudKit
import Foundation
import Testing
@testable import AnythingSyncEngine

@MainActor
private final class InMemoryStateStore: AnythingSyncStateStore {
    var loadCalls = 0
    var clearCalls = 0

    func loadStateSerialization() -> CKSyncEngine.State.Serialization? {
        loadCalls += 1
        return nil
    }

    func persistStateSerialization(_ serialization: CKSyncEngine.State.Serialization) {}

    func clearStateSerialization() {
        clearCalls += 1
    }
}

@MainActor
private final class StubAccountStatusProvider: AnythingSyncAccountStatusProviding {
    let status: CKAccountStatus
    var calls = 0
    var receivedContainer: CKContainer?

    init(status: CKAccountStatus) {
        self.status = status
    }

    func accountStatus(for container: CKContainer) async throws -> CKAccountStatus {
        calls += 1
        receivedContainer = container
        return status
    }
}

@MainActor
private final class NoopSyncDelegate: NSObject, CKSyncEngineDelegate {
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {}

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        nil
    }
}

struct AnythingSyncEngineClientTests {
    @Test @MainActor
    func testAccountStatus_usesInjectedProvider() async throws {
        let stateStore = InMemoryStateStore()
        let provider = StubAccountStatusProvider(status: .available)
        let client = AnythingSyncEngineClient(
            configuration: AnythingSyncEngineConfiguration(
                containerIdentifier: CloudSyncConfig.Container.testIdentifier,
                zoneName: CloudSyncConfig.Zone.testName,
                automaticallySync: false
            ),
            stateStore: stateStore,
            accountStatusProvider: provider
        )

        let status = try await client.accountStatus()

        #expect(status == .available)
        #expect(provider.calls == 1)
        #expect(provider.receivedContainer != nil)
        #expect(stateStore.loadCalls == 0)
    }

    @Test @MainActor
    func testSyncEngine_reinitializeWithoutEngineCreation_keepsStorageEmpty() throws {
        let stateStore = InMemoryStateStore()
        let client = AnythingSyncEngineClient(
            configuration: AnythingSyncEngineConfiguration(
                containerIdentifier: CloudSyncConfig.Container.testIdentifier,
                zoneName: CloudSyncConfig.Zone.testName,
                automaticallySync: false
            ),
            stateStore: stateStore,
            delegate: NoopSyncDelegate()
        )

        #expect(client.loadedSyncEngine == nil)
        #expect(stateStore.loadCalls == 0)

        client.reinitializeSyncEngine()

        #expect(client.loadedSyncEngine == nil)
        #expect(stateStore.loadCalls == 0)
    }

    @Test @MainActor
    func testClearPersistedStateSerialization_forwardsToStateStore() throws {
        let stateStore = InMemoryStateStore()
        let client = AnythingSyncEngineClient(
            configuration: AnythingSyncEngineConfiguration(
                containerIdentifier: CloudSyncConfig.Container.testIdentifier,
                zoneName: CloudSyncConfig.Zone.testName,
                automaticallySync: false
            ),
            stateStore: stateStore
        )

        client.clearPersistedStateSerialization()

        #expect(stateStore.clearCalls == 1)
    }
}
