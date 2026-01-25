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

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss

    @State private var viewModel: AddTaskViewModel

    private let feedItemTitle: String?
    private let isFromSearch: Bool

    @State private var isShowingFilePicker = false

    init(preselectedTorrent: AddTaskPreselectedTorrent? = nil, prefilledURL: String? = nil, feedItemTitle: String? = nil, isFromSearch: Bool = false) {
        self.feedItemTitle = feedItemTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isFromSearch = isFromSearch
        _viewModel = State(initialValue: AddTaskViewModel(
            preselectedTorrent: preselectedTorrent,
            prefilledURL: prefilledURL
        ))
    }

    var provieneFeed: Bool {
        feedItemTitle?.isEmpty == false
    }

    var shouldHideModePicker: Bool {
        provieneFeed || isFromSearch
    }

    // MARK: - Body

    var body: some View {
        Form {
            headerSection
            inputSection
            recentFoldersSection
            createButtonSection
        }
        .navigationTitle("Add New Task")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingFolderPicker) {
            folderPickerSheet
        }
        .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data], onCompletion: handleFileImport)
        .alert("Task Created", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your download task has been successfully created.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        if let itemTitle = feedItemTitle, provieneFeed {
            Section("Feed item") {
                Text(itemTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        } else if isFromSearch {
            Section("Search result") {
                Text("Download from search")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                Picker("Input", selection: $viewModel.inputMode) {
                    ForEach(AddTaskInputMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Input Section

    @ViewBuilder
    private var inputSection: some View {
        Section {
            inputContent
            folderPickerButton
        }
    }

    @ViewBuilder
    private var inputContent: some View {
        switch viewModel.inputMode {
        case .url:
            urlInputRow
        case .file:
            fileInputRow
        }
    }

    @ViewBuilder
    private var urlInputRow: some View {
        HStack {
            TextField("URL", text: $viewModel.taskUrl)
                .autocorrectionDisabled(true)
                .disabled(shouldHideModePicker)
            if !shouldHideModePicker {
                Button {
                    if let pasteboardString = UIPasteboard.general.string {
                        viewModel.taskUrl = pasteboardString
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private var fileInputRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isShowingFilePicker = true }) {
                HStack {
                    if let selectedTorrentName = viewModel.selectedTorrentName {
                        Text(selectedTorrentName)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Select .torrent file...")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.selectedTorrentName != nil {
                Button(role: .destructive) {
                    viewModel.removeTorrentFile()
                } label: {
                    Text("Remove selected file")
                }
                .buttonStyle(.borderless)
                .font(.footnote)
            }
        }
    }

    @ViewBuilder
    private var folderPickerButton: some View {
        Button(action: {
            viewModel.showingFolderPicker = true
        }) {
            HStack {
                Text(viewModel.destinationFolderPath.isEmpty ? "Select folder..." : viewModel.destinationFolderPath)
                    .foregroundStyle(viewModel.destinationFolderPath.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Recent Folders Section

    @ViewBuilder
    private var recentFoldersSection: some View {
        if !viewModel.recentFolders.isEmpty {
            Section("Recent Folders") {
                ForEach(viewModel.recentFolders, id: \.self) { folder in
                    recentFolderRow(folder)
                }
            }
        }
    }

    @ViewBuilder
    private func recentFolderRow(_ folder: String) -> some View {
        Button {
            viewModel.selectRecentFolder(folder)
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text(folder)
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.destinationFolderPath == folder {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    // MARK: - Create Button Section

    @ViewBuilder
    private var createButtonSection: some View {
        Section {
            Button(action: {
                Task { await viewModel.createTask() }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Create Task")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isLoading || !viewModel.canCreateTask)
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private var folderPickerSheet: some View {
        NavigationStack {
            FolderPickerView(selectedFolderPath: $viewModel.destinationFolderPath) {
                viewModel.showingFolderPicker = false
            }
        }
    }

    // MARK: - File Import Handler

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let securityScoped = url.startAccessingSecurityScopedResource()
                defer {
                    if securityScoped {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                viewModel.selectTorrentFile(data: data, name: url.lastPathComponent)
            } catch {
                viewModel.currentError = DSGetError.from(error)
                viewModel.showingError = true
            }
        case .failure(let error):
            viewModel.currentError = DSGetError.from(error)
            viewModel.showingError = true
        }
    }
}
