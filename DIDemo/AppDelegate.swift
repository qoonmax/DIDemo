import Cocoa
import SwiftUI
import ApplicationServices

// Результат попытки получения выделенного текста
enum SelectionResult {
    case success(String)
    case failure(AXError) // Упрощаем: теперь только ошибка, без причины
    case noSelection
}

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

        checkAccessibilityPermissions()
        
        // Запускаем таймер отслеживания курсора
        trackingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(trackMouse), userInfo: nil, repeats: true)
    }

    func checkAccessibilityPermissions() {
        // Эта опция заставит систему показать диалог запроса разрешений, если их нет.
        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !isTrusted {
            print("LOG: Разрешения на использование Accessibility НЕ предоставлены.")
        } else {
            print("LOG: Разрешения на использование Accessibility предоставлены.")
        }
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
            print("LOG: Курсор в горячей зоне, вызываю showPopup()")
            showPopup()
        } else if !cursorInsideWindow && window.isVisible && !isAnimating {
            hidePopup()
        }
    }

    func showPopup() {
        guard !isAnimating else { return }
        isAnimating = true
        
        print("LOG: --- Начало showPopup ---")
        
        // Увеличиваем задержку до 0.1 сек для большей стабильности
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var finalText: String?

            let selectionResult = self.getSelectedText()
            
            switch selectionResult {
            case .success(let text):
                print("LOG: Успех через Accessibility API")
                finalText = text
            
            case .failure(let error):
                // Прямая проверка кода ошибки. -25212 это kAXErrorAttributeUnsupported, -25204 это kAXErrorCannotComplete.
                if error.rawValue == -25212 || error.rawValue == -25204 {
                    print("LOG: Не удалось получить текст напрямую (ошибка \(error.rawValue)). Переключаюсь на Cmd+C.")
                    self.clearClipboard()
                    self.simulateCmdC()
                    finalText = self.getClipboardText()
                } else {
                    // Все остальные, действительно непредвиденные ошибки просто игнорируем
                    print("LOG: Неизвестная ошибка Accessibility: \(error.rawValue). Окно не будет показано.")
                    self.isAnimating = false
                    return
                }
                
            case .noSelection:
                print("LOG: Нет выделения или оно пустое.")
                self.isAnimating = false
                if self.window.isVisible {
                    self.hidePopup()
                }
                return
            }
            
            guard let text = finalText, !text.isEmpty else {
                self.isAnimating = false
                if self.window.isVisible {
                    self.hidePopup()
                }
                return
            }

            // Получаем языки из UserDefaults
            let sourceLangRaw = UserDefaults.standard.string(forKey: "sourceLanguage") ?? "Ру"
            let targetLangRaw = UserDefaults.standard.string(forKey: "targetLanguage") ?? "En"

            // Отправляем POST-запрос
            NetworkManager.sendPostRequest(text: text, sourceLang: sourceLangRaw, targetLang: targetLangRaw)
            
            self.clipboardText = text
            SoundManager.shared.playSystemSound(named: "Pop")
            
            let contentView = PopupView(text: self.clipboardText)
            self.window.contentView = NSHostingView(rootView: contentView)

            if !self.window.isVisible {
                let screenFrame = NSScreen.main!.frame
                let maxPopupWidth: CGFloat = 480
                let maxPopupHeight: CGFloat = 173

                let positionXForMaxPopup = screenFrame.midX - maxPopupWidth / 2
                let positionYForMaxPopup = screenFrame.maxY - maxPopupHeight

                let positionXForMinPopup: CGFloat = screenFrame.midX
                let positionYForMinPopup: CGFloat = screenFrame.maxY - 0

                self.window.setFrame(NSRect(x: positionXForMinPopup, y: positionYForMinPopup, width: 0, height: 0), display: true)

                self.window.orderFront(nil)
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.window.animator().setFrame(NSRect(x: positionXForMaxPopup, y: positionYForMaxPopup, width: maxPopupWidth, height: maxPopupHeight), display: true)
                }, completionHandler: {
                    self.isAnimating = false
                })
            } else {
                self.isAnimating = false
            }
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
    
    // Функция для получения выделенного текста через Accessibility API (альтернативный, более надежный метод)
    func getSelectedText() -> SelectionResult {
        print("LOG: --- Начало getSelectedText (Альтернативный метод) ---")

        // Используем NSWorkspace, чтобы найти активное приложение
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("LOG: Не удалось определить активное приложение.")
            return .failure(.apiDisabled)
        }
        
        // КРИТИЧЕСКИ ВАЖНО: Игнорируем себя, чтобы избежать бесконечного цикла
        if frontmostApp.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            // Это не ошибка, просто мы не должны реагировать на самих себя.
            return .noSelection
        }
        
        print("LOG: Активное приложение: \(frontmostApp.localizedName ?? "Неизвестно") (\(frontmostApp.bundleIdentifier ?? ""))")

        // Создаем AXUIElement для этого приложения
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        // Пытаемся получить у него атрибут фокуса
        var focusedElement: AnyObject?
        let focusErrorCode = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard focusErrorCode == .success, let element = focusedElement else {
            print("LOG: Ошибка получения focusedElement из активного приложения. Код ошибки: \(focusErrorCode.rawValue)")
            return .failure(focusErrorCode)
        }

        print("LOG: focusedElement получен успешно.")
        var selectedText: AnyObject?
        let textErrorCode = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard textErrorCode == .success else {
            print("LOG: Ошибка получения selectedText. Код ошибки: \(textErrorCode.rawValue)")
            // Важно отличать ошибку "нет значения" от других ошибок
            if textErrorCode.rawValue == -25201 { // kAXErrorNoValue
                return .noSelection
            }
            return .failure(textErrorCode)
        }

        guard let selectedTextString = selectedText as? String else {
             return .noSelection // Текст есть, но он не строка
        }

        print("LOG: Сырой выделенный текст: '\(selectedTextString)'")
        
        // Применяем ту же очистку текста
        let cleanedText = selectedTextString
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("LOG: Очищенный текст: '\(cleanedText)'")
        
        return cleanedText.isEmpty ? .noSelection : .success(cleanedText)
    }

    func simulateCmdC() {
        let source = CGEventSource(stateID: .combinedSessionState)
                
        let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cKeyDown?.flags = .maskCommand
        let cKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdKeyDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.05)
        cKeyDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.05)
        cKeyUp?.post(tap: .cghidEventTap)
        cmdKeyUp?.post(tap: .cghidEventTap)
    }

    func clearClipboard() {
        NSPasteboard.general.clearContents()
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
