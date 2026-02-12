import Foundation
import WebKit
import Combine

@MainActor
public final class WebViewDataFetcher {
    private let webView: WKWebView
    private let taskManager = WebViewTaskManager()
    private let configuration: WebViewConfiguration

    public var tasksRunning = PassthroughSubject<[String], Never>()

    private let tasksRunningContinuation: AsyncStream<[String]>.Continuation
    public let tasksRunningStream: AsyncStream<[String]>

    public var defaultJS: [String]?

    public init(webView: WKWebView, configuration: WebViewConfiguration = .default) {
        self.webView = webView
        self.configuration = configuration
        var continuation: AsyncStream<[String]>.Continuation!
        self.tasksRunningStream = AsyncStream { continuation = $0 }
        self.tasksRunningContinuation = continuation
    }

    public func getHTML() async throws -> String {
        let response = try await webView.evaluateJavaScript("document.documentElement.outerHTML;")
        return String(describing: response ?? "")
    }

    // MARK: - FetchAction API

    public func fetch(_ action: FetchAction) async -> FetchResult {
        let id = action.id

        let task = Task<FetchResult, Never> {
            if let url = action.url {
                webView.loadURL(id: id,
                                url: url,
                                forceRefresh: action.forceRefresh,
                                cookies: action.cookies,
                                cookieDomain: configuration.cookieDomain,
                                logger: configuration.logger)
            }

            let result: FetchResult
            switch action.strategy {
            case .once(let delay):
                result = await fetchOnce(id: id, javaScript: action.javaScript, delay: delay)
            case .poll(let maxAttempts, let delay, let until):
                result = await fetchPoll(id: id, javaScript: action.javaScript, maxAttempts: maxAttempts, delay: delay, until: until)
            case .continuous(let delay, let condition):
                result = await fetchContinuous(id: id, javaScript: action.javaScript, delay: delay, condition: condition)
            }

            taskManager.remove(key: id)
            return result
        }
        taskManager.insert(key: id, value: Task { _ = try await task.value })

        return await task.value
    }

    private func fetchOnce(id: String, javaScript: String, delay: Duration) async -> FetchResult {
        do {
            try await Task.sleep(for: delay)
            guard !Task.isCancelled else { return .cancelled(id) }
            try await webView.injectJavaScriptAsync(
                handlerName: configuration.handlerName,
                defaultJS: defaultJS,
                javaScript: javaScript,
                verbose: configuration.verbose,
                logger: configuration.logger
            )
            return .completed(id)
        } catch is CancellationError {
            return .cancelled(id)
        } catch {
            return .failed(id, .fetchFailed(error.localizedDescription))
        }
    }

    private func fetchPoll(id: String, javaScript: String, maxAttempts: Int, delay: Duration, until: @Sendable @MainActor () -> Bool) async -> FetchResult {
        for attempt in 0..<maxAttempts {
            guard !Task.isCancelled else { return .cancelled(id) }
            do {
                try await Task.sleep(for: delay)
            } catch {
                return .cancelled(id)
            }
            configuration.logger.log(.debug, "Polling \(id) attempt \(attempt + 1)/\(maxAttempts)")
            try? await webView.injectJavaScriptAsync(
                handlerName: configuration.handlerName,
                defaultJS: defaultJS,
                javaScript: javaScript,
                verbose: configuration.verbose,
                logger: configuration.logger
            )
            if until() { return .completed(id) }
        }
        return .completed(id)
    }

    private func fetchContinuous(id: String, javaScript: String, delay: Duration, condition: @Sendable @MainActor () -> Bool) async -> FetchResult {
        while condition() {
            guard !Task.isCancelled else { return .cancelled(id) }
            do {
                try await Task.sleep(for: delay)
            } catch {
                return .cancelled(id)
            }
            try? await webView.injectJavaScriptAsync(
                handlerName: configuration.handlerName,
                defaultJS: defaultJS,
                javaScript: javaScript,
                verbose: configuration.verbose,
                logger: configuration.logger
            )
        }
        return .completed(id)
    }

    // MARK: - Legacy DataFetchRequest API

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

    @available(*, deprecated, message: "Use fetch(_ action: FetchAction) instead")
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

    // MARK: - Task Management

    public func debugTaskManager() {
        guard !taskManager.hasTask(at: "DEBUG_TASK_MANAGER") else { return }
        let task = Task {
            while true {
                configuration.logger.log(.debug, "Tasks - \(self.taskManager.count): \(self.taskManager.keys)")
                tasksRunning.send(taskManager.keys)
                tasksRunningContinuation.yield(taskManager.keys)
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
