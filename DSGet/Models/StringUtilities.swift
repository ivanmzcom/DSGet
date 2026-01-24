import Foundation

func firstNonEmpty(_ values: String?...) -> String? {
    for value in values {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
    }
    return nil
}
