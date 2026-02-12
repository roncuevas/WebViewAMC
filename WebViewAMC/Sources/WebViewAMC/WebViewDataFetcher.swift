import Foundation
import WebKit

@MainActor
public final class WebViewDataFetcher {
    private let webView: WKWebView
    private let taskManager = WebViewTaskManager()
    private let configuration: WebViewConfiguration

    private let tasksRunningContinuation: AsyncStream<[String]>.Continuation
    public let tasksRunning: AsyncStream<[String]>

    public var defaultJS: [String]?

    public init(webView: WKWebView, configuration: WebViewConfiguration = .default) {
        self.webView = webView
        self.configuration = configuration
        var continuation: AsyncStream<[String]>.Continuation!
        self.tasksRunning = AsyncStream { cont in
            cont.onTermination = { _ in }
            continuation = cont
        }
        self.tasksRunningContinuation = continuation
    }

    deinit {
        tasksRunningContinuation.finish()
    }

    public func getHTML() async throws -> String? {
        let response = try await webView.evaluateJavaScript("document.documentElement.outerHTML;")
        return response as? String
    }

    // MARK: - FetchAction API

    public func fetch(_ action: FetchAction) async -> FetchResult {
        let id = action.id

        if taskManager.hasTask(at: id) {
            configuration.logger.log(.warning, "Task '\(id)' already running — cancelling previous instance")
            taskManager.remove([id])
        }

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
        taskManager.insert(key: id, value: Task { _ = await task.value })

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
            do {
                try await webView.injectJavaScriptAsync(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
                )
            } catch is CancellationError {
                return .cancelled(id)
            } catch {
                configuration.logger.log(.warning, "Polling \(id) attempt \(attempt + 1) failed: \(error.localizedDescription)")
            }
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
            do {
                try await webView.injectJavaScriptAsync(
                    handlerName: configuration.handlerName,
                    defaultJS: defaultJS,
                    javaScript: javaScript,
                    verbose: configuration.verbose,
                    logger: configuration.logger
                )
            } catch is CancellationError {
                return .cancelled(id)
            } catch {
                configuration.logger.log(.warning, "Continuous \(id) iteration failed: \(error.localizedDescription)")
            }
        }
        return .completed(id)
    }

    // MARK: - Task Management

    public func debugTaskManager() {
        guard !taskManager.hasTask(at: "DEBUG_TASK_MANAGER") else { return }
        let task = Task {
            while true {
                configuration.logger.log(.debug, "Tasks - \(self.taskManager.count): \(self.taskManager.keys)")
                tasksRunningContinuation.yield(taskManager.keys)
                try await Task.sleep(for: .seconds(1))
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

    public func isRunning(_ key: String) -> Bool {
        taskManager.hasTask(at: key)
    }
}
