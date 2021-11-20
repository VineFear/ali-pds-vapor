import Vapor
import AliPdsVapor

func configure(_ app: Application) throws {
    // 中间件
    app.middleware.use(PdsSourcesMiddleware())

    // MARK: Config AliPDS
    /*
     touch .env
     echo "ALI_PDS_SECRET=bc5dfesadfsfsfca8f64086dd9ea2ac" >> .env
     echo "ALI_PDS_DRIVEID=59000000" >> .env
     */
    if let pdsSecret = Environment.get("ALI_PDS_SECRET") {
        app.aliPds.credentials = .init(credentials: .init(secret: pdsSecret))
    }
    
    // register routes
    try routes(app)
}

func routes(_ app: Application) throws {
    
    app.get { req -> String in
        return "Hello, world!"
    }
    
    // http://127.0.0.1:8080/user
    app.get("user") { req async throws -> UserInfoModel in
        let user = try await req.driveClient.user.getUser()
        return user
    }

    // http://127.0.0.1:8080/list?parentId=root
    app.get("list") { req async throws -> FileDriveModel in
        
        guard let driveId = Environment.get("ALI_PDS_DRIVEID") else {
            throw Abort(.badRequest)
        }
        
        guard let parentfileId = req.query[String.self, at: "parentId"] else {
            throw Abort(.notFound, reason: "Please input parentId")
        }
        
        let fileDriveModel = try await req.driveClient.drive.getFileList(driveId: driveId, parentFileId: parentfileId)
        return fileDriveModel
    }
}

extension UserInfoModel: Content { }
extension FileDriveModel: Content { }
