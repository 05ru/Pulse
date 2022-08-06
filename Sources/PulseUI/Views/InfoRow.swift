// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI

struct InfoRow: View {
    let title: String
    let details: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let details = details {
                Text(details).foregroundColor(.secondary)
            }
        }
    }
}
