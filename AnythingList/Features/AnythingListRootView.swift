import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private struct AnythingTemplateJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct AnythingListSnapshotJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct AnythingListAppBackupJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

@MainActor
struct AnythingListRootView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\AnythingListCollection.updatedAt, order: .reverse)])
    private var collections: [AnythingListCollection]

    @Query(sort: [SortDescriptor(\AnythingListItem.updatedAt, order: .reverse)])
    private var allItems: [AnythingListItem]

    @State private var selectedCollectionID: String?
    @State private var isImportingTemplate = false
    @State private var isImportingListData = false
    @State private var isImportingAppBackup = false
    @State private var exportedTemplate: AnythingTemplateJSONDocument?
    @State private var exportedListData: AnythingListSnapshotJSONDocument?
    @State private var exportedAppBackup: AnythingListAppBackupJSONDocument?
    @State private var isExportingTemplate = false
    @State private var isExportingListData = false
    @State private var isExportingAppBackup = false
    @State private var isShowingSettings = false
    @State private var addItemSheetCollection: AnythingListCollection?
    @State private var alertMessage: String?

    private var selectedCollection: AnythingListCollection? {
        collections.first(where: { $0.id == selectedCollectionID })
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCollectionID) {
                ForEach(collections, id: \.id) { collection in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(collection.title, systemImage: collection.symbol)
                            .font(.headline)
                        if !collection.subtitle.isEmpty {
                            Text(collection.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(collection.id)
                }
                .onDelete(perform: deleteCollections)
            }
            .navigationTitle("AnythingList")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Settings", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(AnythingTemplateLibrary.all, id: \.title) { template in
                            Button(template.title) {
                                createCollection(from: template)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingTemplate,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleTemplateImport(result)
            }
            .fileImporter(
                isPresented: $isImportingListData,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleListDataImport(result)
            }
            .fileImporter(
                isPresented: $isImportingAppBackup,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleAppBackupImport(result)
            }
        } detail: {
            if let collection = selectedCollection {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(collection.title, systemImage: collection.symbol)
                                .font(.title2)
                            if !collection.subtitle.isEmpty {
                                Text(collection.subtitle)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Menu("Export", systemImage: "square.and.arrow.up") {
                            Button("Export Template JSON") {
                                exportTemplate(for: collection)
                            }
                            Button("Export List Data JSON") {
                                exportListData(for: collection)
                            }
                        }
                        Button("Add Item", systemImage: "plus") {
                            addItemSheetCollection = collection
                        }
                    }

                    Divider()

                    let template = decodeTemplate(from: collection)
                    let items = items(for: collection)
                    let payloads = items.map(decodePayload)
                    let summary = AnythingListSummaryCalculator.makeSummary(
                        template: template,
                        itemCount: items.count,
                        lastExecutedAtValues: items.map(\.lastExecutedAt),
                        payloads: payloads,
                        updatedAt: collection.updatedAt
                    )

                    summarySection(summary)

                    if items.isEmpty {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Add your first item using this template.")
                        )
                    } else {
                        List(items, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(template.fields, id: \.id) { field in
                                    let payload = decodePayload(item)
                                    if fieldIsVisible(field, values: payload),
                                       let text = payload[field.key],
                                       !text.isEmpty {
                                        Text("\(field.title): \(text)")
                                            .font(field.kind == .longText ? .subheadline : .body)
                                    }
                                }
                                if let lastExecutedAt = item.lastExecutedAt {
                                    Text("Last Executed: \(lastExecutedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle(collection.title)
            } else {
                ContentUnavailableView(
                    "Select a List",
                    systemImage: "list.bullet.rectangle.portrait",
                    description: Text("Create or import a template to start.")
                )
            }
        }
        .sheet(item: $addItemSheetCollection) { collection in
            AnythingItemFormView(collection: collection) { values, lastExecutedAt in
                saveItem(for: collection, values: values, lastExecutedAt: lastExecutedAt)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            AnythingListSettingsView(
                listCount: collections.count,
                itemCount: allItems.count,
                hasSelectedCollection: selectedCollection != nil,
                onExportAppBackup: exportAppBackup,
                onImportAppBackup: { isImportingAppBackup = true },
                onExportTemplate: {
                    guard let collection = selectedCollection else { return }
                    exportTemplate(for: collection)
                },
                onImportTemplate: { isImportingTemplate = true },
                onExportListData: {
                    guard let collection = selectedCollection else { return }
                    exportListData(for: collection)
                },
                onImportListData: { isImportingListData = true },
                onClearAllLocalLists: clearAllLocalData,
                onCheckConsistency: buildConsistencySummary
            )
        }
        .fileExporter(
            isPresented: $isExportingTemplate,
            document: exportedTemplate,
            contentType: .json,
            defaultFilename: (selectedCollection?.title ?? "vibelist-template").replacingOccurrences(of: " ", with: "-").lowercased()
        ) { _ in
            exportedTemplate = nil
        }
        .fileExporter(
            isPresented: $isExportingListData,
            document: exportedListData,
            contentType: .json,
            defaultFilename: (selectedCollection?.title ?? "vibelist-data").replacingOccurrences(of: " ", with: "-").lowercased()
        ) { _ in
            exportedListData = nil
        }
        .fileExporter(
            isPresented: $isExportingAppBackup,
            document: exportedAppBackup,
            contentType: .json,
            defaultFilename: "vibelist-backup"
        ) { _ in
            exportedAppBackup = nil
        }
        .alert("Template Error", isPresented: .constant(alertMessage != nil), presenting: alertMessage) { _ in
            Button("OK") {
                alertMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    private func createCollection(from template: AnythingTemplateDocument) {
        guard template.isValid else {
            alertMessage = "Template is invalid."
            return
        }
        guard let data = try? makeJSONEncoder().encode(template) else {
            alertMessage = "Failed to encode template."
            return
        }

        let collection = AnythingListCollection(
            title: template.title,
            subtitle: template.subtitle,
            symbol: template.symbol,
            templateData: data,
            updatedAt: .now
        )
        modelContext.insert(collection)
        try? modelContext.save()
        selectedCollectionID = collection.id
    }

    private func deleteCollections(at offsets: IndexSet) {
        for index in offsets {
            let collection = collections[index]
            for item in items(for: collection) {
                modelContext.delete(item)
            }
            modelContext.delete(collection)
        }
        try? modelContext.save()
    }

    private func items(for collection: AnythingListCollection) -> [AnythingListItem] {
        allItems.filter { $0.collectionID == collection.id }
    }

    private func decodeTemplate(from collection: AnythingListCollection) -> AnythingTemplateDocument {
        (try? makeJSONDecoder().decode(AnythingTemplateDocument.self, from: collection.templateData))
        ?? AnythingTemplateDocument(version: "1.0", title: collection.title, subtitle: collection.subtitle, symbol: collection.symbol, fields: [])
    }

    private func decodePayload(_ item: AnythingListItem) -> [String: String] {
        (try? makeJSONDecoder().decode(AnythingItemPayload.self, from: item.payloadData).values) ?? [:]
    }

    private func fieldIsVisible(_ field: AnythingTemplateField, values: [String: String]) -> Bool {
        guard let visibleIf = field.visibleIf else { return true }
        return values[visibleIf.key] == visibleIf.equals
    }

    private func saveItem(for collection: AnythingListCollection, values: [String: String], lastExecutedAt: Date?) {
        guard let data = try? makeJSONEncoder().encode(AnythingItemPayload(values: values)) else { return }
        let item = AnythingListItem(
            collectionID: collection.id,
            payloadData: data,
            lastExecutedAt: lastExecutedAt
        )
        modelContext.insert(item)
        collection.updatedAt = .now
        try? modelContext.save()
    }

    @ViewBuilder
    private func summarySection(_ summary: AnythingListSummary) -> some View {
        HStack(spacing: 12) {
            summaryCard(title: "Items", value: "\(summary.itemCount)")
            summaryCard(title: "Required Fill", value: summary.completionText)
            summaryCard(title: "URLs", value: "\(summary.urlCount)")
            summaryCard(
                title: "Last Executed",
                value: summary.latestExecutedAt?.formatted(date: .abbreviated, time: .shortened) ?? "N/A"
            )
            summaryCard(
                title: "Updated",
                value: summary.latestUpdatedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    @ViewBuilder
    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func exportTemplate(for collection: AnythingListCollection) {
        exportedTemplate = AnythingTemplateJSONDocument(data: collection.templateData)
        isExportingTemplate = true
    }

    private func exportListData(for collection: AnythingListCollection) {
        let template = decodeTemplate(from: collection)
        let snapshotItems: [AnythingListSnapshotItem] = items(for: collection).map { item in
            AnythingListSnapshotItem(
                values: decodePayload(item),
                createdAt: item.createdAt,
                updatedAt: item.updatedAt,
                lastExecutedAt: item.lastExecutedAt
            )
        }
        let snapshot = AnythingListSnapshotDocument(
            version: "1.0",
            collection: AnythingListSnapshotCollection(
                title: collection.title,
                subtitle: collection.subtitle,
                symbol: collection.symbol,
                template: template,
                createdAt: collection.createdAt,
                updatedAt: collection.updatedAt
            ),
            items: snapshotItems,
            exportedAt: .now
        )

        guard let data = try? makeJSONEncoder().encode(snapshot) else {
            alertMessage = "Failed to export list data."
            return
        }
        exportedListData = AnythingListSnapshotJSONDocument(data: data)
        isExportingListData = true
    }

    private func handleTemplateImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let template = try makeJSONDecoder().decode(AnythingTemplateDocument.self, from: data)
                createCollection(from: template)
            } catch {
                alertMessage = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func handleListDataImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let snapshot = try makeJSONDecoder().decode(AnythingListSnapshotDocument.self, from: data)
                guard snapshot.collection.template.isValid else {
                    alertMessage = "Imported list template is invalid."
                    return
                }

                guard let templateData = try? makeJSONEncoder().encode(snapshot.collection.template) else {
                    alertMessage = "Imported list template encoding failed."
                    return
                }

                let newCollection = AnythingListCollection(
                    title: snapshot.collection.title,
                    subtitle: snapshot.collection.subtitle,
                    symbol: snapshot.collection.symbol,
                    templateData: templateData,
                    createdAt: .now,
                    updatedAt: .now
                )
                modelContext.insert(newCollection)

                for importedItem in snapshot.items {
                    guard let payloadData = try? makeJSONEncoder().encode(AnythingItemPayload(values: importedItem.values)) else {
                        continue
                    }
                    let item = AnythingListItem(
                        collectionID: newCollection.id,
                        payloadData: payloadData,
                        createdAt: importedItem.createdAt,
                        updatedAt: importedItem.updatedAt,
                        lastExecutedAt: importedItem.lastExecutedAt
                    )
                    modelContext.insert(item)
                }

                try? modelContext.save()
                selectedCollectionID = newCollection.id
            } catch {
                alertMessage = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            alertMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func exportAppBackup() {
        let backupCollections: [AnythingListBackupCollection] = collections.map { collection in
            let template = decodeTemplate(from: collection)
            let backupItems: [AnythingListBackupItem] = items(for: collection).map { item in
                AnythingListBackupItem(
                    id: item.id,
                    values: decodePayload(item),
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                    lastExecutedAt: item.lastExecutedAt
                )
            }
            return AnythingListBackupCollection(
                id: collection.id,
                title: collection.title,
                subtitle: collection.subtitle,
                symbol: collection.symbol,
                template: template,
                createdAt: collection.createdAt,
                updatedAt: collection.updatedAt,
                items: backupItems
            )
        }

        let backup = AnythingListAppBackup(
            version: "1.0",
            exportedAt: .now,
            collections: backupCollections
        )

        guard let data = try? makeJSONEncoder().encode(backup) else {
            alertMessage = "Failed to export app backup."
            return
        }
        exportedAppBackup = AnythingListAppBackupJSONDocument(data: data)
        isExportingAppBackup = true
    }

    private func handleAppBackupImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                let backup = try makeJSONDecoder().decode(AnythingListAppBackup.self, from: data)
                try replaceLocalData(with: backup)
            } catch {
                alertMessage = "Backup import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            alertMessage = "Backup import failed: \(error.localizedDescription)"
        }
    }

    private func replaceLocalData(with backup: AnythingListAppBackup) throws {
        clearAllLocalData()
        var usedCollectionIDs = Set<String>()
        var usedItemIDs = Set<String>()
        var firstCollectionID: String?

        for backupCollection in backup.collections {
            guard backupCollection.template.isValid else { continue }
            guard let templateData = try? makeJSONEncoder().encode(backupCollection.template) else { continue }

            let candidateCollectionID = backupCollection.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let collectionID: String
            if candidateCollectionID.isEmpty || usedCollectionIDs.contains(candidateCollectionID) {
                collectionID = UUID().uuidString
            } else {
                collectionID = candidateCollectionID
            }
            usedCollectionIDs.insert(collectionID)

            let collection = AnythingListCollection(
                id: collectionID,
                title: backupCollection.title,
                subtitle: backupCollection.subtitle,
                symbol: backupCollection.symbol,
                templateData: templateData,
                createdAt: backupCollection.createdAt,
                updatedAt: backupCollection.updatedAt
            )
            modelContext.insert(collection)
            if firstCollectionID == nil {
                firstCollectionID = collectionID
            }

            for backupItem in backupCollection.items {
                guard let payloadData = try? makeJSONEncoder().encode(AnythingItemPayload(values: backupItem.values)) else {
                    continue
                }
                let candidateItemID = backupItem.id.trimmingCharacters(in: .whitespacesAndNewlines)
                let itemID: String
                if candidateItemID.isEmpty || usedItemIDs.contains(candidateItemID) {
                    itemID = UUID().uuidString
                } else {
                    itemID = candidateItemID
                }
                usedItemIDs.insert(itemID)

                let item = AnythingListItem(
                    id: itemID,
                    collectionID: collectionID,
                    payloadData: payloadData,
                    createdAt: backupItem.createdAt,
                    updatedAt: backupItem.updatedAt,
                    lastExecutedAt: backupItem.lastExecutedAt
                )
                modelContext.insert(item)
            }
        }

        try modelContext.save()
        selectedCollectionID = firstCollectionID
    }

    private func clearAllLocalData() {
        for item in allItems {
            modelContext.delete(item)
        }
        for collection in collections {
            modelContext.delete(collection)
        }
        try? modelContext.save()
        selectedCollectionID = nil
    }

    private func buildConsistencySummary() -> String {
        let collectionIDSet = Set(collections.map(\.id))
        let duplicateCollectionIDs = collections.count - collectionIDSet.count

        let itemIDSet = Set(allItems.map(\.id))
        let duplicateItemIDs = allItems.count - itemIDSet.count

        let orphanItems = allItems.filter { !collectionIDSet.contains($0.collectionID) }.count

        let invalidTemplates = collections.reduce(into: 0) { count, collection in
            if !decodeTemplate(from: collection).isValid {
                count += 1
            }
        }

        let invalidPayloadItems = allItems.reduce(into: 0) { count, item in
            if (try? makeJSONDecoder().decode(AnythingItemPayload.self, from: item.payloadData)) == nil {
                count += 1
            }
        }

        return """
        Consistency Check
        Collections: \(collections.count)
        Items: \(allItems.count)
        Duplicate Collection IDs: \(duplicateCollectionIDs)
        Duplicate Item IDs: \(duplicateItemIDs)
        Orphan Items: \(orphanItems)
        Invalid Templates: \(invalidTemplates)
        Invalid Item Payloads: \(invalidPayloadItems)
        """
    }

    private func makeJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

@MainActor
private struct AnythingItemFormView: View {
    let collection: AnythingListCollection
    let onSave: ([String: String], Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var values: [String: String] = [:]
    @State private var lastExecutedAt: Date = .now
    @State private var includeLastExecutedAt = false

    private var template: AnythingTemplateDocument {
        (try? JSONDecoder().decode(AnythingTemplateDocument.self, from: collection.templateData))
        ?? AnythingTemplateDocument(version: "1.0", title: collection.title, subtitle: collection.subtitle, symbol: collection.symbol, fields: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(template.fields, id: \.id) { field in
                    if fieldIsVisible(field) {
                        fieldView(field)
                    }
                }

                if template.fields.contains(where: { $0.key == "lastExecutedAt" }) {
                    Toggle("Set Last Executed", isOn: $includeLastExecutedAt)
                    if includeLastExecutedAt {
                        DatePicker("Last Executed", selection: $lastExecutedAt)
                    }
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(values, includeLastExecutedAt ? lastExecutedAt : nil)
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fieldView(_ field: AnythingTemplateField) -> some View {
        switch field.kind {
        case .text, .url, .number:
            let textField = TextField(
                field.title,
                text: binding(for: field.key),
                prompt: field.placeholder.isEmpty ? nil : Text(field.placeholder)
            )
#if os(iOS)
            textField
                .textInputAutocapitalization(field.kind == .url ? .never : .sentences)
                .keyboardType(field.kind == .number ? .decimalPad : .default)
#else
            textField
#endif
        case .longText:
            VStack(alignment: .leading) {
                Text(field.title)
                    .font(.headline)
                TextField(field.placeholder.isEmpty ? "" : field.placeholder, text: binding(for: field.key), axis: .vertical)
                    .lineLimit(4...8)
            }
        case .toggle:
            Toggle(field.title, isOn: Binding(
                get: { (values[field.key] ?? "false") == "true" },
                set: { values[field.key] = $0 ? "true" : "false" }
            ))
        case .date:
            DatePicker(field.title, selection: Binding(
                get: {
                    ISO8601DateFormatter().date(from: values[field.key] ?? "") ?? .now
                },
                set: { values[field.key] = ISO8601DateFormatter().string(from: $0) }
            ), displayedComponents: .date)
        case .dateTime:
            DatePicker(field.title, selection: Binding(
                get: {
                    ISO8601DateFormatter().date(from: values[field.key] ?? "") ?? .now
                },
                set: { values[field.key] = ISO8601DateFormatter().string(from: $0) }
            ))
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { values[key, default: ""] },
            set: { values[key] = $0 }
        )
    }

    private func fieldIsVisible(_ field: AnythingTemplateField) -> Bool {
        guard let visibleIf = field.visibleIf else { return true }
        return values[visibleIf.key] == visibleIf.equals
    }
}
