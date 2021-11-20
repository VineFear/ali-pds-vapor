import Vapor

public struct PdsSourcesMiddleware: AsyncMiddleware {
    
    let pdsPrefixDelimiter: String
    
    public init(pdsPrefixDelimiter: String = "pds-prefix/") {
        self.pdsPrefixDelimiter = pdsPrefixDelimiter
    }
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        
        // 如果有前缀，重定向到去除前缀
        guard let range = request.url.string.range(of: pdsPrefixDelimiter) else {
            return try await next.respond(to: request)
        }
        let realPath = String(request.url.string[range.upperBound...])
        let headers: HTTPHeaders = ["Referer": "https://www.aliyundrive.com/"]
        let clientResponse: ClientResponse = try await request.client.get(.init(string: realPath), headers: headers)
        let response = try await clientResponse.encodeResponse(for: request)
        return response
    }
}
