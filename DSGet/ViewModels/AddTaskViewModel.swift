//
//  AddTaskViewModel.swift
//  DSGet
//
//  ViewModel for the add task view, handling task creation from URL or torrent file.
//

import Foundation
import SwiftUI
import DSGetCore

// MARK: - AddTaskInputMode

enum AddTaskInputMode: String, CaseIterable, Identifiable {
    case url
    case file

    var id: String { rawValue }

    var title: String {
        switch self {
        case .url: return "URL"
        case .file: return ".torrent"
        }
    }
}

// MARK: - AddTaskViewModel

/// ViewModel that manages the state and logic for adding download tasks.
@MainActor
@Observable
final class AddTaskViewModel: DomainErrorHandling {
    // MARK: - Published State

    /// The URL to download from.
    var taskUrl: String = ""

    /// The destination folder path.
    var destinationFolderPath: String = ""

    /// Input mode (URL or file).
    var inputMode: AddTaskInputMode = .url

    /// Name of the selected torrent file.
    var selectedTorrentName: String?

    /// Data of the selected torrent file.
    var selectedTorrentData: Data?

    /// Whether a task is being created.
    private(set) var isLoading: Bool = false

    /// Whether folder picker is showing.
    var showingFolderPicker: Bool = false

    /// Whether success alert is showing.
    var showingSuccessAlert: Bool = false

    /// Current error.
    var currentError: DSGetError?

    /// Whether to show error alert.
    var showingError: Bool = false

    /// Recent destination folders for quick selection.
    private(set) var recentFolders: [String] = []

    // MARK: - Callbacks

    /// Called when a task is successfully created.
    var onTaskCreated: (() -> Void)?

    // MARK: - Computed Properties

    /// Whether the form can be submitted.
    var canCreateTask: Bool {
        guard !destinationFolderPath.isEmpty else { return false }
        switch inputMode {
        case .url:
            return !taskUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .file:
            return selectedTorrentData != nil
        }
    }

    // MARK: - Dependencies

    private let taskService: TaskServiceProtocol
    private let recentFoldersService: RecentFoldersManaging

    // MARK: - Initialization

    init(
        preselectedTorrent: AddTaskPreselectedTorrent? = nil,
        prefilledURL: String? = nil,
        taskService: TaskServiceProtocol? = nil,
        recentFoldersService: RecentFoldersManaging? = nil
    ) {
        self.taskService = taskService ?? DIService.taskService
        self.recentFoldersService = recentFoldersService ?? DIService.recentFoldersService
        self.taskUrl = prefilledURL ?? ""
        self.recentFolders = self.recentFoldersService.recentFolders

        if let preselectedTorrent {
            self.inputMode = .file
            self.selectedTorrentName = preselectedTorrent.name
            self.selectedTorrentData = preselectedTorrent.data
        }
    }

    // MARK: - Public Methods

    /// Creates a download task based on current input mode.
    func createTask() async {
        guard canCreateTask else { return }

        isLoading = true
        currentError = nil
        showingError = false
        showingSuccessAlert = false

        do {
            switch inputMode {
            case .url:
                let trimmedURL = taskUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                let request: CreateTaskRequest
                if trimmedURL.lowercased().hasPrefix("magnet:") {
                    request = .magnetLink(trimmedURL, destination: destinationFolderPath)
                } else if let url = URL(string: trimmedURL) {
                    request = .url(url, destination: destinationFolderPath)
                } else {
                    throw DomainError.invalidDownloadURL
                }
                try await taskService.createTask(request: request)

            case .file:
                guard let fileData = selectedTorrentData, let fileName = selectedTorrentName else {
                    currentError = DSGetError.api(.serverError(code: -1, message: "Select a .torrent file before creating the task."))
                    showingError = true
                    isLoading = false
                    return
                }
                let request = CreateTaskRequest.torrentFile(data: fileData, fileName: fileName, destination: destinationFolderPath)
                try await taskService.createTask(request: request)
            }

            // Success - save folder to recent list
            recentFoldersService.addRecentFolder(destinationFolderPath)
            recentFolders = recentFoldersService.recentFolders

            showingSuccessAlert = true

            if inputMode == .file {
                selectedTorrentData = nil
                selectedTorrentName = nil
            }

            onTaskCreated?()
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Handles the result of a file import dialog, reading the file data.
    func handleFileImport(_ result: Result<URL, Error>) {
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
                selectTorrentFile(data: data, name: url.lastPathComponent)
            } catch {
                currentError = DSGetError.from(error)
                showingError = true
            }

        case .failure(let error):
            currentError = DSGetError.from(error)
            showingError = true
        }
    }

    /// Selects a torrent file.
    func selectTorrentFile(data: Data, name: String) {
        selectedTorrentData = data
        selectedTorrentName = name
    }

    /// Removes the selected torrent file.
    func removeTorrentFile() {
        selectedTorrentData = nil
        selectedTorrentName = nil
    }

    /// Selects a recent folder as destination.
    func selectRecentFolder(_ path: String) {
        destinationFolderPath = path
    }

    /// Resets the form for a new task.
    func reset() {
        taskUrl = ""
        destinationFolderPath = ""
        selectedTorrentName = nil
        selectedTorrentData = nil
        inputMode = .url
        currentError = nil
        showingError = false
        showingSuccessAlert = false
    }
}
