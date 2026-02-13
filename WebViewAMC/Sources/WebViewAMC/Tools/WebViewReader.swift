import SwiftUI

public struct WebViewReader<Content: View>: View {
    @StateObject private var proxy: WebViewProxy

    private let content: (WebViewProxy) -> Content

    public init(
        manager: WebViewManager = .shared,
        @ViewBuilder content: @escaping (WebViewProxy) -> Content
    ) {
        self._proxy = StateObject(wrappedValue: WebViewProxy(manager: manager))
        self.content = content
    }

    public var body: some View {
        content(proxy)
    }
}
