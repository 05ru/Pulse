// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import CoreData
import Pulse
import Combine
import SwiftUI

#warning("container for ConsoleVieWModl that doesn't refresh itself")
#warning("rework public API")

final class ConsoleViewModel: ObservableObject {
    let title: String
    let isNetworkModeEnabled: Bool
    let store: LoggerStore

    let list: ConsoleListViewModel

#if os(iOS)
    let insightsViewModel: InsightsViewModel
    @available(iOS 15, tvOS 15, *)
    var searchViewModel: ConsoleSearchViewModel {
        _searchViewModel as! ConsoleSearchViewModel
    }
    private var _searchViewModel: AnyObject?
#endif

    let searchBarViewModel: ConsoleSearchBarViewModel
    let searchCriteriaViewModel: ConsoleSearchCriteriaViewModel

    #warning("reimplement this")
    var toolbarTitle: String {
        let suffix = searchCriteriaViewModel.isOnlyNetwork ? "Requests" : "Messages"
        return "\(0) \(suffix)"
    }

    var isViewVisible: Bool = false {
        didSet { refreshListsVisibility() }
    }

    var isSearching = false {
        didSet { refreshListsVisibility() }
    }

    // Filters
    #warning("remove")
    @Published var isShowingFilters = false

    var onDismiss: (() -> Void)?

    private var cancellables: [AnyCancellable] = []

    init(store: LoggerStore, isOnlyNetwork: Bool = false) {
        self.title = isOnlyNetwork ? "Network" : "Console"
        self.store = store
        self.isNetworkModeEnabled = isOnlyNetwork

        self.searchCriteriaViewModel = ConsoleSearchCriteriaViewModel(store: store)
        self.searchBarViewModel = ConsoleSearchBarViewModel()
        self.list = ConsoleListViewModel(store: store, criteria: searchCriteriaViewModel)

#if os(iOS)
        self.insightsViewModel = InsightsViewModel(store: store)
        if #available(iOS 15, *) {
            self._searchViewModel = ConsoleSearchViewModel(entities: list.entitiesSubject, store: store, searchBar: searchBarViewModel)
        }
#endif

        searchCriteriaViewModel.bind(list.$entities)

        #warning("move filterTerm")

    }

    // MARK: Refresh

    private func refreshListsVisibility() {
        list.isViewVisible = !isSearching && isViewVisible
        if #available(iOS 15, tvOS 15, *) {
            searchViewModel.isViewVisible = isSearching && isViewVisible
        }
    }

#warning("reomplement")
    private func refreshList() {
        // important: order
//        refresh(filterTerm: filterTerm)
#if os(iOS)
        if #available(iOS 15, *) {
            searchViewModel.refreshNow()
        }
#endif
    }

    #warning("remove")
    private func refresh(filterTerm: String) {
        list.refresh()
    }

    // MARK: - Sharing

    func prepareForSharing(as output: ShareOutput, _ completion: @escaping (ShareItems?) -> Void) {
        ShareService.share(list.entities, store: store, as: output, completion)
    }
}
