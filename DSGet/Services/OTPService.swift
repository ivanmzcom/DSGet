//
//  OTPService.swift
//  DSGet
//
//  Service for handling OTP (2FA) authentication.
//

import Foundation

// MARK: - OTPService

@MainActor
final class OTPService {
    var showingSheet = false
    var otpCode = ""

    private var resolve: ((String) -> Void)?
    private var reject: ((Error) -> Void)?

    func requestOTP() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.resolve = { otp in continuation.resume(returning: otp) }
            self.reject = { error in continuation.resume(throwing: error) }
            self.showingSheet = true
        }
    }

    func submit(otp: String) {
        resolve?(otp)
        resolve = nil
        reject = nil
        showingSheet = false
        otpCode = ""
    }

    func cancel() {
        reject?(CancellationError())
        resolve = nil
        reject = nil
        showingSheet = false
        otpCode = ""
    }
}
