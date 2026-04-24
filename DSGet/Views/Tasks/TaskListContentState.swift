//
//  TaskListContentState.swift
//  DSGet
//

import DSGetCore

enum TaskListContentState {
    case loading
    case offline
    case error(DSGetError)
    case empty
    case noResults
}
