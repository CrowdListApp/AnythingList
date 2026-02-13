import SwiftData
import SwiftUI

@main
struct AnythingListApp: App {
    private enum LocalStoreConfig {
        static let appGroupID = "group.dt.anything"
        static let relativeStoreFolder = "Documents/data/lists"
        static let sqliteFilename = "lists.sqlite"
    }

    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            AnythingListCollection.self,
            AnythingListItem.self
        ])
        let storeURL = Self.makeSwiftDataStoreURL()
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AnythingListRootView()
        }
#if os(macOS)
        .defaultSize(width: 1180, height: 760)
#endif
        .modelContainer(sharedModelContainer)
    }

    private static func makeSwiftDataStoreURL() -> URL {
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: LocalStoreConfig.appGroupID
        ) else {
            fatalError("Could not resolve App Group container: \(LocalStoreConfig.appGroupID)")
        }

        let storeFolderURL = appGroupURL
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("lists", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: storeFolderURL,
                withIntermediateDirectories: true
            )
        } catch {
            fatalError("Could not create SwiftData directory: \(error)")
        }

        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutableFolderURL = storeFolderURL
            try mutableFolderURL.setResourceValues(values)
        } catch {
            fatalError("Could not set backup exclusion on SwiftData directory: \(error)")
        }

        return storeFolderURL.appendingPathComponent(LocalStoreConfig.sqliteFilename)
    }
}
