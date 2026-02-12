//
//  WindowStandardButtons.swift
//  AutoArchive
//
//  Created by Marco Triverio on 1/24/26.
//

import AppKit

class WindowStandardButtons: NSView {
    private let buttonDimension: CGFloat = 14
    private let buttonSpacing: CGFloat = 6

    private var trackingArea: NSTrackingArea?
    private var mouseIsInside = false

    private var closeButton: NSButton?
    private var minimizeButton: NSButton?
    private var zoomButton: NSButton?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        // Set initial frame size
        frame.size = NSSize(
            width: (buttonDimension * 3) + (buttonSpacing * 2),
            height: buttonDimension
        )
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window = window else { return }

        // Remove existing buttons if any
        closeButton?.removeFromSuperview()
        minimizeButton?.removeFromSuperview()
        zoomButton?.removeFromSuperview()

        // Create NEW buttons using the static factory method
        let styleMask = window.styleMask

        guard let newCloseButton = NSWindow.standardWindowButton(.closeButton, for: styleMask),
              let newMinimizeButton = NSWindow.standardWindowButton(.miniaturizeButton, for: styleMask),
              let newZoomButton = NSWindow.standardWindowButton(.zoomButton, for: styleMask) else {
            return
        }

        closeButton = newCloseButton
        minimizeButton = newMinimizeButton
        zoomButton = newZoomButton

        // Position buttons horizontally
        let buttons = [newCloseButton, newMinimizeButton, newZoomButton]
        var xOffset: CGFloat = 0

        for button in buttons {
            button.frame = NSRect(x: xOffset, y: 0, width: buttonDimension, height: buttonDimension)
            addSubview(button)
            xOffset += buttonDimension + buttonSpacing
        }

        // Set our frame to contain all buttons
        frame.size = NSSize(
            width: (buttonDimension * 3) + (buttonSpacing * 2),
            height: buttonDimension
        )

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

        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updateTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        mouseIsInside = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        mouseIsInside = false
        needsDisplay = true
    }

    // This method is called internally by NSButton to determine hover state
    @objc func _mouseInGroup(_ button: NSButton) -> Bool {
        return mouseIsInside
    }
}
