//
//  ViewModifiers.swift
//  DSGet
//
//  Reusable view modifiers for common UI patterns.
//

import SwiftUI

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let error: DSGetError?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error?.localizedDescription ?? "An unknown error occurred.")
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
            .overlay(alignment: .bottom) {
                if isOffline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Showing cached data")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }
            }
    }
}

extension View {
    func offlineModeIndicator(isOffline: Bool) -> some View {
        modifier(OfflineModeOverlay(isOffline: isOffline))
    }
}
