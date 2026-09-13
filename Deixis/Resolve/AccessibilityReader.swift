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

    /// R3: per-app hit test, system-wide element as fallback. Nil when neither returns anything.
    func snapshot(at point: CGPoint, pid: pid_t) -> ElementSnapshot? {
        if let element = hit(AXUIElementCreateApplication(pid), at: point) {
            return snapshot(of: element)
        }
        if let element = hit(AXUIElementCreateSystemWide(), at: point) {
            return snapshot(of: element)
        }
        return nil
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
