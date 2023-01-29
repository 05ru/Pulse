// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import Foundation
import SwiftUI
import Pulse
import CoreData

#warning("this is not reloading")
struct ConsoleEntityDetailsView: View {
    let viewModel: ConsoleListViewModel
    @Binding var selection: NSManagedObjectID?

    var body: some View {
        if let entity = selection.map(viewModel.entity(withID:)) {
            if let task = entity as? NetworkTaskEntity {
                NetworkInspectorView(task: task)
            } else if let message = entity as? LoggerMessageEntity {
                if let task = message.task {
                    NetworkInspectorView(task: task)
                } else {
                    ConsoleMessageDetailsView(message: message)
                }
            }
        }
    }
}
