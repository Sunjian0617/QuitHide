import Foundation

enum AppAutomationDeferralDuration: Int, CaseIterable {
    case minutes15 = 15
    case minutes30 = 30
    case minutes60 = 60

    var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }
}

enum AppAutomationDeferralEligibilityPolicy {
    static func canDefer(
        isRunning: Bool,
        actionIsAutomated: Bool,
        hasUncancelableQuit: Bool
    ) -> Bool {
        isRunning && actionIsAutomated && !hasUncancelableQuit
    }
}
