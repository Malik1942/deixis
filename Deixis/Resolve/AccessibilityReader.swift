import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Owns every `AXUIElement`. Nothing accessibility-typed leaves this actor; callers receive
/// Sendable snapshots and the pure `ElementResolver` does the rest. Keeps AppKit off the main thread's
/// back: the overlay stays responsive while a lazy tree is being read.
actor AccessibilityReader {
    static let frameAttribute = "AXFrame"

    /// Accessibility trust for this process. `prompt` shows the system dialog once.
    nonisolated static func isTrusted(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Apps whose accessibility tree has been switched on this session (Electron and Chromium build
    /// it only when an assistive client asks).
    private var accessibilityEnabledPIDs: Set<pid_t> = []

    /// Chromium-based browsers respond to `AXEnhancedUserInterface`, the signal VoiceOver sends.
    /// Electron apps expose `AXManualAccessibility` for the same purpose and are detected by it.
    private static let chromiumBundleIDs: Set<String> = [
        "com.google.Chrome", "com.google.Chrome.canary", "com.google.Chrome.beta", "org.chromium.Chromium",
        "com.microsoft.edgemac", "com.brave.Browser", "company.thebrowser.Browser", "com.vivaldi.Vivaldi",
    ]

    /// R3: Electron and Chromium apps expose only window-sized groups until accessibility is enabled
    /// from outside. Done once per app per session; the tree fills in within about half a second.
    private func enableAccessibilityIfNeeded(app: AXUIElement, pid: pid_t) {
        guard !accessibilityEnabledPIDs.contains(pid) else { return }
        accessibilityEnabledPIDs.insert(pid)
        var names: CFArray?
        AXUIElementCopyAttributeNames(app, &names)
        let attributeNames = (names as? [String]) ?? []
        if attributeNames.contains("AXManualAccessibility") {
            AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        }
        if let bundleID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
           Self.chromiumBundleIDs.contains(bundleID) {
            AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        }
    }

    /// R3: per-app hit test, system-wide element as fallback. Nil when neither returns anything.
    func snapshot(at point: CGPoint, pid: pid_t) -> ElementSnapshot? {
        let app = AXUIElementCreateApplication(pid)
        enableAccessibilityIfNeeded(app: app, pid: pid)
        if let element = hit(app, at: point) {
            return snapshot(of: refine(element, at: point))
        }
        if let element = hit(AXUIElementCreateSystemWide(), at: point) {
            return snapshot(of: refine(element, at: point))
        }
        return nil
    }

    /// R2 hover precision: a container hit is replaced by the best control among its descendants
    /// near the point (see `HitRefiner`). Descends only through nodes whose frame is near the point,
    /// so the walk stays small even on a large tree.
    private func refine(_ base: AXUIElement, at point: CGPoint) -> AXUIElement {
        let baseAttributes = attributes(of: base)
        guard ElementResolver.isContainer(baseAttributes) else { return base }
        let tolerance = HitRefiner.tolerance
        var candidates: [(element: AXUIElement, attributes: AttributeSet)] = []
        var stack: [(element: AXUIElement, depth: Int)] = children(of: base).map { ($0, 1) }
        var visited = 0
        while let (node, depth) = stack.popLast(), visited < 400 {
            visited += 1
            guard let frame = frame(copy(node, Self.frameAttribute)),
                  frame.cgRect.insetBy(dx: -tolerance, dy: -tolerance).contains(point) else { continue }
            let nodeAttributes = attributes(of: node)
            candidates.append((node, nodeAttributes))
            if depth < 12, ElementResolver.isContainer(nodeAttributes) {
                stack.append(contentsOf: children(of: node).map { ($0, depth + 1) })
            }
        }
        guard let chosen = HitRefiner.choose(from: candidates.map(\.attributes), replacing: baseAttributes, at: point),
              let match = candidates.first(where: { $0.attributes == chosen }) else { return base }
        return match.element
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        guard let value = copy(element, kAXChildrenAttribute), let array = value as? [AnyObject] else { return [] }
        return array.compactMap { CFGetTypeID($0) == AXUIElementGetTypeID() ? ($0 as! AXUIElement) : nil }
    }

    /// Title of the app's focused window, falling back to its main window.
    func focusedWindowTitle(pid: pid_t) -> String? {
        let app = AXUIElementCreateApplication(pid)
        guard let window = element(copy(app, kAXFocusedWindowAttribute)) ?? element(copy(app, kAXMainWindowAttribute)) else {
            return nil
        }
        return string(copy(window, kAXTitleAttribute))
    }

    // MARK: Reading

    private func hit(_ root: AXUIElement, at point: CGPoint) -> AXUIElement? {
        var out: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(root, Float(point.x), Float(point.y), &out)
        return error == .success ? out : nil
    }

    private func snapshot(of element: AXUIElement) -> ElementSnapshot {
        var ancestors: [AttributeSet] = []
        var current = element
        for _ in 0..<ElementResolver.maxAncestors {
            guard let parent = self.element(copy(current, kAXParentAttribute)) else { break }
            ancestors.append(attributes(of: parent))
            current = parent
        }
        return ElementSnapshot(element: attributes(of: element), ancestors: ancestors)
    }

    private func attributes(of element: AXUIElement) -> AttributeSet {
        var childCount: CFIndex = 0
        AXUIElementGetAttributeValueCount(element, kAXChildrenAttribute as CFString, &childCount)
        return AttributeSet(
            role: string(copy(element, kAXRoleAttribute)),
            subrole: string(copy(element, kAXSubroleAttribute)),
            title: string(copy(element, kAXTitleAttribute)),
            description: string(copy(element, kAXDescriptionAttribute)),
            value: value(copy(element, kAXValueAttribute)),
            identifier: string(copy(element, kAXIdentifierAttribute)),
            frame: frame(copy(element, Self.frameAttribute)),
            childCount: Int(childCount)
        )
    }

    private func copy(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return error == .success ? value : nil
    }

    private func element(_ value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private func string(_ value: CFTypeRef?) -> String? {
        guard let value, CFGetTypeID(value) == CFStringGetTypeID() else { return nil }
        return (value as! CFString) as String
    }

    private func frame(_ value: CFTypeRef?) -> Frame? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let axValue = value as! AXValue
        var rect = CGRect.zero
        guard AXValueGetType(axValue) == .cgRect, AXValueGetValue(axValue, .cgRect, &rect) else { return nil }
        return Frame(rect)
    }

    private func value(_ value: CFTypeRef?) -> ElementValue? {
        guard let value else { return nil }
        let typeID = CFGetTypeID(value)
        if typeID == CFStringGetTypeID() { return .string((value as! CFString) as String) }
        if typeID == CFBooleanGetTypeID() { return .bool(CFBooleanGetValue((value as! CFBoolean))) }
        if typeID == CFNumberGetTypeID() {
            var number = 0.0
            return CFNumberGetValue((value as! CFNumber), .doubleType, &number) ? .number(number) : nil
        }
        return nil
    }
}

/// The reader bound to one process, as the resolver's provider.
struct AppElementProvider: ElementProvider {
    let reader: AccessibilityReader
    let pid: pid_t

    func snapshot(at point: CGPoint) async -> ElementSnapshot? {
        await reader.snapshot(at: point, pid: pid)
    }
}
