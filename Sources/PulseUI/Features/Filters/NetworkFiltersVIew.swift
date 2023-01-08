// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

#if os(iOS) || os(macOS)

struct NetworkFiltersView: View {
    @ObservedObject var viewModel: ConsoleNetworkSearchCriteriaViewModel
    @ObservedObject var sharedCriteriaViewModel: ConsoleSharedSearchCriteriaViewModel

#if os(iOS)

    @State var isGeneralGroupExpanded = true
    @State var isResponseGroupExpanded = true
    @State var isTimePeriodExpanded = true
    @State var isDomainsGroupExpanded = true
    @State var isDurationGroupExpanded = true
    @State var isContentTypeGroupExpanded = true
    @State var isRedirectGroupExpanded = true

    @Binding var isPresented: Bool

    var body: some View {
        Form {
            formContents
        }
        .navigationBarTitle("Filters", displayMode: .inline)
        .navigationBarItems(leading: buttonReset, trailing: buttonDone)
    }

    private var buttonDone: some View {
        Button("Done") { isPresented = false }
    }

    #else

    @AppStorage("networkFilterIsParametersExpanded") var isGeneralGroupExpanded = true
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
                        buttonReset
                    }
                    Divider()
                }.padding(.top, 6)

                formContents
            }.padding(Filters.formPadding)
        }
    }

    #endif
}

// MARK: - NetworkFiltersView (Contents)

extension NetworkFiltersView {
    @ViewBuilder
    var formContents: some View {
        if #available(iOS 14, *) {
            ConsoleSharedFiltersView(viewModel: sharedCriteriaViewModel)
        }
        if #available(iOS 15, *) {
            generalGroup
        }
        responseGroup
        if #available(iOS 14, *) {
            durationGroup
        }
        domainsGroup
        networkingGroup
    }

    var buttonReset: some View {
        Button("Reset") {
            viewModel.resetAll()
            sharedCriteriaViewModel.resetAll()
        }.disabled(!(viewModel.isButtonResetEnabled || sharedCriteriaViewModel.isButtonResetEnabled))
    }
}

// MARK: - NetworkFiltersView (General)

extension NetworkFiltersView {
    @available(iOS 15, *)
    var generalGroup: some View {
        FiltersSection(
            isExpanded: $isGeneralGroupExpanded,
            header: { generalGroupHeader },
            content: { generalGroupContent },
            isWrapped: false
        )
    }

    private var generalGroupHeader: some View {
        FilterSectionHeader(
            icon: "line.horizontal.3.decrease.circle", title: "Filters",
            color: .yellow,
            reset: { viewModel.resetFilters() },
            isDefault: viewModel.isDefaultFilters,
            isEnabled: $viewModel.criteria.isFiltersEnabled
        )
    }

#if os(iOS)

    @available(iOS 15, *)
    @ViewBuilder
    private var generalGroupContent: some View {
        ForEach(viewModel.filters) { filter in
            CustomNetworkFilterView(filter: filter, onRemove: viewModel.removeFilter, isRemoveHidden: viewModel.isDefaultFilters)
                .buttonStyle(.plain)
        }
        if !viewModel.isDefaultFilters {
            Button(action: viewModel.addFilter) {
                Text("Add Filter").frame(maxWidth: .infinity)
            }
        }
    }

#elseif os(macOS)

    @ViewBuilder
    private var generalGroupContent: some View {
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
    }

#endif
}

// MARK: - NetworkFiltersView (Response)

extension NetworkFiltersView {
    var responseGroup: some View {
        FiltersSection(
            isExpanded: $isResponseGroupExpanded,
            header: { responseGroupHeader },
            content: { responseGroupContent }
        )
    }

    private var responseGroupHeader: some View {
        FilterSectionHeader(
            icon: "arrow.down.circle", title: "Response",
            color: .yellow,
            reset: { viewModel.criteria.response = .default },
            isDefault: viewModel.criteria.response == .default,
            isEnabled: $viewModel.criteria.response.isEnabled
        )
    }

    @ViewBuilder
    private var responseGroupContent: some View {
        statusCodeRow
        contentTypeRow
        responseSizeRow
    }

    @ViewBuilder
    private var contentTypeRow: some View {
        Filters.contentTypesPicker(selection: $viewModel.criteria.response.contentType.contentType)
    }

    #if os(iOS)

    @ViewBuilder
    private var statusCodeRow: some View {
        HStack {
            makeRangePicker(title: "Status Code", from: $viewModel.criteria.response.statusCode.from, to: $viewModel.criteria.response.statusCode.to, isEnabled: $viewModel.criteria.response.isEnabled)
        }
    }

    @ViewBuilder
    private var responseSizeRow: some View {
        HStack {
            makeRangePicker(title: "Size", from: $viewModel.criteria.response.responseSize.from, to: $viewModel.criteria.response.responseSize.to, isEnabled: $viewModel.criteria.response.isEnabled)
            if #available(iOS 14, *) {
                Menu(content: {
                    Filters.sizeUnitPicker($viewModel.criteria.response.responseSize.unit).labelsHidden()
                }, label: {
                    FilterPickerButton(title: viewModel.criteria.response.responseSize.unit.localizedTitle)
                })
                .animation(.none)
                .fixedSize()
            } else {
                Text("KB")
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func makeRangePicker(title: String, from: Binding<String>, to: Binding<String>, isEnabled: Binding<Bool>) -> some View {
        Text(title)

        Spacer()

        TextField("Min", text: from, onEditingChanged: {
            if $0 { isEnabled.wrappedValue = true }
        })
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
        .frame(width: 80)

        TextField("Max", text: to, onEditingChanged: {
            if $0 { isEnabled.wrappedValue = true }
        })
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
        .frame(width: 80)
    }

#elseif os(macOS)

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

#endif
}

// MARK: - NetworkFiltersView (Duration)

extension NetworkFiltersView {
    @available(iOS 14, *)
    var durationGroup: some View {
        FiltersSection(
            isExpanded: $isDurationGroupExpanded,
            header: { durationGroupHeader },
            content: { durationGroupContent }
        )
    }

    private var durationGroupHeader: some View {
        FilterSectionHeader(
            icon: "hourglass", title: "Duration",
            color: .yellow,
            reset: { viewModel.criteria.duration = .default },
            isDefault: viewModel.criteria.duration == .default,
            isEnabled: $viewModel.criteria.duration.isEnabled
        )
    }

#if os(iOS)
    @available(iOS 14, *)
    @ViewBuilder
    private var durationGroupContent: some View {
        HStack {
            Text("Duration")
            Spacer()
            durationMinField
            durationMaxField
            Menu(content: { durationUnitPicker }, label: {
                FilterPickerButton(title: viewModel.criteria.duration.unit.localizedTitle)
            })
            .animation(.none)
        }
    }
#elseif os(macOS)
    @ViewBuilder
    private var durationGroupContent: some View {
        HStack {
            durationMinField
            durationMaxField
            durationUnitPicker.fixedSize().labelsHidden()
        }
    }
#endif

    private var durationMinField: some View {
        TextField("Min", text: $viewModel.criteria.duration.min)
            .textFieldStyle(.roundedBorder)
#if os(iOS)
            .keyboardType(.decimalPad)
            .frame(maxWidth: 80)
#endif
    }

    private var durationMaxField: some View {
        TextField("Max", text: $viewModel.criteria.duration.max)
            .textFieldStyle(.roundedBorder)
#if os(iOS)
            .keyboardType(.decimalPad)
            .frame(maxWidth: 80)
#endif
    }

    private var durationUnitPicker: some View {
        Picker("Unit", selection: $viewModel.criteria.duration.unit) {
            Text("Min").tag(NetworkSearchCriteria.DurationFilter.Unit.minutes)
            Text("Sec").tag(NetworkSearchCriteria.DurationFilter.Unit.seconds)
            Text("Ms").tag(NetworkSearchCriteria.DurationFilter.Unit.milliseconds)
        }
    }
}

// MARK: - NetworkFiltersView (Domains)

extension NetworkFiltersView {
    var domainsGroup: some View {
        FiltersSection(
            isExpanded: $isDomainsGroupExpanded,
            header: { domainsGroupHeader },
            content: { domainsGroupContent }
        )
    }

    private var domainsGroupHeader: some View {
        FilterSectionHeader(
            icon: "server.rack", title: "Hosts",
            color: .yellow,
            reset: { viewModel.criteria.host = .default },
            isDefault: viewModel.criteria.host == .default,
            isEnabled: $viewModel.criteria.host.isEnabled
        )
    }

    @ViewBuilder
    private var domainsGroupContent: some View {
        makeDomainPicker(limit: 4)
        if viewModel.allDomains.count > 4 {
            domainsShowAllButton
        }
    }

    #if os(iOS)
    private var domainsShowAllButton: some View {
        NavigationLink(destination: { domainsPickerView }) {
            Text("Show All")
        }
    }

    private func makeDomainPicker(limit: Int? = nil) -> some View {
        var domains = viewModel.allDomains
        if let limit = limit {
            domains = Array(domains.prefix(limit))
        }
        return ForEach(domains, id: \.self) { domain in
            let binding = viewModel.binding(forDomain: domain)
            Button(action: { binding.wrappedValue.toggle() }) {
                HStack {
                    Text(domain)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Checkbox(isEnabled: binding)
                }
            }
        }
    }
    #elseif os(macOS)
    private var domainsShowAllButton: some View {
        HStack {
            Spacer()
            Button(action: { isDomainsPickerPresented = true }) {
                Text("Show All")
            }
            .padding(.top, 6)
            .popover(isPresented: $isDomainsPickerPresented) {
                domainsPickerView
                    .frame(width: 220, height: 340)
            }
            Spacer()
        }
    }

    private func makeDomainPicker(limit: Int? = nil) -> some View {
        var domains = viewModel.allDomains
        if let limit = limit {
            domains = Array(domains.prefix(limit))
        }
        return ForEach(domains, id: \.self) { domain in
            HStack {
                Toggle(domain, isOn: viewModel.binding(forDomain: domain))
                    .lineLimit(1)
                Spacer()
            }
        }
    }
    #endif

    private var domainsPickerView: some View {
        List {
            Button("Deselect All") {
                viewModel.criteria.host.values = []
            }
            makeDomainPicker()
        }
        #if os(iOS)
        .navigationBarTitle("Select Hosts", displayMode: .inline)
        #else
        .navigationTitle("Select Hosts")
        #endif
    }
}

// MARK: - NetworkFiltersView (Networking)

extension NetworkFiltersView {
    var networkingGroup: some View {
        FiltersSection(
            isExpanded: $isRedirectGroupExpanded,
            header: { networkingGroupHeader },
            content: { networkingGroupContent }
        )
    }

    private var networkingGroupHeader: some View {
        FilterSectionHeader(
            icon: "arrowshape.zigzag.right", title: "Networking",
            color: .yellow,
            reset: { viewModel.criteria.networking = .default },
            isDefault: viewModel.criteria.networking == .default,
            isEnabled: $viewModel.criteria.networking.isEnabled
        )
    }

    @ViewBuilder
    private var networkingGroupContent: some View {
        Filters.taskTypePicker($viewModel.criteria.networking.taskType)
        Filters.responseSourcePicker($viewModel.criteria.networking.source)
        Filters.toggle("Redirect", isOn: $viewModel.criteria.networking.isRedirect)
    }
}

#if DEBUG
struct NetworkFiltersView_Previews: PreviewProvider {
    static var previews: some View {
#if os(iOS)
        NavigationView {
            NetworkFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock), isPresented: .constant(true))
        }
#else
        NetworkFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock))
            .previewLayout(.fixed(width: Filters.preferredWidth - 15, height: 940))
#endif
    }
}

private func makeMockViewModel() -> ConsoleNetworkSearchCriteriaViewModel {
    ConsoleNetworkSearchCriteriaViewModel(store: .mock)

}
#endif

#endif
