//
//  AutoArchiveApp.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/23/26.
//

import SwiftUI

@main
struct AutoArchiveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1051, height: 875)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var trafficLightWindow: NSWindow?
    private weak var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure all windows after SwiftUI has set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for window in NSApplication.shared.windows {
                self.configureWindow(window)
            }
        }
    }

    func configureWindow(_ window: NSWindow) {
        mainWindow = window

        // Key settings for traffic lights on window material
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        // Make window background transparent so our SwiftUI content shows through
        window.backgroundColor = .clear
        window.isOpaque = false

        // More rounded window corners (like Dia)
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true

        // Hide native traffic light buttons
        let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for buttonType in buttonTypes {
            window.standardWindowButton(buttonType)?.isHidden = true
        }

        // Create traffic lights in a child window (guaranteed to be on top)
        let buttonSize: CGFloat = 14
        let buttonSpacing: CGFloat = 6
        let containerWidth = (buttonSize * 3) + (buttonSpacing * 2)
        let containerHeight = buttonSize

        // Position: 18pt from left, 17pt from top of main window
        let leftOffset: CGFloat = 18
        let topOffset: CGFloat = 17

        let trafficFrame = NSRect(
            x: window.frame.origin.x + leftOffset,
            y: window.frame.origin.y + window.frame.height - topOffset - containerHeight,
            width: containerWidth,
            height: containerHeight
        )

        // Create a borderless child window for traffic lights
        let childWindow = NSWindow(
            contentRect: trafficFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        childWindow.isOpaque = false
        childWindow.backgroundColor = .clear
        childWindow.level = window.level
        childWindow.ignoresMouseEvents = false

        // Create container with traffic light buttons
        let container = TrafficLightContainer(frame: NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        container.wantsLayer = true
        container.mainWindow = window  // Pass reference for button actions

        // Create custom traffic light buttons with manual actions
        let closeButton = createTrafficLightButton(color: NSColor(red: 1.0, green: 0.38, blue: 0.34, alpha: 1.0), action: #selector(closeWindow))
        let minimizeButton = createTrafficLightButton(color: NSColor(red: 1.0, green: 0.78, blue: 0.23, alpha: 1.0), action: #selector(minimizeWindow))
        let zoomButton = createTrafficLightButton(color: NSColor(red: 0.15, green: 0.8, blue: 0.26, alpha: 1.0), action: #selector(zoomWindow))

        var xOffset: CGFloat = 0
        for button in [closeButton, minimizeButton, zoomButton] {
            button.frame = NSRect(x: xOffset, y: 0, width: buttonSize, height: buttonSize)
            button.target = self
            container.addSubview(button)
            xOffset += buttonSize + buttonSpacing
        }

        childWindow.contentView = container

        // Attach child window to parent
        window.addChildWindow(childWindow, ordered: .above)
        trafficLightWindow = childWindow
    }

    private func createTrafficLightButton(color: NSColor, action: Selector) -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 14, height: 14))
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = 7
        button.layer?.backgroundColor = color.cgColor
        button.action = action
        button.title = ""
        return button
    }

    @objc func closeWindow() {
        mainWindow?.close()
    }

    @objc func minimizeWindow() {
        mainWindow?.miniaturize(nil)
    }

    @objc func zoomWindow() {
        mainWindow?.zoom(nil)
    }
}

// Simple container that handles hover state for traffic light buttons
class TrafficLightContainer: NSView {
    private var trackingArea: NSTrackingArea?
    private var mouseInside = false
    weak var mainWindow: NSWindow?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        updateTrackingArea()
    }

    private func updateTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        if let area = trackingArea {
            addTrackingArea(area)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updateTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        mouseInside = true
    }

    override func mouseExited(with event: NSEvent) {
        mouseInside = false
    }

    // Called by NSButton internally to check if mouse is in the button group
    @objc func _mouseInGroup(_ button: NSButton) -> Bool {
        return mouseInside
    }
}
