import Foundation
import Testing
@testable import QuitHide

@Suite("App automation deferral")
struct AppAutomationDeferralTests {
    @Test("Deferral presets are 15, 30, and 60 minutes")
    func presetDurationsAre15_30And60Minutes() {
        #expect(AppAutomationDeferralDuration.allCases.map(\.seconds) == [900, 1_800, 3_600])
    }

    @Test("A stopped app cannot be deferred")
    func cannotDeferWhenTheAppIsNotRunning() {
        #expect(!AppAutomationDeferralEligibilityPolicy.canDefer(
            isRunning: false,
            actionIsAutomated: true,
            hasUncancelableQuit: false
        ))
    }

    @Test("An app with a non-automated rule cannot be deferred")
    func cannotDeferWhenTheRuleIsNotAutomated() {
        #expect(!AppAutomationDeferralEligibilityPolicy.canDefer(
            isRunning: true,
            actionIsAutomated: false,
            hasUncancelableQuit: false
        ))
    }

    @Test("An app with an outstanding quit request cannot be deferred")
    func cannotDeferWhenAQuitHasBeenRequested() {
        #expect(!AppAutomationDeferralEligibilityPolicy.canDefer(
            isRunning: true,
            actionIsAutomated: true,
            hasUncancelableQuit: true
        ))
        #expect(AppAutomationDeferralEligibilityPolicy.canDefer(
            isRunning: true,
            actionIsAutomated: true,
            hasUncancelableQuit: false
        ))
    }
}
