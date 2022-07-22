// The MIT License (MIT)
//
// Copyright (c) 2020–2021 Alexander Grebenyuk (github.com/kean).

import Foundation
import PulseCore
import CoreData

private var isAddingItemsDynamically = true
private var isUsingDefaultStore = true

extension LoggerStore {
    static let mock: LoggerStore = {
        let store: LoggerStore = isUsingDefaultStore ? .default : makeMockStore()

        if isAddingItemsDynamically {
            func populate() {
                populateStore(store)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                    populate()
                }
            }
            populate()
        } else {
            populateStore(store)
        }

//        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
//            store.storeMessage(label: "ping", level: .debug, message: "ping", metadata: nil, file: "a", function: "b", line: 2)
//        }

        return store
    }()
}

private func makeMockStore() -> LoggerStore {
    let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent("com.github.kean.pulse-ui-demo")
    try? FileManager.default.removeItem(at: rootURL) // TODO: cleanup
    try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true, attributes: nil)

    let storeURL = rootURL.appendingPathComponent("demo-store.pulse")
    return try! LoggerStore(storeURL: storeURL, options: [.create])
}

private extension NSManagedObject {
    convenience init(using usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}

private struct Logger {
    let label: String
    let store: LoggerStore

    func log(level: LoggerStore.Level, _ message: String, metadata: LoggerStore.Metadata? = nil) {
        self.store.storeMessage(label: label, level: level, message: message, metadata: metadata, file: "", function: "", line: 0)
    }
}

private func populateStore(_ store: LoggerStore) {
    precondition(Thread.isMainThread)

    func logger(named: String) -> Logger {
        Logger(label: named, store: store)
    }

    logger(named: "application")
        .log(level: .info, "UIApplication.didFinishLaunching", metadata: [
            "custom-metadata-key": .string("value")
        ])

    logger(named: "application")
        .log(level: .info, "UIApplication.willEnterForeground")

    logger(named: "auth")
        .log(level: .trace, "Instantiated Session")

    logger(named: "auth")
        .log(level: .trace, "Instantiated the new login request")

    let networkLogger = NetworkLogger(store: store)

    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = [
        "User-Agent": "Pulse Demo/0.19 iOS"
    ]
    let urlSession = URLSession(configuration: configuration)

    func logTask(_ mockTask: MockDataTask) {
        let dataTask = urlSession.dataTask(with: mockTask.request)
        if isAddingItemsDynamically {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1000...6000))) {
                networkLogger.logTaskCreated(dataTask)
//                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 500...2000))) {
//                    networkLogger.logDataTask(dataTask, didReceive: mockTask.response)
//                    networkLogger.logDataTask(dataTask, didReceive: mockTask.responseBody)
//                    networkLogger.logTask(dataTask, didFinishCollecting: mockTask.metrics)
//                    networkLogger.logTask(dataTask, didCompleteWithError: nil, session: urlSession)
//                }
            }
        } else {
            networkLogger.logTaskCreated(dataTask)
            networkLogger.logDataTask(dataTask, didReceive: mockTask.response)
            networkLogger.logDataTask(dataTask, didReceive: mockTask.responseBody)
            networkLogger.logTask(dataTask, didFinishCollecting: mockTask.metrics)
            networkLogger.logTask(dataTask, didCompleteWithError: nil, session: urlSession)
        }
    }

    logTask(MockDataTask.login)

    logger(named: "application")
        .log(level: .debug, "Will navigate to Dashboard")

    logTask(MockDataTask.octocat)

    logTask(MockDataTask.repos)

    logTask(MockDataTask.profileFailure)

    let stackTrace = """
        Replace this implementation with code to handle the error appropriately. fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        2015-12-08 15:04:03.888 Conversion[76776:4410388] call stack:
        (
            0   Conversion                          0x000694b5 -[ViewController viewDidLoad] + 128
            1   UIKit                               0x27259f55 <redacted> + 1028
            ...
            9   UIKit                               0x274f67a7 <redacted> + 134
            10  FrontBoardServices                  0x2b358ca5 <redacted> + 232
            11  FrontBoardServices                  0x2b358f91 <redacted> + 44
            12  CoreFoundation                      0x230e87c7 <redacted> + 14
            ...
            16  CoreFoundation                      0x23038ecd CFRunLoopRunInMode + 108
            17  UIKit                               0x272c7607 <redacted> + 526
            18  UIKit                               0x272c22dd UIApplicationMain + 144
            19  Conversion                          0x000767b5 main + 108
            20  libdyld.dylib                       0x34f34873 <redacted> + 2
        )
        """

    logger(named: "auth")
        .log(level: .warning, .init(stringLiteral: stackTrace))

    if isAddingItemsDynamically {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            logger(named: "default")
                .log(level: .critical, "💥 0xDEADBEEF")
        }
    } else {
        logger(named: "default")
            .log(level: .critical, "💥 0xDEADBEEF")
    }

    // Wait until everything is stored
    store.container.viewContext.performAndWait {}
    store.backgroundContext.performAndWait {
        try? store.backgroundContext.save()
    }
}
