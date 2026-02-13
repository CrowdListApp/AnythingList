import Foundation
import SwiftData

@Model
final class AnythingListCollection {
    @Attribute(.unique) var id: String
    var title: String
    var subtitle: String
    var symbol: String
    var templateData: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        symbol: String,
        templateData: Data,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.templateData = templateData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class AnythingListItem {
    @Attribute(.unique) var id: String
    var collectionID: String
    var payloadData: Data
    var createdAt: Date
    var updatedAt: Date
    var lastExecutedAt: Date?

    init(
        id: String = UUID().uuidString,
        collectionID: String,
        payloadData: Data,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastExecutedAt: Date? = nil
    ) {
        self.id = id
        self.collectionID = collectionID
        self.payloadData = payloadData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastExecutedAt = lastExecutedAt
    }
}
