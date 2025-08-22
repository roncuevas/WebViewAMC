import Foundation
import WebKit
import Dispatch
import os
import Combine

@MainActor
public final class WebViewDataFetcher {
    private let webView: WKWebView
    private let taskManager = WebViewTaskManager()
    
    public var tasksRunning = PassthroughSubject<[String], Never>()
    public var defaultJS: [String]?

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
            while (request.condition?() ?? true) && counter < request.iterations ?? 1 {
                if let url = request.url {
                    try? await Task.sleep(nanoseconds: request.delayToLoad)
                    webView.loadURL(id: request.id,
                                    url: url,
                                    forceRefresh: request.forceRefresh,
                                    cookies: request.cookies)
                }
                try? await Task.sleep(nanoseconds: request.delayToFetch)
                if request.verbose {
                    print("     - Fetching \(request.id) for \(request.iterations == nil ? "infinite" : String(counter))")
                }
                webView.injectJavaScript(
                    handlerName: WebViewManager.handlerName,
                    defaultJS: defaultJS,
                    javaScript: request.javaScript
                )
                try await Task.sleep(nanoseconds: request.delayToNextRequest)
                if let _ = request.iterations {
                    counter += 1
                }
            }
            taskManager.remove(key: request.id)
        }
        taskManager.insert(key: request.id, value: task)
    }
    /*
    private func fetchWhile(id: String,
                           run javaScript: String,
                           delay: UInt64 = 1_000_000_000,
                           while condition: @escaping () -> Bool) {
        let request = DataFetchRequest(id: id,
                                       javaScript: javaScript,
                                       delayToNextRequest: delay,
                                       condition: condition)
        fetch(request: request)
    }

    private func fetchInfinite(id: String,
                              run javaScript: String,
                              delay: UInt64 = 1_000_000_000) {
        let request = DataFetchRequest(id: id,
                                       javaScript: javaScript,
                                       delayToNextRequest: delay,
                                       condition: { true })
        fetch(request: request)
    }
    
    private func fetchFinite(id: String,
                            run javaScript: String,
                            delay: UInt64 = 1_000_000_000,
                            iterations: Int = 15) {
        let request = DataFetchRequest(id: id,
                                       javaScript: javaScript,
                                       delayToNextRequest: delay,
                                       iterations: iterations)
        fetch(request: request)
    }
    
    private func fetchOnce(id: String,
                          run javaScript: String,
                          delay: UInt64 = 1_000_000_000) {
        let request = DataFetchRequest(id: id,
                                       javaScript: javaScript,
                                       delayToNextRequest: delay,
                                       iterations: 1)
        fetch(request: request)
    }
    
    private func fetchIterationsOrWhile(id: String,
                                       run javaScript: String,
                                       delay: UInt64 = 1_000_000_000,
                                       iterations: Int = 15,
                                       while condition: (() -> Bool)? = nil) {
        let request = DataFetchRequest(id: id,
                                       javaScript: javaScript,
                                       delayToNextRequest: delay,
                                       iterations: iterations,
                                       condition: condition)
        fetch(request: request)
    }
    */
    public func fetch(_ requests: [DataFetchRequest],
                      for url: String? = nil) {
        if let url {
            webView.loadURL(id: requests.first?.id,
                            url: url,
                            forceRefresh: requests.first?.forceRefresh ?? false,
                            cookies: requests.first?.cookies)
        }
        for request in requests {
            self.fetch(request: request)
        }
    }
    
    public func debugTaskManager() {
        guard !taskManager.hasTask(at: "DEBUG_TASK_MANAGER") else { return }
        let task = Task {
            while true {
                print("-> Tasks - \(self.taskManager.count): \(self.taskManager.getKeys())")
                tasksRunning.send(taskManager.getKeys())
                await try Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        taskManager.insert(key: "DEBUG_TASK_MANAGER", value: task)
    }
    
    public func cancellAllTasks() {
        Logger().trace("Tasks cancelled: ALL")
        taskManager.removeAll()
    }
    
    public func cancellTasks(_ keys: [String]) {
        Logger().trace("Tasks cancelled: \(keys.description)")
        taskManager.remove(keys)
    }
    
    public func isRunning(_ key: String) -> Bool {
        taskManager.hasTask(at: key)
    }
}
