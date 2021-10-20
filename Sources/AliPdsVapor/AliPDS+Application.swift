//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/7/1.
//

import Vapor
@_exported import Core

extension Application {
    public var aliPds: AliPDS {
        .init(application: self, logger: self.logger)
    }
    
    private struct PdsCredentialsKey: StorageKey {
        typealias Value = PDSCredentialsConfiguration
    }
    
    public struct AliPDS {
        public let application: Application
        public let logger: Logger
        
        public var credentials: PDSCredentialsConfiguration {
            get {
                if let credentials = application.storage[PdsCredentialsKey.self] {
                    return credentials
                } else {
                    fatalError("Cloud credentials configuration has not been set. Use app.microsoftGraph.credentials = ...")
                }
            }
            nonmutating set {
                if application.storage[PdsCredentialsKey.self] == nil {
                    application.storage[PdsCredentialsKey.self] = newValue
                } else {
                    fatalError("Overriding credentials configuration after being set is not allowed.")
                }
            }
        }
    }
}

extension Application.AliPDS {
    public struct PDSDriveAPI {
        public let application: Application
        public let eventLoop: EventLoop
        public let logger: Logger
        
        public var client: AliDriveClient {
            let new =  AliDriveClient.init(credentials: self.application.aliPds.credentials, httpClient: self.http, eventLoop: self.eventLoop, logger: self.logger)
            return new
        }
        
        
        /// Custom `HTTPClient` that ignores unclean SSL shutdown.
        private struct AliPDSHTTPClientKey: StorageKey, LockKey {
            typealias Value = HTTPClient
        }
        public var http: HTTPClient {
            if let existing = application.storage[AliPDSHTTPClientKey.self] {
                return existing
            } else {
                let lock = application.locks.lock(for: AliPDSHTTPClientKey.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = application.storage[AliPDSHTTPClientKey.self] {
                    return existing
                }
                let new = HTTPClient(
                    eventLoopGroupProvider: .shared(application.eventLoopGroup),
                    configuration: HTTPClient.Configuration(ignoreUncleanSSLShutdown: true)
                )
                application.storage.set(AliPDSHTTPClientKey.self, to: new) {
                    try $0.syncShutdown()
                }
                return new
            }
        }
    }
    
    // 客户端
    private struct AliPDSAppDriveAPIKey: StorageKey {
        typealias Value = PDSDriveAPI
    }
    public var aliPdsDrive: PDSDriveAPI {
        get {
            if let existing = self.application.storage[AliPDSAppDriveAPIKey.self] {
                return existing
            } else {
                return .init(application: self.application, eventLoop: self.application.eventLoopGroup.next(), logger: self.logger)
            }
        }
        
        nonmutating set {
            self.application.storage[AliPDSAppDriveAPIKey.self] = newValue
        }
    }
}

extension Request {
    
    private struct AliPdsDriveKey: StorageKey {
        typealias Value = AliDriveClient
    }
    
    public var driveClient: AliDriveClient {
        if let existing = application.storage[AliPdsDriveKey.self] {
            return existing.hopped(to: self.eventLoop)
        } else {
            let client = Application.AliPDS.PDSDriveAPI(application: self.application, eventLoop: self.eventLoop, logger: self.logger).client
            application.storage[AliPdsDriveKey.self] = client
            return client
        }
    }
}
