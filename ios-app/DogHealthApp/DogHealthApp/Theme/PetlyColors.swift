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
        return .custom("Stylish-Regular", size: size, relativeTo: .title)
    }
    
    static func petlyBody(_ size: CGFloat = 16) -> Font {
        return .custom("Poppins-Regular", size: size, relativeTo: .body)
    }
    
    static func petlyBodyMedium(_ size: CGFloat = 16) -> Font {
        return .custom("Poppins-Medium", size: size, relativeTo: .body)
    }
    
    static func petlyCaption(_ size: CGFloat = 12) -> Font {
        return .custom("Poppins-Regular", size: size, relativeTo: .caption)
    }
    
    static func petlyHeadline(_ size: CGFloat = 18) -> Font {
        return .custom("Poppins-Medium", size: size, relativeTo: .headline)
    }
}

struct ScaledSizes: View {
    @ScaledMetric(relativeTo: .body) var iconSmall: CGFloat = 16
    @ScaledMetric(relativeTo: .body) var iconMedium: CGFloat = 20
    @ScaledMetric(relativeTo: .body) var iconLarge: CGFloat = 28
    @ScaledMetric(relativeTo: .body) var iconXLarge: CGFloat = 40
    
    @ScaledMetric(relativeTo: .body) var paddingSmall: CGFloat = 8
    @ScaledMetric(relativeTo: .body) var paddingMedium: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var paddingLarge: CGFloat = 16
    @ScaledMetric(relativeTo: .body) var paddingXLarge: CGFloat = 20
    
    @ScaledMetric(relativeTo: .body) var spacingSmall: CGFloat = 8
    @ScaledMetric(relativeTo: .body) var spacingMedium: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var spacingLarge: CGFloat = 16
    
    @ScaledMetric(relativeTo: .body) var cardMinHeight: CGFloat = 100
    @ScaledMetric(relativeTo: .body) var buttonHeight: CGFloat = 44
    
    // Avatar sizes - scale with Dynamic Type but with limits
    @ScaledMetric(relativeTo: .body) var avatarSmall: CGFloat = 32
    @ScaledMetric(relativeTo: .body) var avatarMedium: CGFloat = 50
    @ScaledMetric(relativeTo: .body) var avatarLarge: CGFloat = 60
    @ScaledMetric(relativeTo: .body) var avatarXLarge: CGFloat = 120
    
    // Tab bar and navigation
    @ScaledMetric(relativeTo: .body) var tabBarButtonSize: CGFloat = 64
    @ScaledMetric(relativeTo: .body) var tabBarIconSize: CGFloat = 28
    
    // Activity ring
    @ScaledMetric(relativeTo: .body) var activityRingSize: CGFloat = 100
    @ScaledMetric(relativeTo: .body) var activityRingStroke: CGFloat = 12
    
    // Card heights - flexible minimums
    @ScaledMetric(relativeTo: .body) var cardMinHeightLarge: CGFloat = 280
    
    // Chat bubble
    @ScaledMetric(relativeTo: .body) var chatBubbleMaxWidth: CGFloat = 280
    
    // Image attachment preview
    @ScaledMetric(relativeTo: .body) var imagePreviewSize: CGFloat = 60
    
    var body: some View { EmptyView() }
}

// Environment key for accessing scaled sizes throughout the app
struct ScaledSizesKey: EnvironmentKey {
    static let defaultValue = ScaledSizesValues()
}

struct ScaledSizesValues {
    // Default values - these will be overridden by actual @ScaledMetric values in views
    var avatarSmall: CGFloat = 32
    var avatarMedium: CGFloat = 50
    var avatarLarge: CGFloat = 60
    var avatarXLarge: CGFloat = 120
    var tabBarButtonSize: CGFloat = 64
    var tabBarIconSize: CGFloat = 28
    var activityRingSize: CGFloat = 100
    var activityRingStroke: CGFloat = 12
    var cardMinHeightLarge: CGFloat = 280
    var chatBubbleMaxWidth: CGFloat = 280
    var imagePreviewSize: CGFloat = 60
}

extension EnvironmentValues {
    var scaledSizes: ScaledSizesValues {
        get { self[ScaledSizesKey.self] }
        set { self[ScaledSizesKey.self] = newValue }
    }
}

struct DynamicTypeModifier: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var scaleFactor: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(0.8)
            .lineLimit(nil)
    }
}

extension View {
    func dynamicTypeSupport() -> some View {
        modifier(DynamicTypeModifier())
    }
}
