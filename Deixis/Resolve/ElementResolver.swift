import CoreGraphics
import Foundation

/// Raw attributes of one accessibility node, as read from the platform or recorded in a fixture.
/// Keys are the platform attribute names so fixtures read like real accessibility dumps.
struct AttributeSet: Codable, Sendable, Equatable {
    var role: String?
    var subrole: String?
    var title: String?
    var description: String?
    var value: ElementValue?
    var identifier: String?
    var frame: Frame?
    var childCount: Int?

    enum CodingKeys: String, CodingKey {
        case role = "AXRole"
        case subrole = "AXSubrole"
        case title = "AXTitle"
        case description = "AXDescription"
        case value = "AXValue"
        case identifier = "AXIdentifier"
        case frame = "AXFrame"
        case childCount = "AXChildrenCount"
    }
}

/// The hit element plus its ancestor chain, nearest first, as walked through the parent attribute.
struct ElementSnapshot: Codable, Sendable, Equatable {
    var element: AttributeSet
    var ancestors: [AttributeSet]
}

/// Something that can hit-test a screen point and return a snapshot. The app's provider is the
/// accessibility actor; tests use scripted stand-ins.
protocol ElementProvider: Sendable {
    func snapshot(at point: CGPoint) async -> ElementSnapshot?
}

/// Pure transform from a snapshot to the platform-neutral element (R3, section 4).
enum ElementResolver {
    static let maxAncestors = 6

    static func resolve(_ snapshot: ElementSnapshot) -> ResolvedElement? {
        // Missing frame means the element cannot be cropped or pointed at. Never fabricate a zero frame.
        guard let frame = snapshot.element.frame else { return nil }
        let rawRole = snapshot.element.role ?? ""
        let role = mapRole(rawRole, subrole: snapshot.element.subrole)
        let identifier = nonEmpty(snapshot.element.identifier)
        let label = nonEmpty(snapshot.element.title) ?? nonEmpty(snapshot.element.description)

        var path: [PathEntry] = snapshot.ancestors.prefix(maxAncestors).reversed().map { node in
            PathEntry(role: mapRole(node.role ?? "", subrole: node.subrole), identifier: nonEmpty(node.identifier))
        }
        path.append(PathEntry(role: role, identifier: identifier))

        return ResolvedElement(
            role: role,
            rawRole: rawRole,
            label: label,
            identifier: identifier,
            identifierSource: identifierSource(role: role, identifier: identifier),
            value: snapshot.element.value,
            frame: frame,
            path: path
        )
    }

    /// Section 4: `possiblySymbolName` when role is image and the identifier looks like an SF Symbol name.
    static func identifierSource(role: String, identifier: String?) -> IdentifierSource {
        guard let identifier, !identifier.isEmpty else { return .unknown }
        if role == "image", looksLikeSymbolName(identifier) { return .possiblySymbolName }
        return .declared
    }

    /// `^[a-z0-9]+(\.[a-z0-9]+)*$` without a regex, so it stays trivially Sendable.
    static func looksLikeSymbolName(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        for segment in s.split(separator: ".", omittingEmptySubsequences: false) {
            if segment.isEmpty { return false }
            for scalar in segment.unicodeScalars {
                let ok = (scalar >= "a" && scalar <= "z") || (scalar >= "0" && scalar <= "9")
                if !ok { return false }
            }
        }
        return true
    }

    /// A group with no children is the lazy-tree symptom observed in the Simulator on first read.
    static func isEmptyGroup(_ snapshot: ElementSnapshot) -> Bool {
        mapRole(snapshot.element.role ?? "", subrole: snapshot.element.subrole) == "group"
            && (snapshot.element.childCount ?? 0) == 0
    }

    private static let roleMap: [String: String] = [
        "AXApplication": "application",
        "AXWindow": "window",
        "AXSheet": "sheet",
        "AXDrawer": "drawer",
        "AXGroup": "group",
        "AXSplitGroup": "splitGroup",
        "AXTabGroup": "tabGroup",
        "AXToolbar": "toolbar",
        "AXNavigationBar": "navigationBar",
        "AXButton": "button",
        "AXPopUpButton": "popUpButton",
        "AXMenuButton": "menuButton",
        "AXCheckBox": "checkBox",
        "AXRadioButton": "radioButton",
        "AXRadioGroup": "radioGroup",
        "AXDisclosureTriangle": "disclosureTriangle",
        "AXSlider": "slider",
        "AXIncrementor": "stepper",
        "AXProgressIndicator": "progressIndicator",
        "AXTextField": "textField",
        "AXTextArea": "textArea",
        "AXComboBox": "comboBox",
        "AXStaticText": "staticText",
        "AXHeading": "heading",
        "AXLink": "link",
        "AXImage": "image",
        "AXList": "list",
        "AXTable": "table",
        "AXOutline": "outline",
        "AXRow": "row",
        "AXColumn": "column",
        "AXCell": "cell",
        "AXScrollArea": "scrollArea",
        "AXScrollBar": "scrollBar",
        "AXMenuBar": "menuBar",
        "AXMenuBarItem": "menuBarItem",
        "AXMenu": "menu",
        "AXMenuItem": "menuItem",
        "AXWebArea": "webArea",
        "AXValueIndicator": "valueIndicator",
        "AXLayoutArea": "layoutArea",
        "AXUnknown": "unknown",
    ]

    private static let subroleMap: [String: String] = [
        "AXSwitch": "switch",
        "AXToggle": "toggle",
        "AXSearchField": "searchField",
        "AXSecureTextField": "secureTextField",
        "AXTabButton": "tab",
        "AXCloseButton": "closeButton",
    ]

    /// Maps a platform role (and subrole, when it is more specific) to the platform-neutral vocabulary.
    static func mapRole(_ axRole: String, subrole: String?) -> String {
        if let subrole, let mapped = subroleMap[subrole] { return mapped }
        return roleMap[axRole] ?? "unknown"
    }

    private static func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.isEmpty else { return nil }
        return s
    }
}

extension ElementResolver {
    /// R3 lazy-tree retry: a nil hit or an empty group is re-read every `delay`, up to `retries` more
    /// times. Returns nil when no populated element was ever seen; the caller records `element: null`.
    static func resolve(
        at point: CGPoint,
        using provider: some ElementProvider,
        retries: Int = 5,
        delay: Duration = .milliseconds(100)
    ) async -> ResolvedElement? {
        for attempt in 0...max(retries, 0) {
            if let snapshot = await provider.snapshot(at: point), !isEmptyGroup(snapshot),
               let resolved = resolve(snapshot) {
                return resolved
            }
            if (attempt < retries) && (delay > .zero) {
                try? await Task.sleep(for: delay)
            }
        }
        return nil
    }
}
