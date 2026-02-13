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
    .package(url: "https://github.com/roncuevas/WebViewAMC.git", from: "1.0.0")
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

### WebViewReader (Recommended)

Use `WebViewReader` for reactive state and programmatic control, following the `ScrollViewReader` pattern:

```swift
import SwiftUI
import WebViewAMC

struct BrowserView: View {
    var body: some View {
        WebViewReader { proxy in
            VStack {
                if proxy.isLoading {
                    ProgressView(value: proxy.estimatedProgress)
                }
                WebView(proxy: proxy)
                HStack {
                    Button("Back") { proxy.goBack() }
                        .disabled(!proxy.canGoBack)
                    Button("Forward") { proxy.goForward() }
                        .disabled(!proxy.canGoForward)
                    Button("Reload") { proxy.reload() }
                }
                Text(proxy.title ?? "Untitled")
            }
        }
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

## WebViewProxy

`WebViewProxy` is an `ObservableObject` that provides reactive KVO-backed properties and action methods for the underlying `WKWebView`.

### Reactive Properties

| Property | Type | Description |
|----------|------|-------------|
| `isLoading` | `Bool` | Whether the web view is currently loading |
| `url` | `URL?` | The current URL |
| `title` | `String?` | The current page title |
| `canGoBack` | `Bool` | Whether back navigation is available |
| `canGoForward` | `Bool` | Whether forward navigation is available |
| `estimatedProgress` | `Double` | Page load progress (0.0–1.0) |

### Navigation Actions

```swift
WebViewReader { proxy in
    // Load a URL
    proxy.load("https://example.com")
    proxy.load(URL(string: "https://example.com")!)
    proxy.load("https://example.com", cookies: myCookies, forceRefresh: true)

    // Navigation
    proxy.goBack()
    proxy.goForward()
    proxy.reload()
    proxy.stop()

    // Convenience evaluation (delegates to fetcher)
    let title: String = try await proxy.evaluate("document.title")
    let html = try await proxy.getHTML()
    let result = await proxy.fetch(.once(id: "test", javaScript: "run()"))
}
```

### Subsystem Access

The proxy provides pass-through access to all `WebViewManager` subsystems:

```swift
WebViewReader { proxy in
    proxy.fetcher          // WebViewDataFetcher
    proxy.cookieManager    // CookieManager
    proxy.messageRouter    // WebViewMessageRouter
    proxy.coordinator      // WebViewCoordinator
    proxy.handler          // WebViewMessageHandler
    proxy.configuration    // WebViewConfiguration
    proxy.webView          // WKWebView (direct access)
}
```

### Custom Manager

By default, `WebViewReader` uses `WebViewManager.shared`. Pass a custom manager for isolated instances:

```swift
let manager = WebViewManager(configuration: myConfig)

WebViewReader(manager: manager) { proxy in
    WebView(proxy: proxy)
}
```

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

### Smart Waiting

Replace fixed delays with intelligent wait conditions:

```swift
// Wait for a specific element to appear in the DOM
try await fetcher.waitForElement("#grades-table", timeout: .seconds(10))

// Wait for navigation to complete
try await fetcher.waitForNavigation(timeout: .seconds(15))

// Use with FetchAction — replaces fixed delay
let result = await fetcher.fetch(
    .once(
        id: "grades",
        url: "https://example.com/grades",
        javaScript: "postMessage(getGrades())",
        waitFor: .element("#grades-table")  // waits for element instead of fixed delay
    )
)

// Wait for navigation before polling
let result = await fetcher.fetch(
    .poll(
        id: "data",
        url: "https://example.com",
        javaScript: "postMessage(getData())",
        maxAttempts: 5,
        waitFor: .navigation(timeout: .seconds(10)),
        until: { !data.isEmpty }
    )
)
```

| WaitCondition | Default Timeout | Default Poll Interval | Description |
|---------------|----------------|-----------------------|-------------|
| `.element(_ selector:, timeout:, pollInterval:)` | 10s | 250ms | Polls DOM until CSS selector matches |
| `.navigation(timeout:, pollInterval:)` | 15s | 250ms | Polls until page finishes loading |
| `.none` | — | — | Uses the strategy's fixed delay (default) |

### Typed JavaScript Evaluation

Evaluate JavaScript and get type-safe results:

```swift
// Primitive types
let title: String = try await fetcher.evaluate("document.title")
let count: Int = try await fetcher.evaluate("document.querySelectorAll('.item').length")
let ratio: Double = try await fetcher.evaluate("window.devicePixelRatio")
let loaded: Bool = try await fetcher.evaluate("document.readyState === 'complete'")

// Decodable types from JSON strings
struct Grade: Decodable { let subject: String; let score: Int }
let grades: [Grade] = try await fetcher.evaluate("JSON.stringify(getGrades())")

// Custom JSONDecoder
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let user: User = try await fetcher.evaluate("JSON.stringify(getUserData())", using: decoder)
```

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

### Dynamic Timeout

Change the navigation timeout duration at runtime:

```swift
manager.coordinator.setTimeout(60) // 60 seconds
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
    case .typeCastFailed(let expected, let actual):
        print("Type cast failed: expected \(expected), got \(actual)")
    }
}
```

## Multiple Contexts

Use `WebViewContextGroup` to create multiple isolated web view instances that share cookies via a common `WKProcessPool`:

```swift
let group = WebViewContextGroup()
let loginContext = group.createContext(id: "login")
let gradesContext = group.createContext(id: "grades")
let scheduleContext = group.createContext(id: "schedule")

// All contexts share cookies — login once, scrape from all
await loginContext.fetcher.fetch(.once(id: "login", javaScript: "submitForm()"))
await gradesContext.fetcher.fetch(.poll(
    id: "grades", javaScript: "getGrades()", maxAttempts: 5, until: { !grades.isEmpty }
))
```

### Manual Process Pool Sharing

For finer control, pass a shared `WKProcessPool` directly:

```swift
let pool = WKProcessPool()
let mgr1 = WebViewManager(processPool: pool)
let mgr2 = WebViewManager(processPool: pool)
// mgr1 and mgr2 share cookie storage
```

### Context Group API

| Method | Description |
|--------|-------------|
| `createContext(id:configuration:)` | Creates a new named context with shared pool |
| `context(for:)` | Retrieves a context by ID |
| `removeContext(_:)` | Removes a context |
| `removeAll()` | Removes all contexts |
| `count` | Number of active contexts |
| `ids` | Sorted list of context identifiers |
| `hasContext(_:)` | Whether a context exists |

## Headless Mode

Use `HeadlessWebView` to keep a WKWebView alive in the view hierarchy without it being visible. This prevents iOS from suspending JavaScript execution:

```swift
var body: some View {
    MyContent()
        .background { HeadlessWebView() }
}
```

With a specific context:

```swift
var body: some View {
    MyContent()
        .background { HeadlessWebView(manager: scrapingManager) }
}
```

The view renders at 1x1 pixels with near-zero opacity, invisible to users but active for scraping operations.

## Architecture Overview

```
WebViewManager (singleton or custom instance)
├── webView: WKWebView              — The web view
├── coordinator: WebViewCoordinator  — Navigation delegate + events stream
├── fetcher: WebViewDataFetcher      — Fetch orchestration + task tracking
│   ├── evaluate<T>(_:)             — Typed JavaScript evaluation
│   ├── waitForElement(_:)          — Smart element waiting
│   ├── waitForNavigation()         — Smart navigation waiting
│   └── tasksRunning: AsyncStream   — Stream of active task IDs
├── handler: WebViewMessageHandler   — JS↔Swift bridge
├── messageRouter: WebViewMessageRouter — Type-safe message routing
├── cookieManager: CookieManager     — Cookie operations
└── configuration: WebViewConfiguration — All settings

WebViewContextGroup (optional, manages multiple managers)
└── processPool: WKProcessPool       — Shared cookie storage across contexts

SwiftUI Layer
├── WebViewReader<Content>           — Container view (owns proxy as @StateObject)
├── WebViewProxy                     — ObservableObject with KVO-backed reactive state
├── WebView                          — UIViewRepresentable (accepts proxy or raw WKWebView)
└── HeadlessWebView                  — Invisible view for background scraping
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

The package includes **195 unit tests across 20 suites** covering:

| Suite | Tests | Covers |
|-------|-------|--------|
| WebViewMessageDecoder | 21 | Value type detection, edge cases |
| WebViewDataFetcher | 22 | Fetch strategies, task tracking, wait primitives |
| WebViewProxy | 20 | KVO state, pass-throughs, actions, fetch delegation |
| WebViewTaskManager | 18 | Insert, remove, cancel, await |
| FetchAction | 17 | Strategies, factories, defaults, WaitCondition |
| WebViewContextGroup | 16 | Context creation, removal, process pool sharing, isolation |
| JavaScriptResultMapper | 12 | Type casting, JSON decoding, error cases |
| WebViewMessageRouter | 12 | Routing, fallback, priority, replacement |
| WebViewManager | 10 | Initialization, component wiring, process pool |
| WebViewCoordinator | 10 | Navigation events, timeout, delegation |
| FetchResult | 7 | Convenience properties, Equatable |
| WebViewLogger | 6 | Capture, filtering, levels |
| CookieManager | 5 | Domain cookies, HTTP header formatting |
| Scripts | 5 | Handler interpolation, helpers |
| NavigationEvent | 5 | All event cases |
| HeadlessWebView | 4 | Init, custom manager, body render, context group integration |
| WebViewError | 3 | Equatable, localized descriptions, typeCastFailed |
| WebViewConfiguration | 3 | Defaults, custom values |
| WebViewReader | 2 | Custom manager, proxy init |
| WebViewMessage | 2 | Property storage, value cases |

## License

See [LICENSE](LICENSE) for details.
