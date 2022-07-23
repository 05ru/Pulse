// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI

// MARK: - Extensions

#if os(iOS) || os(macOS)
extension Color {
    static var separator: Color { Color(UXColor.separator) }
    static var indigo: Color { Color(UXColor.systemIndigo) }
    static var secondaryFill: Color { Color(UXColor.secondarySystemFill) }
}
#endif

#if os(watchOS) || os(tvOS)
extension Color {
    static var indigo: Color { .purple }
    static var separator: Color { Color.secondary.opacity(0.3) }
    static var secondaryFill: Color { Color.secondary.opacity(0.3) }
}
#endif

extension NavigationLink where Label == EmptyView {
    static func programmatic(isActive: Binding<Bool>, destination: @escaping () -> Destination) -> NavigationLink {
        NavigationLink(isActive: isActive, destination: destination) {
            EmptyView()
        }
    }
}

struct Wrapped<View: UXView>: UIViewRepresentable {
    let view: View

    func makeUIView(context: Context) -> View {
        view
    }

    func updateUIView(_ uiView: View, context: Context) {
        // Do nothing
    }
}

// MARK: - Backport

struct Backport<Content: View> {
    let content: Content
}

extension View {
    var backport: Backport<Self> { Backport(content: self) }
}

extension Backport {
    enum HorizontalEdge {
        case leading, trailing

        @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
        var edge: SwiftUI.HorizontalEdge {
            switch self {
            case .leading: return .leading
            case .trailing: return .trailing
            }
        }
    }

    @ViewBuilder
    func swipeActions<T>(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ViewBuilder content: () -> T) -> some View where T: View {
#if os(iOS) || os(watchOS)
        if #available(iOS 15.0, watchOS 8.0, *) {
            self.content.swipeActions(edge: edge.edge, allowsFullSwipe: allowsFullSwipe, content: content)
        } else {
            self.content
        }
#else
        self.content
#endif
    }

    @ViewBuilder
    func borderedButton() -> some View {
        if #available(iOS 15.0, tvOS 14.0, watchOS 8.0, *) {
            self.content.buttonStyle(.bordered)
        } else {
            self.content
        }
    }

    @ViewBuilder
    func hideAccessibility() -> some View {
        if #available(iOS 14.0, tvOS 14.0, *) {
            self.content.accessibilityHidden(true)
        } else {
            self.content
        }
    }

    @ViewBuilder
    func backgroundThinMaterial() -> some View {
        if #available(iOS 15.0, tvOS 15.0, *) {
            self.content.background(.thinMaterial)
        } else {
            self.content
        }
    }
}
