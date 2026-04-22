import Foundation

extension String {
    static func watchLocalized(_ key: String, _ args: CVarArg...) -> String {
        if args.isEmpty {
            return NSLocalizedString(key, comment: "")
        }

        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: args)
    }
}
