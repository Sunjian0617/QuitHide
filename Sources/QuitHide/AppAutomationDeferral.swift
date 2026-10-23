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

struct AppAutomationDeferralReset: Equatable, Sendable {
    let bundleIdentifier: String
    let timerRestartAt: TimeInterval
}

struct AppAutomationDeferralRegistry {
    private var deadlinesByBundleIdentifier: [String: TimeInterval] = [:]

    mutating func deferAutomation(
        for bundleIdentifier: String,
        duration: AppAutomationDeferralDuration,
        at now: TimeInterval
    ) {
        deadlinesByBundleIdentifier[bundleIdentifier] = now + duration.seconds
    }

    mutating func endDeferral(
        for bundleIdentifier: String,
        at now: TimeInterval
    ) -> AppAutomationDeferralReset? {
        guard deadlinesByBundleIdentifier.removeValue(
            forKey: bundleIdentifier
        ) != nil else {
            return nil
        }
        return AppAutomationDeferralReset(
            bundleIdentifier: bundleIdentifier,
            timerRestartAt: now
        )
    }

    func isDeferred(for bundleIdentifier: String, at now: TimeInterval) -> Bool {
        guard let deadline = deadlinesByBundleIdentifier[bundleIdentifier] else {
            return false
        }
        return now < deadline
    }

    func remainingTime(
        for bundleIdentifier: String,
        at now: TimeInterval
    ) -> TimeInterval? {
        guard let deadline = deadlinesByBundleIdentifier[bundleIdentifier],
              now < deadline else {
            return nil
        }
        return deadline - now
    }

    mutating func expire(at now: TimeInterval) -> [AppAutomationDeferralReset] {
        let expiredBundleIdentifiers = deadlinesByBundleIdentifier
            .filter { now >= $0.value }
            .map(\.key)
            .sorted()

        for bundleIdentifier in expiredBundleIdentifiers {
            deadlinesByBundleIdentifier.removeValue(forKey: bundleIdentifier)
        }

        return expiredBundleIdentifiers.map {
            AppAutomationDeferralReset(
                bundleIdentifier: $0,
                timerRestartAt: now
            )
        }
    }

    @discardableResult
    mutating func removeStoppedApps(
        runningBundleIdentifiers: Set<String>
    ) -> Bool {
        let retainedDeadlines = deadlinesByBundleIdentifier.filter {
            runningBundleIdentifiers.contains($0.key)
        }
        guard retainedDeadlines.count != deadlinesByBundleIdentifier.count else {
            return false
        }
        deadlinesByBundleIdentifier = retainedDeadlines
        return true
    }

    mutating func shiftDeadlines(by interval: TimeInterval) {
        let shift = max(interval, 0)
        guard shift > 0 else { return }
        deadlinesByBundleIdentifier = deadlinesByBundleIdentifier.mapValues {
            $0 + shift
        }
    }
}
