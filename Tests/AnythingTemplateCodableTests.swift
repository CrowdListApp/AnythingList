import Foundation
import Testing

struct AnythingTemplateCodableTests {
    @Test
    func testTemplateDecode_defaultsAndConditionalEncoding() throws {
        let json = """
        {
          "title": "Habit Tracker",
          "fields": [
            {"id": "name", "key": "name", "title": "Habit", "kind": "text"},
            {"id": "last", "key": "lastExecutedAt", "title": "Last Executed", "kind": "dateTime"}
          ]
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(AnythingTemplateDocument.self, from: json)
        #expect(template.version == "1.0")
        #expect(template.symbol == "list.bullet")
        #expect(template.subtitle == "")

        let encoded = try JSONEncoder().encode(template)
        let encodedObject = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        #expect(encodedObject?["subtitle"] == nil)
    }

    @Test
    func testTemplateValidation_duplicateKeysInvalid() {
        let template = AnythingTemplateDocument(
            version: "1.0",
            title: "Bad",
            subtitle: "",
            symbol: "xmark",
            fields: [
                .init(id: "a", key: "dup", title: "A", kind: .text),
                .init(id: "b", key: "dup", title: "B", kind: .text)
            ]
        )

        #expect(template.isValid == false)
    }

    @Test
    func testPayloadDecode_defaultsToEmptyMap() throws {
        let payload = try JSONDecoder().decode(AnythingItemPayload.self, from: Data("{}".utf8))
        #expect(payload.values.isEmpty)
    }

    @Test
    func testSnapshotDecode_defaults() throws {
        let json = """
        {
          "collection": {
            "title": "Book List",
            "symbol": "books.vertical",
            "template": {
              "title": "Book List",
              "fields": [
                {"id":"title","key":"title","title":"Title","kind":"text"}
              ]
            },
            "createdAt": "2026-01-01T00:00:00Z",
            "updatedAt": "2026-01-02T00:00:00Z"
          },
          "items": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(AnythingListSnapshotDocument.self, from: json)

        #expect(snapshot.version == "1.0")
        #expect(snapshot.collection.subtitle == "")
        #expect(snapshot.items.isEmpty)
    }

    @Test
    func testSummaryCalculator_countsRequiredAndURL() {
        let template = AnythingTemplateDocument(
            version: "1.0",
            title: "WWDC Watch Log",
            subtitle: "",
            symbol: "play.rectangle.on.rectangle",
            fields: [
                .init(id: "session", key: "sessionTitle", title: "Session", kind: .text, isRequired: true),
                .init(id: "url", key: "url", title: "URL", kind: .url, isRequired: false)
            ]
        )
        let payloads = [
            ["sessionTitle": "Swift Concurrency", "url": "https://example.com/1"],
            ["sessionTitle": "", "url": "https://example.com/2"]
        ]

        let summary = AnythingListSummaryCalculator.makeSummary(
            template: template,
            itemCount: 2,
            lastExecutedAtValues: [nil, nil],
            payloads: payloads,
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        #expect(summary.itemCount == 2)
        #expect(summary.filledRequiredFieldCount == 1)
        #expect(summary.totalRequiredFieldCount == 2)
        #expect(summary.urlCount == 2)
    }

    @Test
    func testTemplateField_visibleIfDecode() throws {
        let json = """
        {
          "id": "status",
          "key": "statusNote",
          "title": "Status Note",
          "kind": "text",
          "visibleIf": {
            "key": "status",
            "equals": "watching"
          }
        }
        """.data(using: .utf8)!

        let field = try JSONDecoder().decode(AnythingTemplateField.self, from: json)
        #expect(field.visibleIf?.key == "status")
        #expect(field.visibleIf?.equals == "watching")
    }

    @Test
    func testAppBackupDecode_defaults() throws {
        let json = """
        {
          "exportedAt": "2026-01-01T00:00:00Z",
          "collections": [
            {
              "title": "Game Backlog",
              "template": {
                "title": "Game Backlog",
                "fields": [
                  {"id":"title","key":"title","title":"Title","kind":"text"}
                ]
              },
              "createdAt": "2026-01-01T00:00:00Z",
              "updatedAt": "2026-01-02T00:00:00Z",
              "items": [
                {
                  "values": {"title":"Game A"},
                  "createdAt": "2026-01-01T00:00:00Z",
                  "updatedAt": "2026-01-02T00:00:00Z"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(AnythingListAppBackup.self, from: json)

        #expect(backup.version == "1.0")
        #expect(backup.collections.count == 1)
        #expect(backup.collections[0].id == "")
        #expect(backup.collections[0].items[0].id == "")
    }
}
