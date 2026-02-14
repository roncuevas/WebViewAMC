# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WebViewAMC is a Swift Package for web scraping and interaction with websites through WKWebView. It provides SwiftUI wrappers, type-safe JavaScript messaging, cookie management, and async fetch strategies with Swift 6 concurrency support.

- **Platform:** iOS 16.0+
- **Swift:** 6.0+ (strict concurrency with `@MainActor` and `Sendable` throughout)
- **Dependencies:** None (self-contained, WebKit-only)
- **License:** AGPL-3.0

## Build & Test Commands

This is an iOS-only Swift Package — `swift build` and `swift test` will fail on macOS. Use xcodebuild with a simulator:

```bash
# Build
xcodebuild build -scheme WebViewAMC -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run all tests (195 tests across 20 suites)
xcodebuild test -scheme WebViewAMC -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a single test suite
xcodebuild test -scheme WebViewAMC -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WebViewAMCTests/WebViewDataFetcherTests

# Run a single test method
xcodebuild test -scheme WebViewAMC -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WebViewAMCTests/WebViewDataFetcherTests/testFetchOnceCompletes
```

No linter is configured. Static analysis relies on Swift 6 strict concurrency checking and Xcode diagnostics.

## Architecture

```
WebViewManager (singleton or custom instance, @MainActor)
├── webView: WKWebView
├── coordinator: WebViewCoordinator      — WKNavigationDelegate, yields NavigationEvent via AsyncStream
├── fetcher: WebViewDataFetcher          — Orchestrates fetch strategies, typed JS evaluation, wait primitives
│   └── taskManager: WebViewTaskManager  — Tracks/cancels running Task instances
├── handler: WebViewMessageHandler       — WKScriptMessageHandler (JS→Swift bridge)
├── messageRouter: WebViewMessageRouter  — Type-safe message routing by key with fallback
├── cookieManager: CookieManager         — Cookie injection/retrieval via WKHTTPCookieStore
└── configuration: WebViewConfiguration  — All settings (handler name, timeout, inspectable, cookie domain, logger)

WebViewContextGroup — Creates multiple WebViewManager instances sharing a WKProcessPool (shared cookies)

SwiftUI Layer
├── WebViewReader<Content>  — Container view, owns WebViewProxy as @StateObject
├── WebViewProxy            — ObservableObject with KVO-backed reactive state (url, title, isLoading, etc.)
├── WebView                 — UIViewRepresentable (accepts proxy or raw WKWebView)
└── HeadlessWebView         — 1x1 invisible view keeping WKWebView alive for background scraping
```

### Key Design Decisions

- **All public API is `@MainActor`** — WKWebView requires main thread access; the entire manager hierarchy enforces this at compile time.
- **Protocols for testability** — `WebViewManaging` and `JavaScriptEvaluating` abstract the manager and WKWebView. Tests use mock implementations extensively (see `Tests/WebViewAMCTests/Mocks/`).
- **Fetch strategies as value types** — `FetchAction` combines URL, JavaScript, strategy (`.once`/`.poll`/`.continuous`), cookies, and wait conditions into a single declarative value.
- **WebViewMessageDecoder** auto-detects JS message types (string, bool, JSON, base64 data URI, dictionary) without explicit type annotations from JavaScript.
- **WKWebView extensions** (`injectJavaScriptAsync`, `loadURL`) live in `Extensions/` and handle script injection with bundled DOM helpers (`Scripts.swift`).

## Source Layout

```
WebViewAMC/Sources/WebViewAMC/
├── WebViewManager.swift          # Central coordinator (owns all subsystems)
├── WebViewDataFetcher.swift      # Fetch orchestration with strategies
├── WebViewTaskManager.swift      # Task lifecycle tracking
├── Configuration/                # WebViewConfiguration
├── Cookies/                      # CookieManager
├── Context/                      # WebViewContextGroup (multi-instance)
├── Errors/                       # WebViewError enum
├── Extensions/                   # WKWebView+Async, WKWebView+Load
├── Fetch/                        # FetchAction, FetchResult, FetchStrategy, WaitCondition
├── Logging/                      # WebViewLogger, WebViewLoggerProtocol
├── Messages/                     # WebViewMessage, WebViewMessageDecoder, WebViewMessageValue
├── Protocols/                    # WebViewManaging, JavaScriptEvaluating
├── Scripts/                      # JS helper injection (byID, bySelector, postMessage, etc.)
└── Tools/                        # SwiftUI views (WebView, WebViewReader, WebViewProxy, HeadlessWebView),
                                  #   WebViewCoordinator, WebViewMessageHandler, WebViewMessageRouter
```

## API History

Tag `v2.0.0` (commit `977f865`) marks the breaking transition from the old API to the modern one:
- `DataFetchRequest` → `FetchAction` with explicit `FetchStrategy` enum and `WaitCondition`
- Completion-handler `injectJavaScript` → `injectJavaScriptAsync` (async/await)
- Combine `PassthroughSubject` → `AsyncStream` for `tasksRunning`
- WKWebView cookie extensions → `CookieManager` as single source of truth
- All new features after this tag (typed evaluation, WebViewProxy/Reader, ContextGroup, HeadlessWebView) use the modern API exclusively.

## Git Conventions

- **Never** add `Co-Authored-By` or any co-author line to commits.
- Make **multiple atomic commits** — each commit should contain a single logical change.
- Follow **Conventional Commits** format: `type(scope): description` (e.g., `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).

## Test Conventions

- Uses **Swift Testing** framework (`import Testing`, `@Suite`, `@Test` macros) — not XCTest.
- Mock implementations in `Tests/WebViewAMCTests/Mocks/` (MockWebViewManager, MockJavaScriptEvaluator, MockCoordinatorDelegate, etc.).
- Tests are pure unit tests with no network or simulator UI dependencies — mocks replace WKWebView entirely.
- Test file naming: `<TypeName>Tests.swift` matching the source file being tested.
