import Foundation
import WebKit
import Combine

@MainActor
public final class WebViewDataFetcher {
    private let webView: WKWebView
    private let taskManager = WebViewTaskManager()
    private let configuration: WebViewConfiguration

    public var tasksRunning = PassthroughSubject<[String], Never>()
    public var defaultJS: [String]?

    public init(webView: WKWebView, configuration: WebViewConfiguration = .default) {
        self.webView = webView
        self.configuration = configuration
    }

    public func getHTML() async throws -> String {
        let response = try await webView.evaluateJavaScript("document.documentElement.outerHTML;")
        return String(describing: response ?? "")
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
                                    cookies: request.cookies,
                                    cookieDomain: configuration.cookieDomain,
                                    logger: configuration.logger)
                }
                try? await Task.sleep(nanoseconds: request.delayToFetch)
                if request.verbose {
                    configuration.logger.log(.debug, "Fetching \(request.id) for \(request.iterations == nil ? "infinite" : String(counter))")
                }
                webView.injectJavaScript(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: request.javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
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

    public func fetch(_ action: FetchAction) async -> FetchResult {
        let id = action.id

        if let url = action.url {
            webView.loadURL(id: id,
                            url: url,
                            forceRefresh: action.forceRefresh,
                            cookies: action.cookies,
                            cookieDomain: configuration.cookieDomain,
                            logger: configuration.logger)
        }

        switch action.strategy {
        case .once(let delay):
            do {
                try await Task.sleep(for: delay)
                guard !Task.isCancelled else { return .cancelled(id) }
                webView.injectJavaScript(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: action.javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
                )
                return .completed(id)
            } catch {
                return .failed(id, .fetchFailed(error.localizedDescription))
            }

        case .poll(let maxAttempts, let delay, let until):
            for attempt in 0..<maxAttempts {
                guard !Task.isCancelled else { return .cancelled(id) }
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return .failed(id, .fetchFailed(error.localizedDescription))
                }
                configuration.logger.log(.debug, "Polling \(id) attempt \(attempt + 1)/\(maxAttempts)")
                webView.injectJavaScript(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: action.javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
                )
                if until() { return .completed(id) }
            }
            return .completed(id)

        case .continuous(let delay, let condition):
            while condition() {
                guard !Task.isCancelled else { return .cancelled(id) }
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return .failed(id, .fetchFailed(error.localizedDescription))
                }
                webView.injectJavaScript(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: action.javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
                )
            }
            return .completed(id)
        }
    }

    public func fetch(_ requests: [DataFetchRequest],
                      for url: String? = nil) {
        if let url {
            webView.loadURL(id: requests.first?.id,
                            url: url,
                            forceRefresh: requests.first?.forceRefresh ?? false,
                            cookies: requests.first?.cookies,
                            cookieDomain: configuration.cookieDomain,
                            logger: configuration.logger)
        }
        for request in requests {
            self.fetch(request: request)
        }
    }

    public func debugTaskManager() {
        guard !taskManager.hasTask(at: "DEBUG_TASK_MANAGER") else { return }
        let task = Task {
            while true {
                configuration.logger.log(.debug, "Tasks - \(self.taskManager.count): \(self.taskManager.keys)")
                tasksRunning.send(taskManager.keys)
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        taskManager.insert(key: "DEBUG_TASK_MANAGER", value: task)
    }

    public func cancelAllTasks() {
        configuration.logger.log(.info, "Tasks cancelled: ALL")
        taskManager.removeAll()
    }

    public func cancelTasks(_ keys: [String]) {
        configuration.logger.log(.info, "Tasks cancelled: \(keys.description)")
        taskManager.remove(keys)
    }

    @available(*, deprecated, renamed: "cancelAllTasks")
    public func cancellAllTasks() {
        cancelAllTasks()
    }

    @available(*, deprecated, renamed: "cancelTasks")
    public func cancellTasks(_ keys: [String]) {
        cancelTasks(keys)
    }

    public func isRunning(_ key: String) -> Bool {
        taskManager.hasTask(at: key)
    }
}
