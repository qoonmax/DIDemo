import SwiftUI

struct PopupView: View {
    var text: String?
    
    var body: some View {
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
                    Text("Ру -> En")
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
                        .cornerRadius(10) // Сначала скругляем углы
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.09, green: 0.09, blue: 0.09), lineWidth: 1))
                        .offset(y: -10) // Поднимаем текст выше
                        .padding(.leading, 10),
                    alignment: .topLeading)
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
    }
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

