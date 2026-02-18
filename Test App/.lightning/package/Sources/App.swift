// Lightning - Swift-native Electron alternative for macOS
// Copyright (c) 2026. MIT License.
// AUTO-GENERATED — do not edit. Regenerated on every `lightning dev` / `lightning build`.

import Lightning
import AppKit
import WebKit

struct GeneratedApp: LightningApp {
    var windowConfiguration: WindowConfiguration {
        WindowConfiguration(
            title: "Notes",
            width: CGFloat(1100),
            height: CGFloat(740),
            isResizable: true,
            minSize: NSSize(width: CGFloat(700), height: CGFloat(500))
        )
    }

    var plugins: [any LightningPlugin] {
        [
            AutoUpdateService(),
            ClipboardService(),
            CrashReporterService(),
            DeepLinkService(),
            DiagnosticsService(),
            DialogService(),
            ExtensionLoaderService(),
            FileSystemService(),
            GlobalShortcutService(),
            HotReloadService(),
            KeychainService(),
            MenuService(),
            NetworkService(),
            NotificationService(),
            PowerMonitorService(),
            ScreenCaptureService(),
            ShellService(),
            SingleInstanceService(),
            SystemInfoService(),
            TerminalService(),
            TrayService()
        ]
    }

    @MainActor
    func appDidFinishLaunching(window: LightningWindow) async throws {
            let entryURL = URL(string: "http://localhost:3274/index.html")!
            window.webView.loadURL(entryURL)
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            let toolbar = NSToolbar(identifier: "mainToolbar")
            toolbar.showsBaselineSeparator = false
            toolbar.displayMode = .iconOnly
            window.toolbar = toolbar
            window.toolbarStyle = .unifiedCompact
        }

        window.show()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = LightningApplication()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            do {
                try await engine.boot(app: GeneratedApp())
                NSApp.activate(ignoringOtherApps: true)
            } catch {
                NSLog("Lightning boot failed: \(error)")
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            engine.mainWindow?.window.makeKeyAndOrderFront(nil)
        }
        return true
    }

    @objc func newWindow(_ sender: Any?) {
        engine.mainWindow?.window.makeKeyAndOrderFront(nil)
    }
}

@main
enum App {
    static func main() {
        NSApplication.shared.setActivationPolicy(.regular)
        // Standard macOS menu bar for keyboard shortcut support
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Notes", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Notes", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Notes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "New Window", action: Selector(("newWindow:")), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Print...", action: #selector(NSView.printView(_:)), keyEquivalent: "p"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu (enables Cmd+C, Cmd+V, Cmd+X, Cmd+A, Cmd+Z)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f"))
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }
}