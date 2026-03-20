import AppKit
import ApplicationServices
import Foundation
import OSLog

enum WindowAccessibilityController {
    private static let logger = Logger(
        subsystem: "com.liangzhiyuan.pathbridge.adapters",
        category: "window-accessibility"
    )

    static func focusedWindowFrame(bundleIdentifier: String) -> CGRect? {
        guard ensureTrusted(prompt: false) else {
            return nil
        }
        guard let application = runningApplication(bundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return focusedWindowFrame(application: application)
            ?? lastWindowFrame(application: application)
    }

    @discardableResult
    static func moveFocusedWindow(
        bundleIdentifier: String,
        to frame: CGRect,
        promptForTrust: Bool,
        timeout: TimeInterval = 1.5
    ) -> Bool {
        guard ensureTrusted(prompt: promptForTrust) else {
            logger.error("skip move reason=accessibility-untrusted bundleID=\(bundleIdentifier, privacy: .public)")
            return false
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let application = runningApplication(bundleIdentifier: bundleIdentifier),
               let window = focusedWindow(application: application) ?? lastWindow(application: application),
               setFrame(frame, for: window)
            {
                logger.info(
                    "window move success bundleID=\(bundleIdentifier, privacy: .public) x=\(frame.origin.x, privacy: .public) y=\(frame.origin.y, privacy: .public) width=\(frame.width, privacy: .public) height=\(frame.height, privacy: .public)"
                )
                return true
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        logger.error("window move failed bundleID=\(bundleIdentifier, privacy: .public) reason=timeout")
        return false
    }

    private static func runningApplication(bundleIdentifier: String) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .sorted { $0.launchDate ?? .distantPast < $1.launchDate ?? .distantPast }
            .last
    }

    private static func focusedWindowFrame(application: NSRunningApplication) -> CGRect? {
        guard let window = focusedWindow(application: application) else {
            return nil
        }
        return frame(for: window)
    }

    private static func lastWindowFrame(application: NSRunningApplication) -> CGRect? {
        guard let window = lastWindow(application: application) else {
            return nil
        }
        return frame(for: window)
    }

    private static func focusedWindow(application: NSRunningApplication) -> AXUIElement? {
        let element = AXUIElementCreateApplication(application.processIdentifier)
        return copyWindowAttribute(
            name: kAXFocusedWindowAttribute as CFString,
            from: element
        )
    }

    private static func lastWindow(application: NSRunningApplication) -> AXUIElement? {
        let element = AXUIElementCreateApplication(application.processIdentifier)
        guard let windows = copyWindowList(from: element) else {
            return nil
        }
        return windows.last
    }

    private static func frame(for window: AXUIElement) -> CGRect? {
        guard let positionValue = copyAttribute(
            name: kAXPositionAttribute as CFString,
            from: window
        ),
        let sizeValue = copyAttribute(
            name: kAXSizeAttribute as CFString,
            from: window
        ),
        let position = point(from: positionValue),
        let size = size(from: sizeValue)
        else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    private static func setFrame(_ frame: CGRect, for window: AXUIElement) -> Bool {
        var position = frame.origin
        guard let positionValue = AXValueCreate(.cgPoint, &position),
              AXUIElementSetAttributeValue(
                  window,
                  kAXPositionAttribute as CFString,
                  positionValue
              ) == .success
        else {
            return false
        }

        var size = frame.size
        guard let sizeValue = AXValueCreate(.cgSize, &size),
              AXUIElementSetAttributeValue(
                  window,
                  kAXSizeAttribute as CFString,
                  sizeValue
              ) == .success
        else {
            return false
        }

        return true
    }

    private static func copyWindowAttribute(name: CFString, from element: AXUIElement) -> AXUIElement? {
        guard let value = copyAttribute(name: name, from: element) else {
            return nil
        }
        return unsafeDowncast(value as AnyObject, to: AXUIElement.self)
    }

    private static func copyWindowList(from element: AXUIElement) -> [AXUIElement]? {
        guard let value = copyAttribute(name: kAXWindowsAttribute as CFString, from: element) else {
            return nil
        }
        let array = value as! [AnyObject]
        return array.compactMap { unsafeDowncast($0, to: AXUIElement.self) }
    }

    private static func copyAttribute(name: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name, &value)
        guard result == .success else {
            return nil
        }
        return value
    }

    private static func point(from value: CFTypeRef) -> CGPoint? {
        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = unsafeDowncast(value as AnyObject, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private static func size(from value: CFTypeRef) -> CGSize? {
        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = unsafeDowncast(value as AnyObject, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }

    private static func ensureTrusted(prompt: Bool) -> Bool {
        if prompt {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }
}
