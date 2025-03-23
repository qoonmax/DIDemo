import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var trackingTimer: Timer?
    var cursorInsideWindow = false // Флаг для отслеживания, находится ли курсор на окне
    var isAnimating = false

    var clipboardText: String?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = PopupView(text: clipboardText)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver  // Самый высокий уровень, перекрывает меню-бар
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false // Окно может принимать события
        window.contentView = NSHostingView(rootView: contentView)
        window.orderOut(nil) // Скрываем по умолчанию

        // Запускаем таймер отслеживания курсора
        trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(trackMouse), userInfo: nil, repeats: true)
    }

    // Обработка отслеживания положения мыши
    @objc func trackMouse() {
        guard let screen = NSScreen.main else { return }
        let cursorPosition = NSEvent.mouseLocation // Глобальные координаты курсора

        let hotspotX = screen.frame.midX
        let hotspotY = screen.frame.maxY - 10

        let isInHotspot = (cursorPosition.x > hotspotX - 100 && cursorPosition.x < hotspotX + 100) &&
                          (cursorPosition.y > hotspotY - 30 && cursorPosition.y < hotspotY + 10)

        // Проверяем, находится ли курсор в пределах окна
        if window.frame.contains(cursorPosition) {
            cursorInsideWindow = true
        } else {
            cursorInsideWindow = false
        }

        // Если курсор в зоне "горячей точки" или на окне, показываем окно
        if isInHotspot && !window.isVisible && !isAnimating {
            showPopup()
        } else if !cursorInsideWindow && window.isVisible && !isAnimating {
            hidePopup()
        }
    }

    func showPopup() {
        guard !isAnimating else { return }
        isAnimating = true
        
        clearClipboard()
        simulateCmdC()

        // Извлечь текст из буфера обмена
        clipboardText = getClipboardText()
        
        if (clipboardText != nil) {
            SoundManager.shared.playSystemSound(named: "Pop")
        }

        if !window.isVisible {
            let contentView = PopupView(text: clipboardText)
            window.contentView = NSHostingView(rootView: contentView)
            
            let screenFrame = NSScreen.main!.frame
            let maxPopupWidth: CGFloat = 480
            let maxPopupHeight: CGFloat = 173

            let positionXForMaxPopup = screenFrame.midX - maxPopupWidth / 2
            let positionYForMaxPopup = screenFrame.maxY - maxPopupHeight

            let positionXForMinPopup: CGFloat = screenFrame.midX
            let positionYForMinPopup: CGFloat = screenFrame.maxY - 0

            window.setFrame(NSRect(x: positionXForMinPopup, y: positionYForMinPopup, width: 0, height: 0), display: true)

            window.orderFront(nil)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(NSRect(x: positionXForMaxPopup, y: positionYForMaxPopup, width: maxPopupWidth, height: maxPopupHeight), display: true)
            }, completionHandler: {
                self.isAnimating = false
            })
        } else {
            isAnimating = false
        }
    }

    func hidePopup() {
        guard !isAnimating else { return } // Предотвращаем повторную анимацию
        isAnimating = true
        
        if window.isVisible && !cursorInsideWindow {
            
            let screenFrame = NSScreen.main!.frame
            
            let positionXForMinPopup: CGFloat = screenFrame.midX
            let positionYForMinPopup: CGFloat = screenFrame.maxY + 20
            
            // Анимация скрытия окна
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3  // Время анимации скрытия
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(NSRect(x: positionXForMinPopup, y: positionYForMinPopup, width: 0, height: 0), display: true)
            }, completionHandler: {
                self.window.orderOut(nil)  // После завершения анимации скрыть окно
                self.isAnimating = false
            })
        } else {
            isAnimating = false
        }
    }
    
    func simulateCmdC() {
        let source = CGEventSource(stateID: .combinedSessionState)
                
        let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        let cKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        cKeyDown?.flags = .maskCommand
        
        // Используем CGHIDEventTap для предотвращения звуков
        cmdKeyDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)  // Задержка для стабилизации
        cKeyDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)  // Задержка для стабилизации
        cKeyUp?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)  // Задержка для стабилизации
        cmdKeyUp?.post(tap: .cghidEventTap)
    }

    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
    }
    
    // Функция для получения текста из буфера обмена
    func getClipboardText() -> String? {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string) else { return nil }

        // Убираем двойные пробелы, переносы строк и табуляции
        let cleanedText = text
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression) // Заменяем несколько пробелов на один
            .replacingOccurrences(of: "\\t", with: " ", options: .regularExpression) // Заменяем табуляции на пробел
            .replacingOccurrences(of: "\\n", with: " ", options: .regularExpression) // Заменяем переносы строк на пробел
            .trimmingCharacters(in: .whitespacesAndNewlines) // Убираем ведущие и завершающие пробелы и новые строки

        return cleanedText
    }
}
