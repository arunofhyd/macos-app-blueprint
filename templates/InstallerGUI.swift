// =============================================================================
//  InstallerGUI.swift — Drag-to-Applications Interactive Installer Window
//  Template extracted from ClipLocal & HTML2PPTX by Arun Thomas
//
//  This Swift code is embedded as a heredoc inside the install-*.command script.
//  It gets compiled at install time and shows a native macOS drag-to-Applications
//  window with the app icon, a gradient arrow, and an Instant Install button.
//
//  USAGE: Paste this inside the install script as:
//    cat << 'EOF' > "$BUILD_DIR/InstallerGUI.swift"
//    <this file contents>
//    EOF
//    swiftc "$BUILD_DIR/InstallerGUI.swift" -o "$BUILD_DIR/InstallerGUI"
//    "$BUILD_DIR/InstallerGUI" "$APP_TARGET"
// =============================================================================

import Cocoa
import AppKit

let sourcePath = CommandLine.arguments[1]
let appName = "__APP_NAME__"

func getHighResIcon(path: String) -> NSImage {
    let iconPath = (path as NSString).appendingPathComponent("Contents/Resources/AppLogo.png")
    if FileManager.default.fileExists(atPath: iconPath), let img = NSImage(contentsOfFile: iconPath) {
        img.size = NSSize(width: 128, height: 128)
        return img
    }
    let wsIcon = NSWorkspace.shared.icon(forFile: path)
    wsIcon.size = NSSize(width: 128, height: 128)
    return wsIcon
}

func performInstallation(src: URL) -> Bool {
    let fm = FileManager.default
    let dest = URL(fileURLWithPath: "/Applications/\(src.lastPathComponent)")
    do {
        if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
        try fm.copyItem(at: src, to: dest)

        let alert = NSAlert()
        alert.messageText = "Installation Complete!"
        alert.informativeText = "\(appName) has been installed to your Applications folder."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Launch Now")
        alert.addButton(withTitle: "Done")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(dest)
        }
        NSApp.terminate(nil)
        return true
    } catch {
        let alert = NSAlert()
        alert.messageText = "Installation Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.runModal()
        return false
    }
}

class DragIcon: NSImageView, NSDraggingSource {
    var fileURL: URL?
    func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { .copy }
    override func mouseDown(with event: NSEvent) {
        guard let url = fileURL, let originalImg = image else { return }
        let item = NSPasteboardItem()
        item.setString(url.absoluteString, forType: .fileURL)
        let drag = NSDraggingItem(pasteboardWriter: item)
        let dragImg = NSImage(size: bounds.size)
        dragImg.lockFocus()
        if let ctx = NSGraphicsContext.current { ctx.imageInterpolation = .high }
        originalImg.draw(in: bounds)
        dragImg.unlockFocus()
        drag.setDraggingFrame(bounds, contents: dragImg)
        beginDraggingSession(with: [drag], event: event, source: self)
    }
}

class DropZone: NSImageView {
    override init(frame f: NSRect) { super.init(frame: f); registerForDraggedTypes([.fileURL]) }
    required init?(coder: NSCoder) { super.init(coder: coder); registerForDraggedTypes([.fileURL]) }
    override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ s: NSDraggingInfo) -> Bool {
        guard let str = s.draggingPasteboard.propertyList(forType: .fileURL) as? String,
              let src = URL(string: str) else { return false }
        return performInstallation(src: src)
    }
}

class GradientArrowView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let w = bounds.width, h = bounds.height, midY = h / 2.0
        let stemH: CGFloat = 10, headH: CGFloat = 26, headW: CGFloat = 20
        let stemR = w - headW

        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: midY - stemH/2))
        path.line(to: NSPoint(x: stemR, y: midY - stemH/2))
        path.line(to: NSPoint(x: stemR, y: midY - headH/2))
        path.line(to: NSPoint(x: w, y: midY))
        path.line(to: NSPoint(x: stemR, y: midY + headH/2))
        path.line(to: NSPoint(x: stemR, y: midY + stemH/2))
        path.line(to: NSPoint(x: 0, y: midY + stemH/2))
        path.close()

        // Change these colors to match your brand
        let startColor = NSColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 0.20)
        let endColor   = NSColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 0.85)
        NSGradient(starting: startColor, ending: endColor)?.draw(in: path, angle: 0)
    }
}

class BrandInstallButton: NSButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true; isBordered = false; focusRingType = .none
        layer?.cornerRadius = 10
        // Change to match your brand color
        layer?.backgroundColor = NSColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 1.0).cgColor
        contentTintColor = .white
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

// ── Build and show the window ──

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let W: CGFloat = 620, H: CGFloat = 420
let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: W, height: H),
                   styleMask: [.titled, .closable], backing: .buffered, defer: false)
win.title = "Install \(appName)"
win.center()

let bg = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: W, height: H))
bg.material = .windowBackground; bg.state = .active
win.contentView = bg

let title = NSTextField(labelWithString: "Install \(appName)")
title.frame = NSRect(x: 0, y: H - 65, width: W, height: 30)
title.alignment = .center
title.font = NSFont.systemFont(ofSize: 22, weight: .bold)
bg.addSubview(title)

let sub = NSTextField(labelWithString: "Drag app to Applications or click Instant Install below")
sub.frame = NSRect(x: 0, y: H - 90, width: W, height: 20)
sub.alignment = .center; sub.font = NSFont.systemFont(ofSize: 13); sub.textColor = .secondaryLabelColor
bg.addSubview(sub)

let iconSize: CGFloat = 128, midY: CGFloat = 150

let appIcon = DragIcon(frame: NSRect(x: 90, y: midY, width: iconSize, height: iconSize))
appIcon.imageScaling = .scaleProportionallyUpOrDown
appIcon.image = getHighResIcon(path: sourcePath)
appIcon.fileURL = URL(fileURLWithPath: sourcePath)
bg.addSubview(appIcon)

let appLabel = NSTextField(labelWithString: appName)
appLabel.frame = NSRect(x: 90, y: midY - 24, width: iconSize, height: 18)
appLabel.alignment = .center; appLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
bg.addSubview(appLabel)

let arrowView = GradientArrowView(frame: NSRect(x: 240, y: midY + 50, width: 140, height: 30))
bg.addSubview(arrowView)

let appsIcon = DropZone(frame: NSRect(x: 400, y: midY, width: iconSize, height: iconSize))
appsIcon.imageScaling = .scaleProportionallyUpOrDown
appsIcon.image = NSWorkspace.shared.icon(forFile: "/Applications")
appsIcon.image?.size = NSSize(width: 128, height: 128)
bg.addSubview(appsIcon)

let appsLabel = NSTextField(labelWithString: "Applications")
appsLabel.frame = NSRect(x: 400, y: midY - 24, width: iconSize, height: 18)
appsLabel.alignment = .center; appsLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
bg.addSubview(appsLabel)

class InstallAction: NSObject {
    @objc func install() {
        _ = performInstallation(src: URL(fileURLWithPath: sourcePath))
    }
}
let action = InstallAction()

let installBtn = BrandInstallButton(frame: NSRect(x: (W - 220)/2, y: 40, width: 220, height: 42))
installBtn.title = "⚡  Instant Install"
installBtn.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
installBtn.target = action; installBtn.action = #selector(InstallAction.install)
bg.addSubview(installBtn)

win.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
app.run()
