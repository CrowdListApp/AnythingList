import Foundation
import MetaCodable

@Codable
struct AnythingListSnapshotCollection: Hashable {
    let title: String
    @Default(ifMissing: "")
    @IgnoreEncoding(if: \String.isEmpty)
    let subtitle: String
    @Default(ifMissing: "list.bullet")
    let symbol: String
    let template: AnythingTemplateDocument
    let createdAt: Date
    let updatedAt: Date
}

@Codable
struct AnythingListSnapshotItem: Hashable {
    @Default(ifMissing: [:])
    let values: [String: String]
    let createdAt: Date
    let updatedAt: Date
    let lastExecutedAt: Date?
}

@Codable
struct AnythingListSnapshotDocument: Hashable {
    @Default(ifMissing: "1.0")
    let version: String
    let collection: AnythingListSnapshotCollection
    @Default(ifMissing: [])
    let items: [AnythingListSnapshotItem]
    @Default(ifMissing: Date(timeIntervalSince1970: 0))
    let exportedAt: Date
}
