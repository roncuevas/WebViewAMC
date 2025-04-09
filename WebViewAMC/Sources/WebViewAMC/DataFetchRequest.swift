import Foundation

public struct DataFetchRequest {
    let id: String
    let url: String?
    let forceRefresh: Bool
    let javaScript: String
    let delayToLoad: UInt64
    let delayToFetch: UInt64
    let delayToNextRequest: UInt64
    let verbose: Bool
    let iterations: Int?
    let cookies: [HTTPCookie]?
    let condition: (() -> Bool)?
    
    public init(id: String,
                url: String? = nil,
                forceRefresh: Bool = false,
                javaScript: String,
                delayToLoad: UInt64 = 0,
                delayToFetch: UInt64 = 1_000_000_000,
                delayToNextRequest: UInt64 = 1_000_000_000,
                verbose: Bool = true,
                iterations: Int? = nil,
                cookies: [HTTPCookie]? = nil,
                condition: ( () -> Bool)? = nil) {
        self.id = id
        self.url = url
        self.forceRefresh = forceRefresh
        self.javaScript = javaScript
        self.delayToLoad = delayToLoad
        self.delayToFetch = delayToFetch
        self.delayToNextRequest = delayToNextRequest
        self.verbose = verbose
        self.iterations = iterations
        self.cookies = cookies
        self.condition = condition
    }
}
