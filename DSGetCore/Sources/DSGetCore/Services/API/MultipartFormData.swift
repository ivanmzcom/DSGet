import Foundation

/// Multipart form data builder for file uploads.
public struct MultipartFormData: Sendable {
    public let boundary: String
    private var fields: [(String, String)] = []
    private var files: [(name: String, data: Data, fileName: String, mimeType: String)] = []

    public init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    /// Adds a text field.
    public mutating func addField(name: String, value: String) {
        fields.append((name, value))
    }

    /// Adds a file.
    public mutating func addFile(name: String, data: Data, fileName: String, mimeType: String) {
        files.append((name, data, fileName, mimeType))
    }

    /// Builds the multipart data.
    public func build() -> Data {
        var body = Data()

        // Add fields
        for (name, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        // Add files
        for file in files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n")
            body.append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }

        // End boundary
        body.append("--\(boundary)--\r\n")

        return body
    }
}

// MARK: - Data Extension

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
