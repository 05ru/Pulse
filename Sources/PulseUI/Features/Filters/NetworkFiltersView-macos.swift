// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

#if os(macOS)

struct NetworkFiltersView: View {
    @ObservedObject var viewModel: NetworkSearchCriteriaViewModel

    @AppStorage("networkFilterIsParametersExpanded") var isParametersExpanded = true
    @AppStorage("networkFilterIsResponseExpanded") var isResponseGroupExpanded = true
    @AppStorage("networkFilterIsTimePeriodExpanded") var isTimePeriodExpanded = true
    @AppStorage("networkFilterIsDomainsGroupExpanded") var isDomainsGroupExpanded = true
    @AppStorage("networkFilterIsDurationGroupExpanded") var isDurationGroupExpanded = true
    @AppStorage("networkFilterIsContentTypeGroupExpanded") var isContentTypeGroupExpanded = true
    @AppStorage("networkFilterIsRedirectGroupExpanded") var isRedirectGroupExpanded = true

    @State var isDomainsPickerPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: Filters.formSpacing) {
                VStack(spacing: 6) {
                    HStack {
                        Text("FILTERS")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Reset") { viewModel.resetAll() }
                        .disabled(!viewModel.isButtonResetEnabled)
                    }
                    Divider()
                }.padding(.top, 6)
                
                generalGroup
                responseGroup
                durationGroup
                timePeriodGroup
                domainsGroup
                networkingGroup
            }.padding(Filters.formPadding)
        }
    }

    // MARK: - General
    
    private var generalGroup: some View {
        DisclosureGroup(isExpanded: $isParametersExpanded, content: {
            VStack {
                ForEach(viewModel.filters) { filter in
                    CustomNetworkFilterView(filter: filter, onRemove: {
                        viewModel.removeFilter(filter)
                    })
                }
            }
            .padding(.leading, 4)
            .padding(.top, Filters.contentTopInset)
            Button(action: viewModel.addFilter) {
                Image(systemName: "plus.circle")
            }
        }, label: {
            FilterSectionHeader(
                icon: "line.horizontal.3.decrease.circle", title: "General",
                color: .yellow,
                reset: { viewModel.resetFilters() },
                isDefault: viewModel.filters.count == 1 && viewModel.filters[0].isDefault,
                isEnabled: $viewModel.criteria.isFiltersEnabled
            )
        })
    }

    // MARK: - Response
    
    private var responseGroup: some View {
        DisclosureGroup(isExpanded: $isResponseGroupExpanded, content: {
            FiltersSectionContent {
                statusCodeRow
                contentTypeRow
                responseSizeRow
            }
        }, label: {
            FilterSectionHeader(
                icon: "arrow.down.circle", title: "Response",
                color: .yellow,
                reset: { viewModel.criteria.response = .default },
                isDefault: viewModel.criteria.response == .default,
                isEnabled: $viewModel.criteria.response.isEnabled
            )
        })
    }

    @ViewBuilder
    private var statusCodeRow: some View {
        HStack {
            Text("Status Code")
                .fixedSize()

            TextField("Min", text: $viewModel.criteria.response.statusCode.from)
            .textFieldStyle(.roundedBorder)

            TextField("Max", text: $viewModel.criteria.response.statusCode.to)
            .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var contentTypeRow: some View {
        Filters.contentTypesPicker(selection: $viewModel.criteria.response.contentType.contentType)
    }

    @ViewBuilder
    private var responseSizeRow: some View {
        HStack {
            TextField("Min", text: $viewModel.criteria.response.responseSize.from)
            .textFieldStyle(.roundedBorder)

            TextField("Max", text: $viewModel.criteria.response.responseSize.to)
            .textFieldStyle(.roundedBorder)

            Filters.sizeUnitPicker($viewModel.criteria.response.responseSize.unit)
                .labelsHidden()
        }
    }

    // MARK: - Time Period Group

    private var timePeriodGroup: some View {
        DisclosureGroup(isExpanded: $isTimePeriodExpanded, content: {
            FiltersSectionContent {
                HStack {
                    Toggle("Latest Session", isOn: $viewModel.criteria.dates.isCurrentSessionOnly)
                    Spacer()
                }
                startDateRow
                endDateRow
                HStack {
                    Button("Recent") {
                        viewModel.criteria.dates = .recent
                    }
                    Button("Today") {
                        viewModel.criteria.dates = .today
                    }
                    Spacer()
                }.padding(.top, 6)
            }
        }, label: {
            FilterSectionHeader(
                icon: "calendar", title: "Time Period",
                color: .yellow,
                reset: { viewModel.criteria.dates = .default },
                isDefault: viewModel.criteria.dates == .default,
                isEnabled: $viewModel.criteria.dates.isEnabled
            )
        })
    }

    @ViewBuilder
    private var startDateRow: some View {
        let fromBinding = Binding(get: {
            viewModel.criteria.dates.startDate ?? Date().addingTimeInterval(-3600)
        }, set: { newValue in
            viewModel.criteria.dates.startDate = newValue
        })

        VStack(spacing: 5) {
            HStack {
                Toggle("Start Date", isOn: $viewModel.criteria.dates.isStartDateEnabled)
                Spacer()
            }
            DatePicker("Start Date", selection: fromBinding)
                .disabled(!viewModel.criteria.dates.isStartDateEnabled)
                .fixedSize()
                .labelsHidden()
        }
    }

    @ViewBuilder
    private var endDateRow: some View {
        let toBinding = Binding(get: {
            viewModel.criteria.dates.endDate ?? Date()
        }, set: { newValue in
            viewModel.criteria.dates.endDate = newValue
        })

        VStack(spacing: 5) {
            HStack {
                Toggle("End Date", isOn: $viewModel.criteria.dates.isEndDateEnabled)
                Spacer()
            }
            DatePicker("End Date", selection: toBinding)
                .disabled(!viewModel.criteria.dates.isEndDateEnabled)
                .fixedSize()
                .labelsHidden()
        }
    }

    private typealias ContentType = NetworkSearchCriteria.ContentTypeFilter.ContentType
}

#if DEBUG
struct NetworkFiltersPanelPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NetworkFiltersView(viewModel: makeMockViewModel())
                .previewLayout(.fixed(width: Filters.preferredWidth - 15, height: 940))
        }
    }
}

private func makeMockViewModel() -> NetworkSearchCriteriaViewModel {
    let viewModel = NetworkSearchCriteriaViewModel()
    viewModel.setInitialDomains(["api.github.com", "github.com", "apple.com", "google.com", "example.com"])
    return viewModel

}
#endif

#endif
