import XCTest
@testable import Locant

final class AgentConfigTests: XCTestCase {
    private let exe = "/Applications/Locant.app/Contents/MacOS/Locant"

    private func object(_ text: String) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
    }

    // 1
    func testJSONAddKeepsOtherServersAndReplacesAnOldLocant() throws {
        let existing = """
        {"mcpServers": {"agentation": {"command": "npx", "args": ["-y", "agentation-mcp", "server"]}, "locant": {"command": "/old/Locant", "args": ["--mcp"]}}, "numStartups": 12, "projects": {"/Users/me/x": {"allowedTools": []}}}
        """
        let updated = try object(try AgentConfig.jsonAdding(existing, executable: exe))
        let servers = try XCTUnwrap(updated["mcpServers"] as? [String: Any])
        XCTAssertEqual(servers.keys.sorted(), ["agentation", "locant"])
        XCTAssertEqual((servers["locant"] as? [String: Any])?["command"] as? String, exe)
        XCTAssertEqual((servers["locant"] as? [String: Any])?["args"] as? [String], ["--mcp"])
        XCTAssertEqual((servers["agentation"] as? [String: Any])?["args"] as? [String], ["-y", "agentation-mcp", "server"])
        XCTAssertEqual(updated["numStartups"] as? Int, 12)
        XCTAssertNotNil((updated["projects"] as? [String: Any])?["/Users/me/x"])

        let fresh = try object(try AgentConfig.jsonAdding(nil, executable: exe))
        XCTAssertEqual(((fresh["mcpServers"] as? [String: Any])?["locant"] as? [String: Any])?["command"] as? String, exe)
        XCTAssertEqual(try AgentConfig.jsonAdding("", executable: exe), try AgentConfig.jsonAdding(nil, executable: exe))
        XCTAssertTrue(try AgentConfig.jsonAdding(nil, executable: exe).hasSuffix("\n"))
        XCTAssertThrowsError(try AgentConfig.jsonAdding("{oops", executable: exe))
        XCTAssertThrowsError(try AgentConfig.jsonAdding("[1, 2]", executable: exe))
    }

    // 2
    func testJSONRemoveLeavesTheRest() throws {
        let existing = try AgentConfig.jsonAdding(#"{"mcpServers": {"agentation": {"command": "npx"}}, "theme": "dark"}"#, executable: exe)
        let removed = try object(try XCTUnwrap(try AgentConfig.jsonRemoving(existing)))
        XCTAssertEqual((removed["mcpServers"] as? [String: Any])?.keys.sorted(), ["agentation"])
        XCTAssertEqual(removed["theme"] as? String, "dark")
        XCTAssertNil(try AgentConfig.jsonRemoving(nil))
        XCTAssertNil(try AgentConfig.jsonRemoving(#"{"mcpServers": {}}"#))
        XCTAssertNil(try AgentConfig.jsonRemoving(#"{"theme": "dark"}"#))
    }

    // 3
    func testTOMLAddAppendsOneTable() throws {
        let existing = """
        model = "gpt-5"

        [mcp_servers.agentation]
        command = "npx"
        args = [ "-y", "agentation-mcp", "server" ]
        """
        let added = AgentConfig.tomlAdding(existing, executable: exe)
        XCTAssertEqual(added, existing + "\n\n[mcp_servers.locant]\ncommand = \"\(exe)\"\nargs = [\"--mcp\"]\n")
        XCTAssertEqual(AgentConfig.tomlAdding(nil, executable: exe), "[mcp_servers.locant]\ncommand = \"\(exe)\"\nargs = [\"--mcp\"]\n")
        // Adding twice replaces, never duplicates.
        let twice = AgentConfig.tomlAdding(added, executable: "/elsewhere/Locant")
        XCTAssertEqual(twice.components(separatedBy: "[mcp_servers.locant]").count, 2)
        XCTAssertEqual(AgentConfig.tomlExecutable(twice), "/elsewhere/Locant")
        XCTAssertEqual(AgentConfig.tomlExecutable(AgentConfig.tomlAdding(nil, executable: "/a \"quoted\"/Locant")), "/a \"quoted\"/Locant")
    }

    // 4
    func testTOMLRemoveTakesTheTableAndItsSubTables() throws {
        let existing = """
        model = "gpt-5"

        [mcp_servers.locant]
        command = "/old/Locant"
        args = ["--mcp"]

          [mcp_servers.locant.env]
          FOO = "bar"

        [mcp_servers.agentation]
        command = "npx"
        """
        XCTAssertEqual(AgentConfig.tomlRemoving(existing), "model = \"gpt-5\"\n\n[mcp_servers.agentation]\ncommand = \"npx\"")
        XCTAssertNil(AgentConfig.tomlRemoving(nil))
        XCTAssertNil(AgentConfig.tomlRemoving("model = \"gpt-5\"\n"))
        // A table at the end of the file.
        let tail = "a = 1\n\n[mcp_servers.locant]\ncommand = \"/x\"\n"
        XCTAssertEqual(AgentConfig.tomlRemoving(tail), "a = 1\n")
    }

    // 5
    func testDetectionReturnsTheConfiguredExecutable() throws {
        XCTAssertNil(AgentConfig.jsonExecutable(nil))
        XCTAssertNil(AgentConfig.jsonExecutable(#"{"mcpServers": {"other": {"command": "x"}}}"#))
        XCTAssertEqual(AgentConfig.jsonExecutable(try AgentConfig.jsonAdding(nil, executable: exe)), exe)
        XCTAssertNil(AgentConfig.tomlExecutable(nil))
        XCTAssertNil(AgentConfig.tomlExecutable("[mcp_servers.other]\ncommand = \"x\"\n"))
        XCTAssertEqual(AgentConfig.tomlExecutable("[mcp_servers.locant]\ncommand = \"/x/Locant\" # comment\nargs = []\n"), "/x/Locant")
        XCTAssertEqual(AgentConfig.tomlExecutable("[mcp_servers.locant]\nargs = []\n"), "")

        let snippet = try object(AgentConfig.jsonSnippet(executable: exe))
        XCTAssertEqual(((snippet["mcpServers"] as? [String: Any])?["locant"] as? [String: Any])?["args"] as? [String], ["--mcp"])
        XCTAssertEqual(Agent.allCases.map(\.title), ["Claude Code", "Cursor", "Codex"])
        XCTAssertEqual(Agent.claudeCode.configURL.lastPathComponent, ".claude.json")
        XCTAssertEqual(Agent.cursor.configURL.path(percentEncoded: false).hasSuffix("/.cursor/mcp.json"), true)
        XCTAssertEqual(Agent.codex.configURL.path(percentEncoded: false).hasSuffix("/.codex/config.toml"), true)
    }
}
