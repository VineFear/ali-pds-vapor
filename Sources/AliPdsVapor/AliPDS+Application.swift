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
    
    public struct AliPDS {
        public let application: Application
        public let logger: Logger
        
        /// 这里是存储
        public class PDSStorage {
            var makeDriver: ((Application) -> PDSAccountCredentialDriver)?
            var credentials: PDSAccountCredentials
            public init(credentials: PDSAccountCredentials,
                        driver: ((Application) -> PDSAccountCredentialDriver)? = { _ in MemoryAccountCredential.init(storage: .init()) }) {
                self.credentials = credentials
                self.makeDriver = driver
            }
        }
        
        public var driver: PDSAccountCredentialDriver {
            guard let makeDriver = self.storage.makeDriver else {
                fatalError("No driver configured. Configure with app.aliPds.use(...)")
            }
            return makeDriver(self.application)
        }
        
        public func use(_ makeDriver: @escaping (Application) -> (PDSAccountCredentialDriver)) {
            self.storage.makeDriver = makeDriver
        }
        
        /// 应用持久化
        public var storage: PDSStorage {
            get {
                if let storage = application.storage[PdsStorageKey.self] {
                    return storage
                } else {
                    fatalError("Cloud credentials configuration has not been set. Use aliPds.storage = ...")
                }
            }
            nonmutating set {
                if application.storage[PdsStorageKey.self] == nil {
                    application.storage[PdsStorageKey.self] = newValue
                } else {
                    fatalError("Overriding credentials configuration after being set is not allowed.")
                }
            }
        }
        private struct PdsStorageKey: StorageKey {
            typealias Value = PDSStorage
        }
    }
}

extension Application.AliPDS {
    public struct PDSDriveAPI {
        public let application: Application
        public let eventLoop: EventLoop
        public let logger: Logger
        
        public var client: AliDriveClient {
            let new =  AliDriveClient.init(credentialsDriver: self.application.aliPds.driver, credentials: self.application.aliPds.storage.credentials, httpClient: self.http, eventLoop: self.eventLoop, logger: self.logger)
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
