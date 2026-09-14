import XCTest
@testable import Deixis

final class ModeInferenceTests: XCTestCase {
    /// A fake disk: the entries of each directory, and DerivedData workspace paths.
    private func environment(entries: [String: [String]] = [:], workspaces: [String: String] = [:]) -> ModeEnvironment {
        ModeEnvironment(
            directoryEntries: { entries[$0] ?? [] },
            derivedDataWorkspacePath: { workspaces[$0] }
        )
    }

    // 1
    func testMyAppsWins() {
        let s = ModeSignals(bundleId: "com.figma.Desktop", bundlePath: "/Applications/Figma.app", myApps: ["com.figma.Desktop"])
        let d = ModeInference.infer(s, environment: environment())
        XCTAssertEqual(d, ModeDecision(mode: .fix, projectRoot: nil, rule: .myApps))
        let sim = ModeSignals(bundleId: ModeInference.simulatorBundleId, isSimulator: true, simulatedBundleId: "com.x.y", myApps: ["com.x.y"])
        XCTAssertEqual(ModeInference.infer(sim, environment: environment()).rule, .myApps)
    }

    // 2
    func testSimulatorIsFix() {
        let s = ModeSignals(bundleId: ModeInference.simulatorBundleId, isSimulator: true, simulatedBundleId: "com.someone.else")
        XCTAssertEqual(ModeInference.infer(s, environment: environment()), ModeDecision(mode: .fix, projectRoot: nil, rule: .simulator))
    }

    // 3
    func testLocalhostHosts() {
        for host in ["localhost", "127.0.0.1", "0.0.0.0", "::1", "myapp.local", "LOCALHOST"] {
            XCTAssertTrue(ModeInference.isLocalhost(host), host)
        }
        XCTAssertFalse(ModeInference.isLocalhost("example.com"))
        XCTAssertFalse(ModeInference.isLocalhost(nil))
        let s = ModeSignals(bundleId: "com.apple.Safari", bundlePath: "/Applications/Safari.app", urlHost: "localhost")
        XCTAssertEqual(ModeInference.infer(s, environment: environment()).rule, .localhost)
    }

    // 4
    func testDerivedDataBuildIsFixWithProjectRoot() {
        let path = "/Users/me/Library/Developer/Xcode/DerivedData/Deixis-abc123/Build/Products/Debug/Deixis.app"
        let env = environment(workspaces: ["/Users/me/Library/Developer/Xcode/DerivedData/Deixis-abc123": "/Users/me/Code/Deixis/Deixis.xcodeproj"])
        let d = ModeInference.infer(ModeSignals(bundleId: "com.malikzhang.deixis", bundlePath: path), environment: env)
        XCTAssertEqual(d, ModeDecision(mode: .fix, projectRoot: "/Users/me/Code/Deixis", rule: .builtHere))
        // Without a readable info.plist, DerivedData still means fix, but no root is guessed.
        let blind = ModeInference.infer(ModeSignals(bundleId: "com.malikzhang.deixis", bundlePath: path), environment: environment())
        XCTAssertEqual(blind.mode, .reference, "DerivedData without WorkspacePath and no ancestor marker: nothing proves it was built here")
    }

    // 5
    func testAncestorWithProjectMarkerGivesFixAndRoot() {
        let path = "/Users/me/Code/Oryne/build/Debug-iphonesimulator/Oryne.app"
        let env = environment(entries: [
            "/Users/me/Code/Oryne/build/Debug-iphonesimulator": ["Oryne.app"],
            "/Users/me/Code/Oryne/build": ["Debug-iphonesimulator"],
            "/Users/me/Code/Oryne": ["Oryne.xcodeproj", "Oryne", "README.md"],
        ])
        let d = ModeInference.infer(ModeSignals(bundleId: "com.inspireocean.app", bundlePath: path), environment: env)
        XCTAssertEqual(d, ModeDecision(mode: .fix, projectRoot: "/Users/me/Code/Oryne", rule: .builtHere))
        let swiftPackage = environment(entries: ["/Users/me/Code/Tool": ["Package.swift", "Sources"]])
        XCTAssertEqual(ModeInference.projectRoot(forBundleAt: "/Users/me/Code/Tool/.build/debug/tool", environment: swiftPackage), "/Users/me/Code/Tool")
    }

    // 6
    func testMatchingTeamIDIsFix() {
        let s = ModeSignals(bundleId: "com.malikzhang.deixis", bundlePath: "/Applications/Deixis.app", teamID: "MVAUZXPK9M", userTeamIDs: ["MVAUZXPK9M"])
        XCTAssertEqual(ModeInference.infer(s, environment: environment()), ModeDecision(mode: .fix, projectRoot: nil, rule: .signedByUser))
        let other = ModeSignals(bundleId: "com.figma.Desktop", bundlePath: "/Applications/Figma.app", teamID: "T8RHJ3WLGX", userTeamIDs: ["MVAUZXPK9M"])
        XCTAssertEqual(ModeInference.infer(other, environment: environment()).mode, .reference)
    }

    // 7
    func testNothingMatchesIsReferenceWithoutRoot() {
        let s = ModeSignals(bundleId: "com.anthropic.claudefordesktop", bundlePath: "/Applications/Claude.app", teamID: "Q6L7ARMD6X")
        XCTAssertEqual(ModeInference.infer(s, environment: environment(entries: ["/Applications": ["Claude.app", "Figma.app"]])), ModeDecision(mode: .reference, projectRoot: nil, rule: .none))
    }
}
