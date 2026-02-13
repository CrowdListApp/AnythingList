import Foundation

struct AnythingListSummary: Hashable {
    let itemCount: Int
    let filledRequiredFieldCount: Int
    let totalRequiredFieldCount: Int
    let urlCount: Int
    let latestExecutedAt: Date?
    let latestUpdatedAt: Date

    var completionText: String {
        guard totalRequiredFieldCount > 0 else { return "N/A" }
        let rate = Double(filledRequiredFieldCount) / Double(totalRequiredFieldCount)
        return "\(Int((rate * 100).rounded()))%"
    }
}

struct AnythingListSummaryCalculator {
    static func makeSummary(
        template: AnythingTemplateDocument,
        itemCount: Int,
        lastExecutedAtValues: [Date?],
        payloads: [[String: String]],
        updatedAt: Date
    ) -> AnythingListSummary {
        let requiredFields = template.fields.filter(\.isRequired)
        var filledRequiredFieldCount = 0
        var totalRequiredFieldCount = 0

        for payload in payloads {
            for field in requiredFields {
                totalRequiredFieldCount += 1
                if let rawValue = payload[field.key], !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    filledRequiredFieldCount += 1
                }
            }
        }

        let urlKeys = Set(template.fields.filter { $0.kind == .url }.map(\.key))
        let urlCount = payloads.reduce(into: 0) { partialResult, payload in
            for key in urlKeys {
                if let rawValue = payload[key], !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    partialResult += 1
                }
            }
        }

        return AnythingListSummary(
            itemCount: itemCount,
            filledRequiredFieldCount: filledRequiredFieldCount,
            totalRequiredFieldCount: totalRequiredFieldCount,
            urlCount: urlCount,
            latestExecutedAt: lastExecutedAtValues.compactMap { $0 }.max(),
            latestUpdatedAt: updatedAt
        )
    }
}
