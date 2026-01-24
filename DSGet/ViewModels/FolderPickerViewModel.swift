//
//  FolderPickerViewModel.swift
//  DSGet
//
//  ViewModel for the folder picker view, handling folder navigation and creation.
//

import Foundation
import SwiftUI

// MARK: - FolderPickerViewModel

/// ViewModel that manages the state and logic for folder selection.
@MainActor
@Observable
final class FolderPickerViewModel: DomainErrorHandling {

    // MARK: - Published State

    /// Folders in the current directory.
    private(set) var folders: [FileSystemItem] = []

    /// Current path being displayed.
    private(set) var currentPath: String

    /// Whether content is loading.
    private(set) var isLoading: Bool = false

    /// Whether folder creation is in progress.
    private(set) var isCreatingFolder: Bool = false

    /// Whether to show create folder sheet.
    var showingCreateFolder: Bool = false

    /// Name for new folder.
    var newFolderName: String = ""

    /// Current error.
    var currentError: DSGetError?

    /// Whether to show error alert.
    var showingError: Bool = false

    // MARK: - Computed Properties

    /// Whether currently at root level.
    var isAtRoot: Bool {
        currentPath == "/"
    }

    /// Navigation title based on current path.
    var navigationTitle: String {
        isAtRoot ? "Shared Folders" : currentPath.lastPathComponent
    }

    /// Trimmed new folder name.
    var trimmedNewFolderName: String {
        newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether can select current folder.
    var canSelectCurrentFolder: Bool {
        !isLoading && !isAtRoot
    }

    /// Whether can create folder in current path.
    var canCreateFolder: Bool {
        !isLoading && !isAtRoot
    }

    // MARK: - Dependencies

    private let fileService: FileServiceProtocol

    // MARK: - Initialization

    init(
        currentPath: String = "/",
        fileService: FileServiceProtocol? = nil
    ) {
        self.currentPath = currentPath
        self.fileService = fileService ?? DI.fileService
    }

    // MARK: - Public Methods

    /// Loads folders for the specified path.
    func loadFolders(path: String? = nil) async {
        let targetPath = path ?? currentPath

        isLoading = true
        currentError = nil
        showingError = false

        do {
            var fetchedItems: [FileSystemItem]

            if targetPath == "/" {
                fetchedItems = try await fileService.getShares()
            } else {
                fetchedItems = try await fileService.getFolderContents(path: targetPath)
            }

            // Filter to show only folders
            folders = fetchedItems
                .filter { $0.isDirectory }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            if path != nil {
                currentPath = targetPath
            }

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Creates a new folder in the current directory.
    func createFolder() async {
        let folderName = trimmedNewFolderName
        guard !folderName.isEmpty else { return }
        guard !isAtRoot else {
            currentError = DSGetError.api(.serverError(code: -1, message: "Creating folders at the root is not supported."))
            showingError = true
            return
        }

        isCreatingFolder = true
        currentError = nil
        showingError = false

        do {
            try await fileService.createFolder(parentPath: currentPath, name: folderName)

            // Reload folders after creation
            await loadFolders()

            // Reset state
            newFolderName = ""
            showingCreateFolder = false

        } catch {
            handleError(error)
        }

        isCreatingFolder = false
    }

    /// Navigates to a subfolder.
    func navigateTo(_ folder: FileSystemItem) async {
        guard folder.isDirectory else { return }
        await loadFolders(path: folder.path)
    }

    /// Returns the formatted path for selection (without leading slash).
    func formatPathForSelection(_ path: String) -> String {
        path.hasPrefix("/") ? String(path.dropFirst()) : path
    }

    /// Dismisses the create folder sheet.
    func dismissCreateFolderSheet() {
        newFolderName = ""
        showingCreateFolder = false
    }

    /// Creates a new instance for a subfolder navigation.
    func viewModelForSubfolder(_ folder: FileSystemItem) -> FolderPickerViewModel {
        FolderPickerViewModel(
            currentPath: folder.path,
            fileService: fileService
        )
    }
}
