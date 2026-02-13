# WebViewAMC

A generic Swift Package for web scraping and interaction with websites through WKWebView. Provides a SwiftUI wrapper, type-safe JavaScript messaging, configurable cookie management, and async fetch strategies — all with Swift 6 concurrency support.

## Requirements

- iOS 16.0+
- Swift 6.0+
- Xcode 16+

## Installation

### Swift Package Manager

Add WebViewAMC to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/WebViewAMC.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

## Quick Start

### Basic Setup

```swift
import WebViewAMC

// Use the shared singleton with default configuration
let manager = WebViewManager.shared

// Or create a custom instance
let config = WebViewConfiguration(
    handlerName: "myApp",
    timeoutDuration: 60,
    isInspectable: true,
    cookieDomain: URL(string: "https://example.com"),
    verbose: true
)
let manager = WebViewManager(configuration: config)
```

### Display the WebView in SwiftUI

```swift
import SwiftUI
import WebViewAMC

struct BrowserView: View {
    var body: some View {
        WebView(webView: WebViewManager.shared.webView)
    }
}
```

## Configuration

`WebViewConfiguration` controls all behavior of the package:

```swift
let config = WebViewConfiguration(
    handlerName: "myNativeApp",   // JS message handler name (default)
    timeoutDuration: 30.0,        // Navigation timeout in seconds
    isInspectable: false,         // Safari Web Inspector (iOS 16.4+)
    cookieDomain: nil,            // Domain for cookie management
    verbose: false,               // Verbose JS error logging
    logger: WebViewLogger()       // Custom logger
)
```

Use `WebViewConfiguration.default` for sensible defaults.

## Fetching Data

### FetchAction

`FetchAction` provides an awaitable API with three strategies:

```swift
let manager = WebViewManager.shared

// One-shot fetch
let result = await manager.fetcher.fetch(
    .once(
        id: "getTitle",
        url: "https://example.com",
        javaScript: "postMessage({ title: document.title })"
    )
)

// Check result using convenience properties
if result.isCompleted {
    print("Fetch \(result.id) completed")
} else if result.isFailed {
    print("Error: \(result.error?.localizedDescription ?? "unknown")")
}

// Or use pattern matching
switch result {
case .completed(let id):
    print("Fetch \(id) completed")
case .cancelled(let id):
    print("Fetch \(id) was cancelled")
case .failed(let id, let error):
    print("Fetch \(id) failed: \(error.localizedDescription)")
}
```

### Fetch Strategies

```swift
// Once: execute JS after a delay (default: 1 second)
.once(id: "title", javaScript: "postMessage({ title: document.title })")

// Once with custom delay
.once(id: "title", javaScript: "...", delay: .seconds(2))

// Poll: retry up to N times until a condition is met
.poll(
    id: "grades",
    url: "https://example.com/grades",
    javaScript: "postMessage({ grades: getGrades() })",
    maxAttempts: 5,
    delay: .seconds(1),
    until: { !grades.isEmpty }
)

// Continuous: keep executing while a condition holds
.continuous(
    id: "captcha",
    javaScript: "postMessage({ img: getCaptcha() })",
    delay: .milliseconds(500),
    while: { needsCaptcha }
)
```

### FetchResult

`FetchResult` is `Equatable` and provides convenience properties:

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The task identifier |
| `isCompleted` | `Bool` | `true` if fetch completed |
| `isCancelled` | `Bool` | `true` if fetch was cancelled |
| `isFailed` | `Bool` | `true` if fetch failed |
| `error` | `WebViewError?` | The error, if failed |

### Get Current Page HTML

```swift
if let html = try await manager.fetcher.getHTML() {
    print(html)
}
```

## Message Handling

WebViewAMC provides two approaches for receiving JavaScript messages.

### Message Router (recommended)

Type-safe message routing with automatic value decoding:

```swift
let router = manager.messageRouter

// Register handlers for specific keys
router.register(key: "grades") { message in
    switch message.value {
    case .json(let data):
        let grades = try? JSONDecoder().decode([Grade].self, from: data)
    case .string(let text):
        print("Received: \(text)")
    default:
        break
    }
}

router.register(key: "profileImage") { message in
    if case .data(let imageData) = message.value {
        let image = UIImage(data: imageData)
    }
}

// Catch-all for unregistered keys
router.registerFallback { message in
    print("Unhandled message: \(message.key)")
}

// Clean up
router.unregister(key: "grades")
router.unregisterAll()
```

#### Message Value Types

The decoder automatically detects the value type:

| JS Value | Decoded As |
|----------|------------|
| `"hello"` | `.string("hello")` |
| `"1"` / `"0"` | `.bool(true)` / `.bool(false)` |
| `'{"key":"val"}'` | `.json(Data)` |
| `'[1,2,3]'` | `.json(Data)` |
| `"data:image/jpeg;base64,..."` | `.data(Data)` |
| `{ key1: "val1", key2: "val2" }` | `.dictionary([String: String])` |

### Delegate Pattern

```swift
class MyHandler: WebViewMessageHandlerDelegate {
    func messageReceiver(message: [String: Any]) {
        // Handle raw dictionary
    }
}

manager.handler.delegate = myHandler
```

> When a `router` is set on `WebViewMessageHandler`, messages are routed through it. The delegate is used as fallback only when no router is present.

## Cookie Management

```swift
let cookies = manager.cookieManager

// Inject cookies asynchronously
await cookies.injectCookies(myCookies)

// Inject cookies synchronously (fire-and-forget)
cookies.setCookiesSync(myCookies)

// Get all cookies
let all = await cookies.getAllCookies()

// Get cookies for the configured domain
let domainCookies = cookies.cookiesForDomain()

// Remove specific cookies by name
await cookies.removeCookies(named: ["session", "token"])

// Remove all cookies
await cookies.removeAllCookies()

// Format cookies for HTTP headers
let header = CookieManager.formatForHTTPHeader(myCookies)
// "session=abc123; token=xyz789"
```

## Navigation Events

Monitor navigation lifecycle via delegate or AsyncStream:

### AsyncStream

```swift
let coordinator = manager.coordinator

Task {
    for await event in coordinator.events {
        switch event {
        case .started:
            print("Navigation started")
        case .finished(let url):
            print("Navigated to: \(url?.absoluteString ?? "unknown")")
        case .failed(let error):
            print("Navigation failed: \(error)")
        case .timeout:
            print("Navigation timed out")
        }
    }
}
```

### Delegate

```swift
class MyCoordinator: WebViewCoordinatorDelegate {
    func didNavigateTo(url: URL) { }
    func cookiesReceiver(cookies: [HTTPCookie]) { }
    func didFailLoading(error: Error) { }
    func didTimeout() { }
}

manager.coordinator.delegate = myCoordinator
```

## JavaScript Injection

### Using Scripts Helpers

The package injects common DOM helper functions automatically:

```javascript
// Available in every injected script:
byID("elementId")              // document.getElementById
byClass("className")           // document.getElementsByClassName
byTag("tagName")               // document.getElementsByTagName
byName("name")                 // document.getElementsByName
bySelector("css > selector")   // document.querySelector
bySelectorAll(".items")        // document.querySelectorAll
imageToData(element, scale)    // Convert img to base64 data URI
postMessage({ key: "value" })  // Send message to native app
```

### Custom Scripts

```swift
// Generate a script with common helpers + your own
let script = Scripts.custom(
    handlerName: "myApp",
    additionalHelpers: [
        "function getGrades() { return bySelector('.grades-table').innerHTML; }"
    ]
)
```

### Direct Injection

```swift
try await manager.webView.injectJavaScriptAsync(
    handlerName: "myApp",
    defaultJS: ["var config = { debug: true };"],
    javaScript: "postMessage({ title: document.title })",
    verbose: true
)
```

## Logging

### Built-in Logger

```swift
let logger = WebViewLogger(
    subsystem: "com.myapp",
    category: "WebScraping",
    minimumLevel: .debug       // .debug | .info | .warning | .error
)

let config = WebViewConfiguration(logger: logger, verbose: true)
```

### Custom Logger

Conform to `WebViewLoggerProtocol`:

```swift
struct MyLogger: WebViewLoggerProtocol {
    func log(_ level: WebViewLogLevel, _ message: String, source: String) {
        // Send to your analytics, file, etc.
    }
}

let config = WebViewConfiguration(logger: MyLogger())
```

## Task Management

Control running fetch tasks:

```swift
let fetcher = manager.fetcher

// Check if a task is running
if fetcher.isRunning("grades") { ... }

// Cancel specific tasks
fetcher.cancelTasks(["grades", "schedule"])

// Cancel all tasks
fetcher.cancelAllTasks()

// Monitor running tasks via AsyncStream
Task {
    for await runningKeys in fetcher.tasksRunning {
        print("Active tasks: \(runningKeys)")
    }
}
```

> If `fetch()` is called with an ID that's already running, the previous task is automatically cancelled and a warning is logged.

## Error Handling

All errors are typed via `WebViewError`:

```swift
do {
    let html = try await manager.fetcher.getHTML()
} catch let error as WebViewError {
    switch error {
    case .invalidURL(let url):
        print("Bad URL: \(url)")
    case .javaScriptEvaluation(let detail):
        print("JS error: \(detail)")
    case .timeout:
        print("Request timed out")
    case .navigationFailed(let detail):
        print("Nav failed: \(detail)")
    case .taskCancelled(let id):
        print("Task \(id) cancelled")
    case .fetchFailed(let detail):
        print("Fetch failed: \(detail)")
    case .messageDecodingFailed(let detail):
        print("Decode failed: \(detail)")
    }
}
```

## Architecture Overview

```
WebViewManager (singleton or custom instance)
├── webView: WKWebView              — The web view
├── coordinator: WebViewCoordinator  — Navigation delegate + events stream
├── fetcher: WebViewDataFetcher      — Fetch orchestration + task tracking
│   └── tasksRunning: AsyncStream    — Stream of active task IDs
├── handler: WebViewMessageHandler   — JS↔Swift bridge
├── messageRouter: WebViewMessageRouter — Type-safe message routing
├── cookieManager: CookieManager     — Cookie operations
└── configuration: WebViewConfiguration — All settings
```

### Protocols

| Protocol | Purpose |
|----------|---------|
| `WebViewManaging` | Abstracts the manager for testing |
| `JavaScriptEvaluating` | Abstracts JS evaluation (WKWebView conforms) |
| `WebViewCoordinatorDelegate` | Navigation lifecycle callbacks |
| `WebViewMessageHandlerDelegate` | Raw message reception |
| `WebViewLoggerProtocol` | Custom logging backends |

## Testing

The package is iOS-only, so tests must run on a simulator:

```bash
xcodebuild test -scheme WebViewAMC \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

The package includes **127 unit tests across 15 suites** covering:

| Suite | Tests | Covers |
|-------|-------|--------|
| WebViewMessageDecoder | 21 | Value type detection, edge cases |
| WebViewTaskManager | 18 | Insert, remove, cancel, await |
| WebViewDataFetcher | 18 | Fetch strategies, task tracking, cancellation |
| WebViewMessageRouter | 12 | Routing, fallback, priority, replacement |
| FetchAction | 12 | Strategies, factories, defaults |
| WebViewCoordinator | 10 | Navigation events, timeout, delegation |
| FetchResult | 7 | Convenience properties, Equatable |
| WebViewManager | 7 | Initialization, component wiring |
| WebViewLogger | 6 | Capture, filtering, levels |
| CookieManager | 5 | Domain cookies, HTTP header formatting |
| Scripts | 5 | Handler interpolation, helpers |
| NavigationEvent | 5 | All event cases |
| WebViewError | 2 | Equatable, localized descriptions |
| WebViewMessage | 2 | Property storage, value cases |
| WebViewConfiguration | 3 | Defaults, custom values |

## License

See [LICENSE](LICENSE) for details.
