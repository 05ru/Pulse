// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleFiltersView: View {
    let viewModel: ConsoleViewModel

    var body: some View {
        switch viewModel.mode {
        case .all:
            ConsoleMessageFiltersView(viewModel: viewModel.searchCriteriaViewModel, sharedCriteriaViewModel: viewModel.sharedSearchCriteriaViewModel)
#if os(macOS)
                .frame(width: ConsoleFilters.preferredWidth - 20)
#endif
        case .network:
            ConsoleNetworkFiltersView(viewModel: viewModel.networkSearchCriteriaViewModel, sharedCriteriaViewModel: viewModel.sharedSearchCriteriaViewModel)
#if os(macOS)
                .frame(width: ConsoleFilters.preferredWidth)
#endif
        }
    }
}
