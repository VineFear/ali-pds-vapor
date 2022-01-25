//
//  File.swift
//  
//
//  Created by Finer  Vine on 2022/1/25.
//

import Foundation
import Vapor
import Fluent
@_exported import Core

public class DatabasePDSAccountCredential: PDSAccountCredentialDriver {
    
    let db: Database
    var credentialsID: PDSAccountCredentialsID?
    
    public init(db: Database) {
        self.db = db
    }
    
    public func createCredential(_ data: PDSAccountCredentials) async throws -> PDSAccountCredentialsID {
        guard let credentialsID = credentialsID else {
            let newCredentialsID = PDSAccountCredentialsID.init(string: data.secret)
            // 先查询
            guard (try await PDSAccountCredentialsRecord.query(on: db)
                    .filter(\.$key == newCredentialsID)
                    .first()?.data) != nil else {
                // 存储新数据
                try await PDSAccountCredentialsRecord(key: newCredentialsID, data: data).create(on: db)
                credentialsID = newCredentialsID
                return newCredentialsID
            }
            credentialsID = newCredentialsID
            return newCredentialsID
        }
        return credentialsID
    }
    
    public func readCredential(_ credentialsID: PDSAccountCredentialsID) async throws -> PDSAccountCredentials {
        let credentials = try await PDSAccountCredentialsRecord.query(on: db)
            .filter(\.$key == credentialsID)
            .first()?.data
        guard let credentials = credentials else {
            throw OauthRefreshError.psdCredentialsNotFound
        }
        return credentials
    }
    
    public func updateCredential(_ credentialsID: PDSAccountCredentialsID, to data: PDSAccountCredentials) async throws -> PDSAccountCredentialsID {
        try await PDSAccountCredentialsRecord.query(on: db)
            .filter(\.$key == credentialsID)
            .set(\.$data, to: data)
            .update()
        return credentialsID
    }
    
    public func deleteCredential(_ credentialsID: PDSAccountCredentialsID) async throws {
        try await PDSAccountCredentialsRecord.query(on: db)
            .filter(\.$key == credentialsID)
            .delete()
    }
}

enum OauthRefreshError: Error {
    case psdCredentialsNotFound
    
    var localizedDescription: String {
        switch self {
        case .psdCredentialsNotFound:
            return "credentials not found"
        }
    }
}
