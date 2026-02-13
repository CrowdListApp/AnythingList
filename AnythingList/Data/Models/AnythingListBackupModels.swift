import Foundation
import MetaCodable

@Codable
struct AnythingListBackupItem: Hashable {
    @Default(ifMissing: "")
    let id: String
    @Default(ifMissing: [:])
    let values: [String: String]
    let createdAt: Date
    let updatedAt: Date
    let lastExecutedAt: Date?
}

@Codable
struct AnythingListBackupCollection: Hashable {
    @Default(ifMissing: "")
    let id: String
    let title: String
    @Default(ifMissing: "")
    @IgnoreEncoding(if: \String.isEmpty)
    let subtitle: String
    @Default(ifMissing: "list.bullet")
    let symbol: String
    let template: AnythingTemplateDocument
    let createdAt: Date
    let updatedAt: Date
    @Default(ifMissing: [])
    let items: [AnythingListBackupItem]
}

@Codable
struct AnythingListAppBackup: Hashable {
    @Default(ifMissing: "1.0")
    let version: String
    let exportedAt: Date
    @Default(ifMissing: [])
    let collections: [AnythingListBackupCollection]
}
