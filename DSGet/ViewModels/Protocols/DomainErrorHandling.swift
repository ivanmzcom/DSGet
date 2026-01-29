//
//  DomainErrorHandling.swift
//  DSGet
//
//  Unified protocol for handling domain errors in ViewModels.
//

import Foundation
import DSGetCore

// MARK: - Authentication Error Notification

extension Notification.Name {
    /// Posted when a service returns an authentication error requiring re-login.
    static let authenticationRequired = Notification.Name("DSGet.authenticationRequired")
}

// MARK: - DomainErrorHandling Protocol

/// Unified protocol for ViewModels that handle domain errors.
/// ViewModels can optionally support offline mode by implementing `isOfflineMode`.
protocol DomainErrorHandling: AnyObject {
    var currentError: DSGetError? { get set }
    var showingError: Bool { get set }
}

/// Optional protocol for ViewModels that support offline mode.
protocol OfflineModeSupporting: AnyObject {
    var isOfflineMode: Bool { get set }
}

// MARK: - Default Implementation

extension DomainErrorHandling {
    /// Converts a DomainError to DSGetError and sets the error state.
    /// Uses DomainError's built-in categorization properties for cleaner mapping.
    func handleDomainError(_ error: DomainError) {
        // Update offline mode if supported
        if let offlineCapable = self as? OfflineModeSupporting {
            offlineCapable.isOfflineMode = error.isConnectivityError
        }

        // If error requires re-login, notify the app to show login screen
        if error.requiresRelogin {
            NotificationCenter.default.post(name: .authenticationRequired, object: nil)
        }

        // Map error using DomainError's categorization
        currentError = mapDomainError(error)
        showingError = currentError != nil
    }

    /// Handles any error, converting DomainError if needed.
    func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            handleDomainError(domainError)
        } else {
            let dsgetError = DSGetError.from(error)

            // Check if error requires re-login
            if dsgetError.requiresRelogin {
                NotificationCenter.default.post(name: .authenticationRequired, object: nil)
            }

            currentError = dsgetError
            showingError = true
        }
    }

    /// Maps a DomainError to DSGetError using categorization properties.
    private func mapDomainError(_ error: DomainError) -> DSGetError? {
        // Handle cache errors silently (fallback to network)
        if case .cacheEmpty = error { return nil }
        if case .cacheExpired = error { return nil }

        // Authentication errors
        if error.requiresRelogin {
            if case .invalidCredentials = error {
                return .authentication(.invalidCredentials)
            }
            return .authentication(.notLoggedIn)
        }

        // Connectivity errors
        if error.isConnectivityError {
            switch error {
            case .noConnection:
                return .network(.offline)

            case .timeout:
                return .network(.timeout)

            case .serverUnreachable:
                return .network(.requestFailed(reason: error.title))

            default:
                return .network(.requestFailed(reason: error.localizedDescription))
            }
        }

        // OTP handling
        if case .otpRequired = error {
            return .api(.otpRequired)
        }
        if case .otpInvalid = error {
            return .api(.serverError(code: -1, message: error.localizedDescription))
        }

        // API errors with codes
        if case .apiError(let code, let message) = error {
            return .api(.serverError(code: code, message: message))
        }

        // All other errors use their localized description
        return .api(.serverError(code: -1, message: error.localizedDescription))
    }
}
