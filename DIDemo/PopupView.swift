import SwiftUI

// MARK: - Language Model
enum Language: String, CaseIterable {
    case russian = "Ру"
    case english = "En"
    case spanish = "Es"
    case french = "Fr"
    
    var fullName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        }
    }
}

struct PopupView: View {
    var text: String?
    
    // MARK: - Language Selection State
    @State private var sourceLanguage: Language = .russian
    @State private var targetLanguage: Language = .english
    @State private var showLanguageSelectors = false
    @State private var showSourceLanguageMenu = false
    @State private var showTargetLanguageMenu = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 50)
                VStack{
                    VStack {
                        Text(text ?? "Выделите текст для...")
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
                        HStack{
    //                        Text("Copy")
    //                            .font(.system(size: 12))
                            Image(systemName: "doc.on.doc")
                                .frame(width: 10)
                        }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.03, green: 0.03, blue: 0.03))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.09, green: 0.09, blue: 0.09), lineWidth: 1))
                            .offset(y: -15) // Поднимаем текст выше
                            .padding(.trailing, 10),
                        alignment: .topTrailing)
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
                if showSourceLanguageMenu || showTargetLanguageMenu {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSourceLanguageMenu = false
                        showTargetLanguageMenu = false
                    }
                }
                // Закрываем селекторы при клике на основную область
                if showLanguageSelectors {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)) {
                        showLanguageSelectors = false
                        showSourceLanguageMenu = false
                        showTargetLanguageMenu = false
                    }
                }
            }
            
            // Overlay для меню языков
            if showSourceLanguageMenu {
                languageMenuOverlay(for: .source, position: sourceLanguageMenuPosition)
            }
            
            if showTargetLanguageMenu {
                languageMenuOverlay(for: .target, position: targetLanguageMenuPosition)
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
        VStack(spacing: 2) {
            ForEach(Language.allCases, id: \.self) { language in
                Button(action: {
                    selectLanguage(language, for: type)
                }) {
                    HStack {
                        Text(language.rawValue)
                            .font(.system(size: 10))
                        Spacer()
                        Text(language.fullName)
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
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
        .background(Color(red: 0.02, green: 0.02, blue: 0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 1))
        .frame(width: 120)
        .shadow(radius: 5)
        .offset(x: position.x, y: position.y)
        .onTapGesture {
            // Prevent tap from propagating to background
        }
        .zIndex(1000) // Ensure menu is above everything else
    }
    
    // MARK: - Language Menu
    private func languageMenu(for type: LanguageType) -> some View {
        VStack(spacing: 2) {
            ForEach(Language.allCases, id: \.self) { language in
                Button(action: {
                    selectLanguage(language, for: type)
                }) {
                    HStack {
                        Text(language.rawValue)
                            .font(.system(size: 10))
                        Spacer()
                        Text(language.fullName)
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
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
        .background(Color(red: 0.02, green: 0.02, blue: 0.02))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.1, green: 0.1, blue: 0.1), lineWidth: 1))
        .frame(width: 120)
        .shadow(radius: 3)
        .offset(y: 5)
    }
    
    // MARK: - Helper Methods
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

