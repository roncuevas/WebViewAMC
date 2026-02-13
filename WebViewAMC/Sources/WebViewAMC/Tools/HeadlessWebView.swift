import SwiftUI
import WebKit

/// A SwiftUI view that keeps a WKWebView in the view hierarchy
/// without being visible to the user.
///
/// On iOS, a WKWebView not attached to a view hierarchy may suspend
/// JavaScript execution and network requests. This component works
/// around that limitation by rendering the web view at minimal size
/// with near-zero opacity.
///
/// Usage:
/// ```swift
/// var body: some View {
///     MyContent()
///         .background { HeadlessWebView() }
/// }
/// ```
public struct HeadlessWebView: View {
    private let webView: WKWebView

    /// Creates a headless web view backed by the given manager.
    /// - Parameter manager: The `WebViewManager` whose WKWebView should
    ///   be kept alive in the view hierarchy. Defaults to `.shared`.
    public init(manager: WebViewManager = .shared) {
        self.webView = manager.webView
    }

    public var body: some View {
        WebView(webView: webView)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
