import SwiftUI

// MARK: - Language Model
enum Language: String, CaseIterable {
    case russian = "Ру"
    case english = "En"
    case spanish = "Es"
    case french = "Fr"
    case german = "De"
    case italian = "It"

    var fullName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        }
    }
    
    var apiCode: String {
        switch self {
        case .russian: return "ru"
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        }
    }
    
    init?(apiCode: String) {
        let lowercasedCode = apiCode.lowercased()
        for lang in Language.allCases {
            if lang.apiCode == lowercasedCode {
                self = lang
                return
            }
        }
        return nil
    }
}

struct PopupView: View {
    var text: String?
    
    // MARK: - State
    @AppStorage("sourceLanguage") private var sourceLanguage: Language = .russian
    @AppStorage("targetLanguage") private var targetLanguage: Language = .english
    @State private var favoriteLanguages: [String] = []
    @State private var showLanguageSelectors = false
    @State private var showSourceLanguageMenu = false
    @State private var showTargetLanguageMenu = false
    @State private var isHoveringOverPopup = false
    @State private var isHoveringOverMenus = false
    @State private var isLoading = false
    @State private var translatedText: String?
    @State private var justCopied = false
    @State private var originalText: String? // Original text to always translate from
    
    // MARK: - Computed Properties
    private var sortedLanguages: [Language] {
        let allLanguages = Language.allCases
        let favorites = allLanguages.filter { favoriteLanguages.contains($0.apiCode) }
        let nonFavorites = allLanguages.filter { !favoriteLanguages.contains($0.apiCode) }
        return favorites + nonFavorites
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 50)
                VStack{
                    VStack {
                        Text(isLoading ? "Translating..." : (translatedText ?? text ?? "Select text to translate..."))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                            .lineLimit(3) // Разрешаем множество строк
                            //.fixedSize(horizontal: false, vertical: true) // Позволяем тексту расширяться вертикально
                            .padding(20)
                    }
                    .background(Color(red: 0.06, green: 0.06, blue: 0.06))
                    .cornerRadius(10) // Сначала скругляем углы
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.09, green: 0.09, blue: 0.09), lineWidth: 1)
                    ).overlay(
                        languageSelector,
                        alignment: .topLeading
                    )
                    .overlay(
                        Button(action: copyToClipboard) {
                            ZStack {
                                Image(systemName: "doc.on.doc")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                                    .opacity(justCopied ? 0 : 1)
                                
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .mask(
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                )
                                .opacity(justCopied ? 1 : 0)
                            }
                            .frame(width: 10, height: 20)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.03, green: 0.03, blue: 0.03))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.09, green: 0.09, blue: 0.09), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(y: -15) // Поднимаем текст выше
                        .padding(.trailing, 10),
                        alignment: .topTrailing
                    )
                }
                .padding([.leading, .trailing], 35)
                .padding([.bottom], 20)
            }
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(Color.black)
            .clipShape(RoundedCorner(radius: 15))
            .padding([.leading, .trailing, .bottom], 15)
            .shadow(radius: 5)
            .onTapGesture {
                // Закрываем меню при клике на основную область
                closeAllMenus()
            }
            
            // Overlay для меню языков
            if showSourceLanguageMenu {
                languageMenuOverlay(for: .source, position: sourceLanguageMenuPosition)
            }
            
            if showTargetLanguageMenu {
                languageMenuOverlay(for: .target, position: targetLanguageMenuPosition)
            }
        }
        .onAppear {
            // Load favorite languages from UserDefaults
            if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteLanguages") as? [String] {
                favoriteLanguages = savedFavorites
            }
            
            // Save original text on first appearance
            if let currentText = text, !currentText.isEmpty {
                originalText = currentText
            }
            translate()
        }
        .onChange(of: text) {
            // Save original text when new text arrives
            if let newText = text, !newText.isEmpty {
                originalText = newText
            }
            translatedText = nil
            translate()
        }
        .onChange(of: sourceLanguage) {
            translate()
        }
        .onChange(of: targetLanguage) {
            translate()
        }
        .onHover { isHovering in
            isHoveringOverPopup = isHovering
            // Закрываем все меню только когда курсор покидает и главную область и дочерние меню
            if !isHovering && !isHoveringOverMenus {
                closeAllMenus()
            }
        }
    }
    
    // MARK: - Language Selector View
    @ViewBuilder
    private var languageSelector: some View {
        if !showLanguageSelectors {
            // Основной лейбл с языками
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    showLanguageSelectors = true
                }
            }) {
                Text("\(sourceLanguage.rawValue) -> \(targetLanguage.rawValue)")
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.09, green: 0.09, blue: 0.09), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .offset(y: -10)
            .padding(.leading, 10)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            ))
        } else {
            // Два отдельных селектора языков
            HStack(spacing: 8) {
                // Селектор исходного языка
                Button(action: {
                    showTargetLanguageMenu = false
                    showSourceLanguageMenu.toggle()
                }) {
                    Text(sourceLanguage.rawValue)
                        .font(.system(size: 12))
                        .frame(minWidth: 20)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
                
                Text("->")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 0.1).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.4).delay(0.1), value: showLanguageSelectors)
                
                // Селектор целевого языка
                Button(action: {
                    showSourceLanguageMenu = false
                    showTargetLanguageMenu.toggle()
                }) {
                    Text(targetLanguage.rawValue)
                        .font(.system(size: 12))
                        .frame(minWidth: 24)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
            .offset(y: -10)
            .padding(.leading, 10)
            .onTapGesture {
                // Prevent tap from propagating to background
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Language Menu Overlay
    private func languageMenuOverlay(for type: LanguageType, position: CGPoint) -> some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(sortedLanguages, id: \.self) { language in
                    Button(action: {
                        selectLanguage(language, for: type)
                    }) {
                        HStack {
                            Text(language.fullName)
                                .font(.system(size: 12))
                            Spacer()
                            Button(action: {
                                toggleFavorite(language)
                            }) {
                                Image(systemName: favoriteLanguages.contains(language.apiCode) ? "heart.fill" : "heart")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(favoriteLanguages.contains(language.apiCode) ? .red : .gray)
                                    .frame(width: 10, height: 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (type == .source ? sourceLanguage : targetLanguage) == language ?
                            Color.blue.opacity(0.3) : Color.black
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(red: 0.02, green: 0.02, blue: 0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 1))
        .frame(width: 120, height: 120)
        .shadow(radius: 5)
        .offset(x: position.x, y: position.y)
        .onTapGesture {
            // Prevent tap from propagating to background
        }
        .onHover { isHovering in
            isHoveringOverMenus = isHovering
            // Закрываем меню только когда курсор покидает и главную область и все дочерние меню
            if !isHovering && !isHoveringOverPopup {
                closeAllMenus()
            }
        }
        .zIndex(1000) // Ensure menu is above everything else
    }

    // MARK: - Language Menu
    private func languageMenu(for type: LanguageType) -> some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(sortedLanguages, id: \.self) { language in
                    Button(action: {
                        selectLanguage(language, for: type)
                    }) {
                        HStack {
                            Text(language.fullName)
                                .font(.system(size: 12))
                            Spacer()
                            Button(action: {
                                toggleFavorite(language)
                            }) {
                                Image(systemName: favoriteLanguages.contains(language.apiCode) ? "heart.fill" : "heart")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(favoriteLanguages.contains(language.apiCode) ? .red : .gray)
                                    .frame(width: 15, height: 15)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (type == .source ? sourceLanguage : targetLanguage) == language ?
                            Color.blue.opacity(0.3) : Color.black
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(red: 0.02, green: 0.02, blue: 0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 1))
        .frame(width: 120, height: 120)
        .shadow(radius: 3)
        .offset(y: 5)
    }
    
    // MARK: - Helper Methods
    private func copyToClipboard() {
        if let textToCopy = translatedText, !textToCopy.isEmpty {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(textToCopy, forType: .string)
            
            withAnimation(.easeInOut) {
                justCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut) {
                    justCopied = false
                }
            }
        }
    }
    
    private func translate() {
        guard let currentText = originalText, !currentText.isEmpty, !isLoading else {
            return
        }
        
        isLoading = true
        
        NetworkManager.sendPostRequest(text: currentText, sourceLang: sourceLanguage.apiCode, targetLang: targetLanguage.apiCode) { result in
            isLoading = false
            switch result {
            case .success(let response):
                translatedText = response.text
                // Убираем обновление языков из ответа API для предотвращения бесконечного цикла
                // Пользователь выбирает языки вручную через интерфейс
            case .failure(let error):
                // For now, just print the error. A proper UI message could be added.
                print("Translation error: \(error.localizedDescription)")
                translatedText = "Ошибка перевода" // Show error in UI
            }
        }
    }
    
    private func closeAllMenus() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if showSourceLanguageMenu || showTargetLanguageMenu {
                showSourceLanguageMenu = false
                showTargetLanguageMenu = false
            }
        }
        if showLanguageSelectors {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)) {
                showLanguageSelectors = false
                showSourceLanguageMenu = false
                showTargetLanguageMenu = false
            }
        }
        // Сбрасываем hover состояния
        isHoveringOverPopup = false
        isHoveringOverMenus = false
    }
    
    private func selectLanguage(_ language: Language, for type: LanguageType) {
        switch type {
        case .source:
            sourceLanguage = language
            showSourceLanguageMenu = false
        case .target:
            targetLanguage = language
            showTargetLanguageMenu = false
        }
    }
    
    private func toggleFavorite(_ language: Language) {
        if favoriteLanguages.contains(language.apiCode) {
            favoriteLanguages.removeAll { $0 == language.apiCode }
        } else {
            favoriteLanguages.append(language.apiCode)
        }
        // Save to UserDefaults
        UserDefaults.standard.set(favoriteLanguages, forKey: "favoriteLanguages")
    }
    
    // MARK: - Menu Positions
    private var sourceLanguageMenuPosition: CGPoint {
        CGPoint(x: -120, y: 25) // Позиция ниже левого селектора
    }
    
    private var targetLanguageMenuPosition: CGPoint {
        CGPoint(x: -60, y: 25) // Позиция ниже правого селектора
    }
}

// MARK: - Helper Enums
enum LanguageType {
    case source
    case target
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.addArc(tangent1End: CGPoint(x: rect.minX + radius, y: rect.minY),
                    tangent2End: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius)
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - radius))
        path.addArc(tangent1End: CGPoint(x: rect.minX + radius, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX + radius * 2, y: rect.maxY),
                    radius: radius)
        path.addLine(to: CGPoint(x: rect.maxX - radius * 2, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                    radius: radius)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + radius))
        path.addArc(tangent1End: CGPoint(x: rect.maxX - radius, y: rect.minY),
                    tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
                    radius: radius)
        
        path.closeSubpath()
        
        return path
    }
}

