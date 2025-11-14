import SwiftUI

extension Color {
    static let petlyDarkGreen = Color(red: 45/255, green: 95/255, blue: 79/255)
    static let petlySageGreen = Color(red: 139/255, green: 149/255, blue: 116/255)
    static let petlyLightGreen = Color(red: 169/255, green: 179/255, blue: 146/255)
    static let petlyCream = Color(red: 245/255, green: 242/255, blue: 235/255)
    static let petlyBeige = Color(red: 229/255, green: 224/255, blue: 213/255)
    static let petlyWhite = Color(red: 255/255, green: 255/255, blue: 252/255)
}

struct PetlyTheme {
    static let primaryColor = Color.petlyDarkGreen
    static let secondaryColor = Color.petlySageGreen
    static let backgroundColor = Color.petlyCream
    static let cardBackground = Color.petlyWhite
    static let buttonColor = Color.petlySageGreen
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    
    static let cornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 25
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16
}
