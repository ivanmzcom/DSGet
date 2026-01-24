//
//  APIConfiguration.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 27/9/25.
//

import Foundation

public struct APIConfiguration: Codable {
    public var host: String
    public var port: Int
    public var username: String
    public var password: String
    public var useHTTPS: Bool
    public var sid: String?
    
    public init(host: String, port: Int, username: String, password: String, useHTTPS: Bool, sid: String? = nil) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.useHTTPS = useHTTPS
        self.sid = sid
    }
}

// MARK: - Keychain Constants

public enum KeychainConstants {
    public static let service = "es.ncrd.DSGet"
    public static let account = "synology"
}

