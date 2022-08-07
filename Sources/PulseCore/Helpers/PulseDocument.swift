// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import CoreData

final class PulseDocument {
    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    private func document() throws -> PulseDocumentEntity {
        guard let document = self._document else {
            throw LoggerStore.Error.unknownError // Programmatic error
        }
        return document
    }

    private var _document: PulseDocumentEntity?

    init(documentURL: URL) throws {
        guard Files.fileExists(atPath: documentURL.deletingLastPathComponent().path) else {
            throw LoggerStore.Error.fileDoesntExist
        }
        self.container = NSPersistentContainer(name: documentURL.lastPathComponent, managedObjectModel: PulseDocument.model)
        let store = NSPersistentStoreDescription(url: documentURL)
        store.setValue("NONE" as NSString, forPragmaNamed: "journal_mode")
        store.setOption(true as NSNumber, forKey: NSSQLiteManualVacuumOption)
        container.persistentStoreDescriptions = [store]

        try container.loadStore()
    }

    /// Opens existing store and returns store info.
    func open() throws -> LoggerStore.Info {
        guard let document = try context.first(PulseDocumentEntity.self) else {
            throw LoggerStore.Error.storeInvalid
        }
        self._document = document
        return try JSONDecoder().decode(LoggerStore.Info.self, from: document.info)
    }

    // Opens an existing database.
    func database() throws -> Data {
        try document().database
    }

    func getBlob(forKey key: String) -> Data? {
        try? context.first(LoggerBlobHandleEntity.self) {
            $0.predicate = NSPredicate(format: "key == %@", key)
        }?.data
    }

    func close() throws {
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            try coordinator.remove(store)
        }
    }

    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let archive = NSEntityDescription(name: "PulseDocumentEntity", class: PulseDocumentEntity.self)
        let blob = NSEntityDescription(name: "PulseBlobEntity", class: PulseBlobEntity.self)

        archive.properties = [
            NSAttributeDescription(name: "info", type: .binaryDataAttributeType),
            NSAttributeDescription(name: "database", type: .binaryDataAttributeType)
        ]

        blob.properties = [
            NSAttributeDescription(name: "key", type: .stringAttributeType),
            NSAttributeDescription(name: "data", type: .binaryDataAttributeType)
        ]

        model.entities = [archive, blob]

        return model
    }()
}

final class PulseDocumentEntity: NSManagedObject {
    @NSManaged var info: Data
    @NSManaged var database: Data
}

final class PulseBlobEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var data: Data
}
