//
//  SpotlightIndexer.swift
//  DSGet
//
//  Spotlight search integration for indexing download tasks.
//

import Foundation
import CoreSpotlight
import DSGetCore

// MARK: - Spotlight Indexer

@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private let domainIdentifier = "com.dsget.tasks"
    private let searchableIndex = CSSearchableIndex.default()

    private init() {}

    // MARK: - Public Methods

    /// Index all tasks for Spotlight search.
    func indexTasks(_ tasks: [DownloadTask]) {
        let items = tasks.map { createSearchableItem(from: $0) }

        searchableIndex.indexSearchableItems(items) { error in
            #if DEBUG
            if let error = error {
                print("Spotlight indexing error: \(error.localizedDescription)")
            }
            #endif
        }
    }

    /// Index a single task.
    func indexTask(_ task: DownloadTask) {
        let item = createSearchableItem(from: task)

        searchableIndex.indexSearchableItems([item]) { error in
            #if DEBUG
            if let error = error {
                print("Spotlight indexing error: \(error.localizedDescription)")
            }
            #endif
        }
    }

    /// Remove a task from the index.
    func removeTask(_ task: DownloadTask) {
        searchableIndex.deleteSearchableItems(withIdentifiers: [task.id.rawValue]) { error in
            #if DEBUG
            if let error = error {
                print("Spotlight delete error: \(error.localizedDescription)")
            }
            #endif
        }
    }

    /// Remove all indexed items.
    func removeAllItems() {
        searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            #if DEBUG
            if let error = error {
                print("Spotlight delete all error: \(error.localizedDescription)")
            }
            #endif
        }
    }

    /// Update tasks in the index (removes old, adds new).
    func updateTasks(_ tasks: [DownloadTask]) {
        // Remove all existing items first
        searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { [weak self] _ in
            // Then index new items on main actor
            Task { @MainActor [weak self] in
                self?.indexTasks(tasks)
            }
        }
    }

    // MARK: - Private Methods

    private func createSearchableItem(from task: DownloadTask) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)

        // Title
        attributeSet.title = task.title
        attributeSet.displayName = task.title

        // Description
        attributeSet.contentDescription = buildDescription(for: task)

        // Keywords for better searchability
        attributeSet.keywords = buildKeywords(for: task)

        // Thumbnail hint
        attributeSet.thumbnailData = nil // Could add icon data here

        // Metadata
        attributeSet.downloadedDate = Date()
        attributeSet.contentCreationDate = Date()

        // File size if available
        if task.size.bytes > 0 {
            attributeSet.fileSize = NSNumber(value: task.size.bytes)
        }

        return CSSearchableItem(
            uniqueIdentifier: task.id.rawValue,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }

    private func buildDescription(for task: DownloadTask) -> String {
        var components: [String] = []

        // Status
        components.append(task.status.displayName)

        // Progress
        let progress = Int(task.progress * 100)
        components.append("\(progress)% complete")

        // Size
        if task.size.bytes > 0 {
            components.append(task.size.formatted)
        }

        // Destination
        if !task.destination.isEmpty {
            components.append("in \(task.destination)")
        }

        return components.joined(separator: " • ")
    }

    private func buildKeywords(for task: DownloadTask) -> [String] {
        var keywords: [String] = []

        // Title words
        let titleWords = task.title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 }
        keywords.append(contentsOf: titleWords)

        // Status
        keywords.append(task.status.displayName)

        // Type
        keywords.append(task.type.displayName)
        keywords.append("download")
        keywords.append("torrent")

        return keywords
    }
}

// MARK: - Spotlight Activity Handler

extension SpotlightIndexer {
    /// Extracts the task ID from a Spotlight user activity.
    func taskID(from userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        return identifier
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Handles Spotlight search continuation.
    func onSpotlightSearch(perform action: @escaping (String) -> Void) -> some View {
        self.onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let taskID = SpotlightIndexer.shared.taskID(from: userActivity) {
                action(taskID)
            }
        }
    }
}
