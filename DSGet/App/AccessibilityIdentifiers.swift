//
//  AccessibilityIdentifiers.swift
//  DSGet
//
//  Centralized accessibility identifiers for UI testing.
//

import Foundation

enum AccessibilityID {
    // MARK: - Login

    enum Login {
        static let serverNameField = "login.serverName"
        static let hostField = "login.host"
        static let portField = "login.port"
        static let httpsToggle = "login.httpsToggle"
        static let usernameField = "login.username"
        static let passwordField = "login.password"
        static let otpField = "login.otp"
        static let loginButton = "login.loginButton"
    }

    // MARK: - Sidebar

    enum Sidebar {
        static let downloads = "sidebar.downloads"
        static let feeds = "sidebar.feeds"
        static let settings = "sidebar.settings"
    }

    // MARK: - Task List

    enum TaskList {
        static let list = "taskList.list"
        static let addButton = "taskList.addButton"
        static let taskRow = "taskList.taskRow"
    }

    // MARK: - Add Task

    enum AddTask {
        static let urlField = "addTask.urlField"
        static let createButton = "addTask.createButton"
        static let cancelButton = "addTask.cancelButton"
        static let modePicker = "addTask.modePicker"
    }

    // MARK: - Feed List

    enum FeedList {
        static let list = "feedList.list"
        static let feedRow = "feedList.feedRow"
    }

    // MARK: - Settings

    enum Settings {
        static let logoutButton = "settings.logoutButton"
        static let serverName = "settings.serverName"
    }
}
