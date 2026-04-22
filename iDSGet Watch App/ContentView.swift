import SwiftUI

struct ContentView: View {
    @State private var tasksViewModel = WatchTasksViewModel()

    var body: some View {
        NavigationStack {
            WatchRootContent(viewModel: tasksViewModel)
                .navigationTitle(tasksViewModel.navigationTitle)
                .toolbar {
                    if tasksViewModel.phase == .ready {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await tasksViewModel.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(tasksViewModel.isLoading)
                        }
                    }
                }
        }
        .task {
            await tasksViewModel.bootstrap()
        }
        .alert(
            String.watchLocalized("watch.error.title"),
            isPresented: errorAlertBinding,
            presenting: tasksViewModel.error
        ) { _ in
            Button(String.watchLocalized("watch.action.ok"), role: .cancel) {
                tasksViewModel.clearError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { tasksViewModel.error != nil },
            set: { isPresented in
                if !isPresented {
                    tasksViewModel.clearError()
                }
            }
        )
    }
}

private struct WatchRootContent: View {
    @Bindable var viewModel: WatchTasksViewModel

    var body: some View {
        switch viewModel.phase {
        case .checkingSession:
            WatchLoadingView()

        case .waitingForPhone:
            WatchWaitingForPhoneView(
                message: viewModel.companionStatusText,
                canRetry: viewModel.canRetrySync,
                retry: viewModel.retryCompanionSync
            )

        case .ready:
            WatchDownloadsView(viewModel: viewModel)
        }
    }
}

private struct WatchLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(String.watchLocalized("watch.loading"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WatchWaitingForPhoneView: View {
    let message: String
    let canRetry: Bool
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
                .foregroundStyle(.blue)

            Text(String.watchLocalized("watch.waiting.title"))
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if canRetry {
                Button(String.watchLocalized("watch.waiting.button")) {
                    retry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ContentView()
}
