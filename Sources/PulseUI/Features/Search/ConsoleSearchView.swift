// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse
import CoreData
import Combine

#if os(iOS)

@available(iOS 15, tvOS 15, *)
struct ConsoleSearchView: View {
    @ObservedObject var viewModel: ConsoleSearchViewModel
    let consoleViewModel: ConsoleViewModel

    init(viewModel: ConsoleViewModel) {
        self.consoleViewModel = viewModel
        self.viewModel = viewModel.searchViewModel
    }

    var body: some View {
        Section(header: toolbar) {
            makeList(with: viewModel.topSuggestions)
        }

        if !viewModel.suggestedScopes.isEmpty {
            Section(header: Text("Suggested Scopes")) {
                makeList(with: viewModel.suggestedScopes)
            }
        }

        if viewModel.isNewResultsButtonShown {
            Section {
                Button(action: viewModel.buttonShowNewlyAddedSearchResultsTapped) {
                    HStack {
                        Text("New Results Available")
                        Image(systemName: "arrow.clockwise.circle.fill")
                    }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .padding(.vertical, -8)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
            }
        }

        if !viewModel.parameters.terms.isEmpty {
            ForEach(viewModel.results) { result in
                Section {
                    ConsoleSearchResultView(viewModel: result)
                }
            }
        } else {
            Section {
                ForEach(viewModel.results) { result in
                    ConsoleSearchResultView(viewModel: result)
                }
            }
        }
        if !viewModel.isSearching && viewModel.hasMore {
            Button(action: viewModel.buttonShowMoreResultsTapped) {
                Text("Show More Results")
            }
        }
    }

    private func makeList(with suggestions: [ConsoleSearchSuggestion]) -> some View {
        ForEach(suggestions) { suggestion in
            ConsoleSearchSuggestionView(
                suggestion: suggestion,
                options: $viewModel.options,
                isActionable: viewModel.isActionable(suggestion),
                action: { viewModel.perform(suggestion) }
            )
        }
    }

    private var toolbar: some View {
        ConsoleToolbarView(title: viewModel.toolbarTitle, isSpinnerNeeded: viewModel.isSpinnerNeeded, viewModel: consoleViewModel)
    }
}

#endif