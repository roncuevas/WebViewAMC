import Foundation

public enum WaitCondition: Sendable {
    case element(
        _ selector: String,
        timeout: Duration = .seconds(10),
        pollInterval: Duration = .milliseconds(250)
    )
    case navigation(
        timeout: Duration = .seconds(15),
        pollInterval: Duration = .milliseconds(250)
    )
    case none
}
