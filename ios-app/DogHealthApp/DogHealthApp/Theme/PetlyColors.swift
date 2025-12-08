import SwiftUI

extension Color {
    static let petlyBackground = Color(hex: "FAF6EE")
    static let petlyLightGreen = Color(hex: "E7E3C8")
    static let petlyDarkGreen = Color(hex: "40462D")
    static let petlyFormIcon = Color(hex: "7C7F66")
    
    static let petlySageGreen = Color(hex: "E7E3C8")
    static let petlyCream = Color(hex: "FAF6EE")
    static let petlyBeige = Color(hex: "E7E3C8")
    static let petlyWhite = Color.white
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct PetlyTheme {
    static let primaryColor = Color.petlyDarkGreen
    static let secondaryColor = Color.petlyLightGreen
    static let backgroundColor = Color.petlyBackground
    static let cardBackground = Color.petlyLightGreen
    static let buttonColor = Color.petlyDarkGreen
    static let textPrimary = Color.petlyDarkGreen
    static let textSecondary = Color.petlyFormIcon
    
    static let cornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 25
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16
}

extension Font {
    static func petlyTitle(_ size: CGFloat) -> Font {
        return .custom("Stylish-Regular", size: size)
    }
    
    static func petlyBody(_ size: CGFloat = 16) -> Font {
        return .custom("Poppins-Regular", size: size)
    }
    
    static func petlyBodyMedium(_ size: CGFloat = 16) -> Font {
        return .custom("Poppins-Medium", size: size)
    }
}
