import Foundation
import WebKit
import Dispatch

@MainActor
public final class WebViewDataFetcher {
    private let webView: WKWebView
    private let taskManager = WebViewTaskManager()
    
    public init(webView: WKWebView) {
        self.webView = webView
    }
    
    public func getHTML() async -> String {
        do {
            let response = await try? webView.evaluateJavaScript("document.documentElement.outerHTML;")
            let string = String(describing: response ?? "")
            return string
        } catch {
            print("-> ERROR FETCHING HTML: \(error)")
        }
    }
    
    private func fetch(request: DataFetchRequest) {
        let task = Task {
            var counter = 0
            repeat {
                print("-> Fetching \(request.description) for \(request.iterations == nil ? "infinite" : String(counter))")
                print("-> Tasks: \(taskManager.count)")
                webView.injectJavaScript(handlerName: WebViewManager.handlerName,
                                         javaScript: request.javaScript)
                try await Task.sleep(nanoseconds: request.delay)
                if let _ = request.iterations {
                    counter += 1
                }
            } while (request.condition?() ?? true) && counter < request.iterations ?? 1
            taskManager.remove(key: request.id)
        }
        taskManager.add(key: request.id, value: task)
    }
    
    public func fetchWhile(run javaScript: String,
                           delay: UInt64 = 1_000_000_000,
                           description: String = "",
                           while condition: @escaping () -> Bool) {
        let request = DataFetchRequest(javaScript: javaScript,
                                       delay: delay,
                                       description: description,
                                       condition: condition)
        fetch(request: request)
    }
    
    public func fetchInfinite(run javaScript: String,
                              delay: UInt64 = 1_000_000_000,
                              description: String = "") {
        let request = DataFetchRequest(javaScript: javaScript,
                                       delay: delay,
                                       description: description,
                                       condition: { true })
        fetch(request: request)
    }
    
    public func fetchFinite(run javaScript: String,
                            delay: UInt64 = 1_000_000_000,
                            description: String = "",
                            iterations: Int = 15) {
        let request = DataFetchRequest(javaScript: javaScript,
                                       delay: delay,
                                       description: description,
                                       iterations: iterations)
        fetch(request: request)
    }
    
    public func fetchOnce(run javaScript: String,
                          delay: UInt64 = 1_000_000_000,
                          description: String = "") {
        let request = DataFetchRequest(javaScript: javaScript,
                                       delay: delay,
                                       description: description,
                                       iterations: 1)
        fetch(request: request)
    }
    
    public func fetchIterationsOrWhile(run javaScript: String,
                                       delay: UInt64 = 1_000_000_000,
                                       description: String = "",
                                       iterations: Int = 15,
                                       while condition: (() -> Bool)? = nil) {
        let request = DataFetchRequest(javaScript: javaScript,
                                       delay: delay,
                                       description: description,
                                       iterations: iterations,
                                       condition: condition)
        fetch(request: request)
    }
    
    public func addTask(from url: String,
                        delayToRun: UInt64 = 1_000_000_000,
                        fetch: [DataFetchRequest]) async {
        webView.loadURL(url: url)
        try? await Task.sleep(nanoseconds: delayToRun)
        for request in fetch {
            self.fetch(request: request)
        }
    }
}

public struct DataFetchRequest {
    let id = UUID()
    let javaScript: String
    let delay: UInt64
    let description: String
    let iterations: Int?
    let condition: (() -> Bool)?
    
    public init(javaScript: String,
                delay: UInt64 = 1_000_000_000,
                description: String,
                iterations: Int? = nil,
                condition: ( () -> Bool)? = nil) {
        self.javaScript = javaScript
        self.delay = delay
        self.description = description
        self.iterations = iterations
        self.condition = condition
    }
}
