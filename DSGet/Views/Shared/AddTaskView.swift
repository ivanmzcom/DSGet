//
//  AddTaskView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import UniformTypeIdentifiers
import DSGetCore

struct AddTaskPreselectedTorrent {
    let name: String
    let data: Data
}

extension AddTaskPreselectedTorrent: Identifiable {
    var id: String { name }
}

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss

    @State private var viewModel: AddTaskViewModel
    private let feedItemTitle: String?
    private let isFromSearch: Bool
    @State private var isShowingFilePicker = false

    init(
        preselectedTorrent: AddTaskPreselectedTorrent? = nil,
        prefilledURL: String? = nil,
        feedItemTitle: String? = nil,
        isFromSearch: Bool = false
    ) {
        self.feedItemTitle = feedItemTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFromSearch = isFromSearch
        _viewModel = State(
            initialValue: AddTaskViewModel(
                preselectedTorrent: preselectedTorrent,
                prefilledURL: prefilledURL
            )
        )
    }

    private var comesFromFeed: Bool {
        feedItemTitle?.isEmpty == false
    }

    private var shouldHideModePicker: Bool {
        comesFromFeed || isFromSearch
    }

    var body: some View {
        Form {
            AddTaskHeaderSection(
                feedItemTitle: feedItemTitle,
                isFromSearch: isFromSearch,
                shouldHideModePicker: shouldHideModePicker,
                inputMode: $viewModel.inputMode
            )
            AddTaskInputSection(
                viewModel: viewModel,
                shouldHideModePicker: shouldHideModePicker,
                isShowingFilePicker: $isShowingFilePicker,
                showFolderPicker: showFolderPicker,
                pasteFromClipboard: pasteFromClipboard
            )
            if !viewModel.recentFolders.isEmpty {
                AddTaskRecentFoldersSection(
                    folders: viewModel.recentFolders,
                    selectedFolderPath: viewModel.destinationFolderPath,
                    onSelectFolder: viewModel.selectRecentFolder
                )
            }
            AddTaskCreateSection(
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canCreateTask,
                createTask: createTask
            )
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(minWidth: 560, idealWidth: 620, minHeight: 360, idealHeight: 420)
        #endif
        .navigationTitle(String.localized("addTask.title"))
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $viewModel.showingFolderPicker) {
            AddTaskFolderPickerSheet(
                selectedFolderPath: $viewModel.destinationFolderPath,
                onClose: closeFolderPicker
            )
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data],
            onCompletion: handleFileImport
        )
        .alert(String.localized("addTask.alert.success"), isPresented: $viewModel.showingSuccessAlert) {
            Button(String.localized("general.ok")) { dismiss() }
        } message: {
            Text(String.localized("addTask.alert.success.message"))
        }
        .alert(String.localized("addTask.alert.error"), isPresented: $viewModel.showingError) {
            Button(String.localized("general.ok")) { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? String.localized("error.unknown"))
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String.localized("addTask.button.close")) { dismiss() }
                    .accessibilityIdentifier(AccessibilityID.AddTask.cancelButton)
            }
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        viewModel.handleFileImport(result)
    }

    private func showFolderPicker() {
        viewModel.showingFolderPicker = true
    }

    private func closeFolderPicker() {
        viewModel.showingFolderPicker = false
    }

    private func pasteFromClipboard() {
        if let pasteboardString = PlatformClipboard.string() {
            viewModel.taskUrl = pasteboardString
        }
    }

    private func createTask() async {
        await viewModel.createTask()
    }
}

private struct AddTaskHeaderSection: View {
    let feedItemTitle: String?
    let isFromSearch: Bool
    let shouldHideModePicker: Bool
    @Binding var inputMode: AddTaskInputMode

    var body: some View {
        if let feedItemTitle, shouldHideModePicker, !feedItemTitle.isEmpty {
            Section(String.localized("addTask.section.feedItem")) {
                Text(feedItemTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else if isFromSearch {
            Section(String.localized("addTask.section.searchResult")) {
                Text(String.localized("addTask.search.downloadFromSearch"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section(String.localized("addTask.section.input")) {
                Picker(String.localized("addTask.section.input"), selection: $inputMode) {
                    ForEach(AddTaskInputMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .accessibilityIdentifier(AccessibilityID.AddTask.modePicker)
                .pickerStyle(.segmented)
            }
        }
    }
}

private struct AddTaskInputSection: View {
    let viewModel: AddTaskViewModel
    let shouldHideModePicker: Bool
    @Binding var isShowingFilePicker: Bool

    let showFolderPicker: () -> Void
    let pasteFromClipboard: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(String.localized("addTask.section.destination")) {
            switch viewModel.inputMode {
            case .url:
                AddTaskURLInputRow(
                    taskURL: $viewModel.taskUrl,
                    isLocked: shouldHideModePicker,
                    pasteFromClipboard: pasteFromClipboard
                )
            case .file:
                AddTaskFileInputRow(
                    selectedTorrentName: viewModel.selectedTorrentName,
                    removeFile: viewModel.removeTorrentFile,
                    showFilePicker: { isShowingFilePicker = true }
                )
            }

            AddTaskFolderButton(
                destinationFolderPath: viewModel.destinationFolderPath,
                showFolderPicker: showFolderPicker
            )
        }
    }
}

private struct AddTaskURLInputRow: View {
    @Binding var taskURL: String

    let isLocked: Bool
    let pasteFromClipboard: () -> Void

    var body: some View {
        HStack {
            TextField(String.localized("addTask.placeholder.url"), text: $taskURL)
                .accessibilityIdentifier(AccessibilityID.AddTask.urlField)
                .autocorrectionDisabled(true)
                .disabled(isLocked)
                #if !os(macOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif

            if !isLocked {
                Button(action: pasteFromClipboard) {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct AddTaskFileInputRow: View {
    let selectedTorrentName: String?
    let removeFile: () -> Void
    let showFilePicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: showFilePicker) {
                HStack {
                    Text(selectedTorrentName ?? String.localized("addTask.placeholder.selectTorrent"))
                        .foregroundStyle(selectedTorrentName == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.secondary)
                }
            }

            if selectedTorrentName != nil {
                Button(role: .destructive, action: removeFile) {
                    Text(String.localized("addTask.button.removeFile"))
                }
                .buttonStyle(.borderless)
                .font(.footnote)
            }
        }
    }
}

private struct AddTaskFolderButton: View {
    let destinationFolderPath: String
    let showFolderPicker: () -> Void

    var body: some View {
        Button(action: showFolderPicker) {
            HStack {
                Text(destinationFolderPath.isEmpty ? String.localized("addTask.placeholder.selectFolder") : destinationFolderPath)
                    .foregroundStyle(destinationFolderPath.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AddTaskRecentFoldersSection: View {
    let folders: [String]
    let selectedFolderPath: String
    let onSelectFolder: (String) -> Void

    var body: some View {
        Section(String.localized("addTask.section.recentFolders")) {
            ForEach(folders, id: \.self) { folder in
                Button {
                    onSelectFolder(folder)
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text(folder)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedFolderPath == folder {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
    }
}

private struct AddTaskCreateSection: View {
    let isLoading: Bool
    let isEnabled: Bool
    let createTask: () async -> Void

    var body: some View {
        Section(String.localized("addTask.section.create")) {
            Button {
                Task { await createTask() }
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(String.localized("addTask.button.createTask"))
                    }
                    Spacer()
                }
            }
            .accessibilityIdentifier(AccessibilityID.AddTask.createButton)
            .disabled(isLoading || !isEnabled)
        }
    }
}

private struct AddTaskFolderPickerSheet: View {
    @Binding var selectedFolderPath: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            FolderPickerView(selectedFolderPath: $selectedFolderPath, onDismissSheet: onClose)
        }
    }
}
