import Vapor
import AliPdsVapor
func configure(_ app: Application) throws {
    // MARK: Config AliPDS
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
}
