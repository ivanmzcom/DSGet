//
//  ViewModifiers.swift
//  DSGet
//
//  Reusable view modifiers for common UI patterns.
//

import SwiftUI
import DSGetCore

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let error: DSGetError?

    func body(content: Content) -> some View {
        content
            .alert(String.localized("error.title"), isPresented: $isPresented) {
                Button(String.localized("general.ok"), role: .cancel) { }
            } message: {
                Text(error?.localizedDescription ?? String.localized("error.unknown"))
            }
    }
}

extension View {
    func errorAlert(isPresented: Binding<Bool>, error: DSGetError?) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, error: error))
    }
}

// MARK: - Loading Overlay Modifier

struct LoadingOverlayModifier<Empty: View>: ViewModifier {
    let isLoading: Bool
    let isEmpty: Bool
    let emptyView: () -> Empty

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading && isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(.accentColor)
                } else if !isLoading && isEmpty {
                    emptyView()
                }
            }
    }
}

extension View {
    func loadingOverlay<Empty: View>(
        isLoading: Bool,
        isEmpty: Bool,
        @ViewBuilder emptyView: @escaping () -> Empty
    ) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, isEmpty: isEmpty, emptyView: emptyView))
    }

    func loadingOverlay(
        isLoading: Bool,
        isEmpty: Bool,
        title: String,
        systemImage: String,
        description: String
    ) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, isEmpty: isEmpty) {
            ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
        })
    }
}

// MARK: - Offline Mode Indicator

struct OfflineModeOverlay: ViewModifier {
    let isOffline: Bool

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isOffline {
                    Label(String.localized("offline.cachedData"), systemImage: "wifi.slash")
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.bar)
                }
            }
    }
}

extension View {
    func offlineModeIndicator(isOffline: Bool) -> some View {
        modifier(OfflineModeOverlay(isOffline: isOffline))
    }
}
