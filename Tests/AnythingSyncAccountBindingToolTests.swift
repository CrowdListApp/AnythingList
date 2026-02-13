import Testing
@testable import AnythingSyncEngine

@MainActor
private struct StubCurrentAccountProvider: AnythingSyncCurrentAccountProviding {
    let currentAccountID: String?

    func fetchCurrentAccountID(containerIdentifier: String) async throws -> String? {
        currentAccountID
    }
}

struct AnythingSyncAccountBindingToolTests {
    @Test @MainActor
    func testFetchBindingState_whenBoundEmpty_canSync() async throws {
        var bound = ""
        let tool = AnythingSyncAccountBindingTool(
            containerIdentifier: "iCloud.anything.lists",
            loadBoundAccountID: { bound },
            saveBoundAccountID: { bound = $0 ?? "" },
            accountProvider: StubCurrentAccountProvider(currentAccountID: "user-1")
        )

        let state = try await tool.fetchBindingState()
        #expect(state.currentAccountID == "user-1")
        #expect(state.boundAccountID == nil)
        #expect(state.canSyncWithCurrentAccount == true)
        #expect(state.isBoundAccountMismatch == false)
    }

    @Test @MainActor
    func testPreviewSwitch_whenMismatch() async throws {
        var bound = "user-old"
        let tool = AnythingSyncAccountBindingTool(
            containerIdentifier: "iCloud.anything.lists",
            loadBoundAccountID: { bound },
            saveBoundAccountID: { bound = $0 ?? "" },
            accountProvider: StubCurrentAccountProvider(currentAccountID: "user-new")
        )

        let preview = try await tool.previewSwitchToCurrentAccount()
        #expect(preview.previousBoundAccountID == "user-old")
        #expect(preview.targetBoundAccountID == "user-new")
        #expect(preview.willEnableSync == true)
        #expect(bound == "user-old")
    }

    @Test @MainActor
    func testSwitchBinding_persistsTargetAccount() async throws {
        var bound = "user-old"
        let tool = AnythingSyncAccountBindingTool(
            containerIdentifier: "iCloud.anything.lists",
            loadBoundAccountID: { bound },
            saveBoundAccountID: { bound = $0 ?? "" },
            accountProvider: StubCurrentAccountProvider(currentAccountID: "user-new")
        )

        let preview = try await tool.switchBindingToCurrentAccount()
        #expect(preview.targetBoundAccountID == "user-new")
        #expect(bound == "user-new")
    }
}
