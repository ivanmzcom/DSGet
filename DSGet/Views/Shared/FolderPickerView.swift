//
//  FolderPickerView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 27/9/25.
//

import SwiftUI
import DSGetCore

struct FolderPickerView: View {
    @Binding var selectedFolderPath: String
    let onDismissSheet: () -> Void

    @State private var viewModel: FolderPickerViewModel

    init(
        selectedFolderPath: Binding<String>,
        currentPath: String = "/",
        onDismissSheet: @escaping () -> Void
    ) {
        _selectedFolderPath = selectedFolderPath
        self.onDismissSheet = onDismissSheet
        _viewModel = State(initialValue: FolderPickerViewModel(currentPath: currentPath))
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.folders.isEmpty {
                ProgressView()
            } else if viewModel.folders.isEmpty && viewModel.currentError == nil && !viewModel.isLoading {
                Text(String.localized("folderPicker.noFolders"))
            } else {
                ForEach(viewModel.folders) { folder in
                    NavigationLink(destination: Self(
                        selectedFolderPath: $selectedFolderPath,
                        currentPath: folder.path,
                        onDismissSheet: onDismissSheet
                    )) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.yellow)
                            Text(folder.name)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button(String.localized("folderPicker.button.cancel")) { onDismissSheet() }
            }
            ToolbarItemGroup {
                Button {
                    viewModel.showingCreateFolder = true
                } label: {
                    Label(String.localized("folderPicker.button.newFolder"), systemImage: "folder.badge.plus")
                }
                .disabled(!viewModel.canCreateFolder)

                Button(String.localized("folderPicker.button.select")) {
                    handleSelectFolder()
                }
                .disabled(!viewModel.canSelectCurrentFolder)
            }
        }
        .task {
            await viewModel.loadFolders()
        }
        .alert(String.localized("error.title"), isPresented: $viewModel.showingError) {
            Button(String.localized("general.ok")) { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
        }
        .sheet(isPresented: $viewModel.showingCreateFolder) {
            NavigationStack {
                Form {
                    Section(header: Text(String.localized("folderPicker.createFolder.header"))) {
                        TextField(String.localized("folderPicker.createFolder.placeholder"), text: $viewModel.newFolderName)
                            .disableAutocorrection(true)
                    }
                }
                .navigationTitle(String.localized("folderPicker.createFolder.title"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String.localized("folderPicker.button.cancel")) {
                            viewModel.dismissCreateFolderSheet()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String.localized("folderPicker.createFolder.button.create")) {
                            Task { await viewModel.createFolder() }
                        }
                        .disabled(viewModel.trimmedNewFolderName.isEmpty || viewModel.isCreatingFolder)
                    }
                }
            }
        }
    }

    private func handleSelectFolder() {
        selectedFolderPath = viewModel.formatPathForSelection(viewModel.currentPath)
        onDismissSheet()
    }
}

// Extension to get last path component for navigation title
extension String {
    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }
}
