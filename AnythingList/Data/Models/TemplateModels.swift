import Foundation
import MetaCodable

@Codable
enum AnythingTemplateFieldKind: String, CaseIterable {
    case text
    case longText
    case url
    case number
    case toggle
    case date
    case dateTime
}

@Codable
struct AnythingTemplateFieldCondition: Hashable {
    let key: String
    let equals: String
}

@Codable
struct AnythingTemplateField: Hashable, Identifiable {
    @Default(ifMissing: "")
    let id: String
    let key: String
    let title: String
    @Default(ifMissing: AnythingTemplateFieldKind.text)
    let kind: AnythingTemplateFieldKind
    @Default(ifMissing: true)
    let isRequired: Bool
    @Default(ifMissing: "")
    @IgnoreEncoding(if: \String.isEmpty)
    let placeholder: String
    @Default(ifMissing: "")
    @IgnoreEncoding(if: \String.isEmpty)
    let helperText: String
    let visibleIf: AnythingTemplateFieldCondition?

    init(
        id: String,
        key: String,
        title: String,
        kind: AnythingTemplateFieldKind,
        isRequired: Bool = true,
        placeholder: String = "",
        helperText: String = "",
        visibleIf: AnythingTemplateFieldCondition? = nil
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.kind = kind
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.helperText = helperText
        self.visibleIf = visibleIf
    }
}

@Codable
struct AnythingTemplateDocument: Hashable {
    @Default(ifMissing: "1.0")
    let version: String
    let title: String
    @Default(ifMissing: "")
    @IgnoreEncoding(if: \String.isEmpty)
    let subtitle: String
    @Default(ifMissing: "list.bullet")
    let symbol: String
    @Default(ifMissing: [])
    let fields: [AnythingTemplateField]

    var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let keys = fields.map(\.key)
        return Set(keys).count == keys.count && !keys.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
}

@Codable
struct AnythingItemPayload: Hashable {
    @Default(ifMissing: [:])
    let values: [String: String]
}
