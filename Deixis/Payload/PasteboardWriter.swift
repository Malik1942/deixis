import AppKit

/// R8: one pasteboard item carrying both the PNG and the Markdown. Called only after the files are
/// on disk, so a failed capture never touches the clipboard.
@MainActor
enum PasteboardWriter {
    static func write(markdown: String, png: Data) {
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        item.setString(markdown, forType: .string)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
    }
}
