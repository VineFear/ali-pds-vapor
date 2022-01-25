//
//  File.swift
//  
//
//  Created by Finer  Vine on 2022/1/25.
//

import Foundation
import Fluent

public final class PDSAccountCredentialsRecord: Model {
    public static let schema = "_fluent_pdsAccountCredentials"

    struct Create: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema("_fluent_pdsAccountCredentials")
                .id()
                .field("key", .string, .required)
                .field("data", .json, .required)
                .unique(on: "key")
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema("_fluent_pdsAccountCredentials").delete()
        }
    }

    public static var migration: Migration {
        Create()
    }
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "key")
    public var key: PDSAccountCredentialsID
    
    @Field(key: "data")
    public var data: PDSAccountCredentials
    
    public init() { }
    
    public init(id: UUID? = nil, key: PDSAccountCredentialsID, data: PDSAccountCredentials) {
        self.id = id
        self.key = key
        self.data = data
    }
}
