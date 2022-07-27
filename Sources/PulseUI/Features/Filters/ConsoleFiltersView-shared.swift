// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

#if os(iOS) || os(macOS)

// MARK: - ConsoleFiltersView (Contents)

extension ConsoleFiltersView {
    @ViewBuilder
    var formContents: some View {
        if #available(iOS 14.0, *) {
            generalSection
        }
        logLevelsSection
        labelsSection
        timePeriodSection
    }

    var buttonReset: some View {
        Button("Reset") { viewModel.resetAll() }
            .disabled(!viewModel.isButtonResetEnabled)
    }
}

// MARK: - ConsoleFiltersView (Custom Filters)

extension ConsoleFiltersView {
    @available(iOS 14.0, *)
    var generalSection: some View {
        FiltersSection(
            isExpanded: $isGeneralSectionExpanded,
            header: { generalHeader },
            content: { generalContent },
            isWrapped: false
        )
    }

    private var generalHeader: some View {
        FilterSectionHeader(
            icon: "line.horizontal.3.decrease.circle", title: "General",
            color: .yellow,
            reset: { viewModel.resetFilters() },
            isDefault: viewModel.filters.count == 1 && viewModel.filters[0].isDefault,
            isEnabled: $viewModel.criteria.isFiltersEnabled
        )
    }

#if os(iOS)
    @available(iOS 14.0, *)
    @ViewBuilder
    private var generalContent: some View {
        ForEach(viewModel.filters) { filter in
            CustomFilterView(filter: filter, onRemove: {
                viewModel.removeFilter(filter)
            }).buttonStyle(.plain)
        }

        Button(action: { viewModel.addFilter() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add Filter")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
#else
    @ViewBuilder
    private var generalContent: some View {
        VStack {
            ForEach(viewModel.filters) { filter in
                CustomFilterView(filter: filter, onRemove: {
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

// MARK: - ConsoleFiltersView (Log Levels)

extension ConsoleFiltersView {
    var logLevelsSection: some View {
        FiltersSection(
            isExpanded: $isLevelsSectionExpanded,
            header: { logLevelsHeader },
            content: { logLevelsContent }
        )
    }

    private var logLevelsHeader: some View {
        FilterSectionHeader(
            icon: "flag", title: "Levels",
            color: .accentColor,
            reset: { viewModel.criteria.logLevels = .default },
            isDefault: false,
            isEnabled: $viewModel.criteria.logLevels.isEnabled
        )
    }

#if os(iOS)
    @ViewBuilder
    private var logLevelsContent: some View {
        HStack(spacing: 16) {
            makeLevelsSection(levels: [.trace, .debug, .info, .notice])
            makeLevelsSection(levels: [.warning, .error, .critical])
        }
        .padding(.bottom, 6)
        .buttonStyle(.plain)

        Button(viewModel.bindingForTogglingAllLevels.wrappedValue ? " Disable All" : "Enable All", action: { viewModel.bindingForTogglingAllLevels.wrappedValue.toggle() })
            .frame(maxWidth: .infinity, alignment: .center)
    }
#else
    private var logLevelsContent: some View {
        HStack(spacing:0) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLevels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)

                HStack(spacing: 32) {
                    makeLevelsSection(levels: [.trace, .debug, .info, .notice])
                    makeLevelsSection(levels: [.warning, .error, .critical])
                }.fixedSize()
            }
            Spacer()
        }
    }
#endif

    private func makeLevelsSection(levels: [LoggerStore.Level]) -> some View {
        VStack(alignment: .leading) {
            Spacer()
            ForEach(levels, id: \.self, content: makeLevelView)
        }
    }

#if os(macOS)
    private func makeLevelView(for level: LoggerStore.Level) -> some View {
        Toggle(level.rawValue.capitalized, isOn: viewModel.binding(forLevel: level))
            .accentColor(tintColor(for: level))
    }
#else
    private func makeLevelView(for level: LoggerStore.Level) -> some View {
        BadgePickerItemView(title: level.rawValue.capitalized, isEnabled: viewModel.binding(forLevel: level), textColor: tintColor(for: level))
            .accentColor(tintColor(for: level))
    }
#endif

    private func tintColor(for level: LoggerStore.Level) -> Color {
        switch level {
        case .trace, .debug: return Color.primary.opacity(0.66)
        default: return Color.textColor(for: level)
        }
    }
}

// MARK: - ConsoleFiltersView (Labels)

extension ConsoleFiltersView {
    var labelsSection: some View {
        FiltersSection(
            isExpanded: $isLabelsSectionExpanded,
            header: { labelsHeader },
            content: { labelsContent }
        )
    }

    private var labelsHeader: some View {
        FilterSectionHeader(
            icon: "tag", title: "Labels",
            color: .orange,
            reset: { viewModel.criteria.labels = .default },
            isDefault: viewModel.criteria.labels == .default,
            isEnabled: $viewModel.criteria.labels.isEnabled
        )
    }

#if os(iOS)
    @ViewBuilder
    private var labelsContent: some View {
        let labels = viewModel.allLabels

        if labels.isEmpty {
            Text("No Labels")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
        } else {
            ForEach(labels.prefix(5), id: \.self) { item in
                Toggle(item.capitalized, isOn: viewModel.binding(forLabel: item))
            }
            if labels.count > 5 {
                Button("View All", action: { isAllLabelsShown = true })
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(allLabelsNavigationLink)
            }
        }
    }

    private var allLabelsNavigationLink: some View {
        InvisibleNavigationLinks {
            NavigationLink.programmatic(isActive: $isAllLabelsShown) {
                ConsoleFiltersLabelsPickerView(viewModel: viewModel)
            }
        }
    }
#else
    private var labelsContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLabels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                ForEach(viewModel.allLabels, id: \.self) { item in
                    Toggle(item.capitalized, isOn: viewModel.binding(forLabel: item))
                }
            }
            Spacer()
        }
    }
#endif
}

// MARK: - ConsoleFiltersView (Time Period)

extension ConsoleFiltersView {
    var timePeriodSection: some View {
        FiltersSection(
            isExpanded: $isTimePeriodSectionExpanded,
            header: { timePeriodHeader },
            content: { timePeriodContent }
        )
    }

    private var timePeriodHeader: some View {
        FilterSectionHeader(
            icon: "calendar", title: "Time Period",
            color: .yellow,
            reset: { viewModel.criteria.dates = .default },
            isDefault: viewModel.criteria.dates == .default,
            isEnabled: $viewModel.criteria.dates.isEnabled
        )
    }

    @ViewBuilder
    private var timePeriodContent: some View {
        Filters.toggle("Latest Session", isOn: $viewModel.criteria.dates.isCurrentSessionOnly)

        DateRangePicker(title: "Start Date", date: viewModel.bindingStartDate, isEnabled: $viewModel.criteria.dates.isStartDateEnabled)
        DateRangePicker(title: "End Date", date: viewModel.bindingEndDate, isEnabled: $viewModel.criteria.dates.isEndDateEnabled)

        HStack(spacing: 16) {
            Button("Recent") { viewModel.criteria.dates = .recent }
            Button("Today") { viewModel.criteria.dates = .today }
            Spacer()
        }
#if os(iOS)
        .foregroundColor(.accentColor)
        .buttonStyle(.plain)
#elseif os(macOS)
        .padding(.top, 6)
#endif
    }
}

#endif
