import CloudKit

enum CloudSyncConfig {
    enum Container {
        static let appIdentifier = "iCloud.anything.lists"
        static let testIdentifier = "iCloud.anything.lists"
        static let identifier = appIdentifier
    }

    enum Zone {
        static let appName = "Lists"
        static let testName = "Lists.test"
        static let name = appName
        static let id = CKRecordZone.ID(zoneName: name)

        static func id(zoneName: String) -> CKRecordZone.ID {
            CKRecordZone.ID(zoneName: zoneName)
        }
    }

    enum RecordType {
        static let listCollection: CKRecord.RecordType = "AnythingListCollection"
        static let listItem: CKRecord.RecordType = "AnythingListItem"
        static let metadata: CKRecord.RecordType = "AnythingSyncMetadata"
    }

    enum RecordName {
        static let collectionPrefix = "lc_"
        static let itemPrefix = "li_"
        static let metadataPrimary = "metadata_primary"

        static func collection(_ id: String) -> String {
            "\(collectionPrefix)\(id)"
        }

        static func item(_ id: String) -> String {
            "\(itemPrefix)\(id)"
        }
    }

    enum LocalState {
        static let bindingAccountID = "sync.binding_account_id"
        static let primary = "primary"
    }
}

extension CKRecord.FieldKey {
    static let collection_id = "id"
    static let collection_title = "title"
    static let collection_subtitle = "subtitle"
    static let collection_symbol = "symbol"
    static let collection_templateData = "templateData"
    static let collection_createdAt = "createdAt"
    static let collection_updatedAt = "updatedAt"

    static let item_id = "id"
    static let item_collectionID = "collectionID"
    static let item_payloadData = "payloadData"
    static let item_createdAt = "createdAt"
    static let item_updatedAt = "updatedAt"
    static let item_lastExecutedAt = "lastExecutedAt"

    static let metadata_boundAccountID = "boundAccountID"
    static let metadata_updatedAt = "updatedAt"
}
