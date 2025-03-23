//
//  SoundManager.swift
//  DIDemo
//
//  Created by Максим Марков on 14.02.2025.
//

import AppKit

class SoundManager {
    static let shared = SoundManager() // Синглтон для удобства

    private init() {} // Запрещаем создание экземпляров класса извне

    func playSystemSound(named name: String) {
        if let sound = NSSound(named: .init(name)) {
            if sound.isPlaying {
                sound.stop() // Останавливаем текущий звук, если он играет
            }
            sound.play()
        } else {
            print("Не удалось загрузить звук: \(name)")
        }
    }
}
