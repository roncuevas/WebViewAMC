import Foundation
@testable import WebViewAMC

@MainActor
final class MockWebViewCoordinatorDelegate: WebViewCoordinatorDelegate {
    var navigatedURLs = [URL]()
    var receivedCookies = [[HTTPCookie]]()
    var failedErrors = [Error]()
    var timeoutCount = 0

    func didNavigateTo(url: URL) {
        navigatedURLs.append(url)
    }

    func cookiesReceiver(cookies: [HTTPCookie]) {
        receivedCookies.append(cookies)
    }

    func didFailLoading(error: Error) {
        failedErrors.append(error)
    }

    func didTimeout() {
        timeoutCount += 1
    }
}
