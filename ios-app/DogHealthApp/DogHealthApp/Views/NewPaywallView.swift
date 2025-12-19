import SwiftUI
import CoreText

struct NewPaywallView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPlan: PlanType = .annual
    @Environment(\.dismiss) var dismiss
    
    enum PlanType {
        case annual, monthly
    }
    
    let features = [
        ("heart.fill", "Personalized Wellness"),
        ("stethoscope", "Vet-Backed Insights"),
        ("chart.line.uptrend.xyaxis", "Smart Care Tracking"),
        ("crown.fill", "Exclusive Member Perks")
    ]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(12)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        ArcTextView(
                            text: "PETLY PREMIUM",
                            radius: 450,
                            arcAngle: 28
                        )
                        .frame(height: 60)
                        
                        HStack(spacing: 4) {
                            Text("Try us")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                            Text("free")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                                .underline()
                            Text("for 1 week.")
                                .font(.petlyTitle(32))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(features, id: \.1) { icon, title in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.petlyDarkGreen)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(title)
                                        .font(.petlyBody(16))
                                        .foregroundColor(.petlyDarkGreen)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                        
                        HStack(spacing: 12) {
                            PlanCard(
                                title: "Annual",
                                price: "$29.99",
                                originalPrice: "$35.99",
                                subtitle: "Per-year after a\n7 day free trial.",
                                badge: "SAVE 17%",
                                isSelected: selectedPlan == .annual
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .annual
                                }
                            }
                            
                            PlanCard(
                                title: "Monthly",
                                price: "$3.99",
                                originalPrice: nil,
                                subtitle: "Per-month after\na 7 day free trial.",
                                badge: nil,
                                isSelected: selectedPlan == .monthly
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = .monthly
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("You'll be charged $3.99 per-month after your 7 day free trial ends. You can cancel anytime.")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: startFreeTrial) {
                            Text("START YOUR FREE TRIAL")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index == 2 ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
    
    private func startFreeTrial() {
        appState.hasActiveSubscription = true
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let originalPrice: String?
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 12) {
                HStack {
                    Text(title)
                        .font(.petlyBodyMedium(18))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .petlyDarkGreen : .petlyFormIcon)
                }
                
                if let originalPrice = originalPrice {
                    Text(originalPrice)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .strikethrough()
                } else {
                    Text(" ")
                        .font(.petlyBody(14))
                }
                
                Text(price)
                    .font(.petlyTitle(36))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(subtitle)
                    .font(.petlyBody(11))
                    .foregroundColor(.petlyFormIcon)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let badge = badge {
                    Text(badge)
                        .font(.petlyBodyMedium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(16)
                } else {
                    Text(" ")
                        .font(.petlyBodyMedium(12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .opacity(0)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct ArcTextView: View {
    let text: String
    let radius: CGFloat
    let arcAngle: CGFloat
    
    var body: some View {
        Canvas { context, size in
            context.withCGContext { cgContext in
                let font = UIFont(name: "Georgia-Italic", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .medium)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(Color.petlyDarkGreen),
                    .kern: 2.0
                ]
                
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let line = CTLineCreateWithAttributedString(attributedString)
                let glyphRuns = CTLineGetGlyphRuns(line) as! [CTRun]
                
                var glyphPositions: [(glyph: CGGlyph, position: CGFloat, width: CGFloat)] = []
                var currentX: CGFloat = 0
                
                for run in glyphRuns {
                    let glyphCount = CTRunGetGlyphCount(run)
                    var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
                    var advances = [CGSize](repeating: .zero, count: glyphCount)
                    
                    CTRunGetGlyphs(run, CFRangeMake(0, glyphCount), &glyphs)
                    CTRunGetAdvances(run, CFRangeMake(0, glyphCount), &advances)
                    
                    for i in 0..<glyphCount {
                        let width = advances[i].width
                        glyphPositions.append((glyphs[i], currentX + width / 2, width))
                        currentX += width
                    }
                }
                
                let totalWidth = currentX
                let totalArcAngle = arcAngle * .pi / 180
                let startAngle = (.pi / 2) + (totalArcAngle / 2)
                
                let centerX = size.width / 2
                let centerY = size.height + radius - 30
                
                cgContext.saveGState()
                cgContext.textMatrix = .identity
                
                for (glyph, position, _) in glyphPositions {
                    let normalizedPosition = position / totalWidth
                    let angle = startAngle - (normalizedPosition * totalArcAngle)
                    
                    let x = centerX + radius * cos(angle)
                    let y = centerY - radius * sin(angle)
                    
                    cgContext.saveGState()
                    cgContext.translateBy(x: x, y: y)
                    cgContext.rotate(by: -(angle - .pi / 2))
                    cgContext.scaleBy(x: 1, y: -1)
                    
                    let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
                    var glyphCopy = glyph
                    var glyphPosition = CGPoint.zero
                    
                    CTFontDrawGlyphs(ctFont, &glyphCopy, &glyphPosition, 1, cgContext)
                    
                    cgContext.restoreGState()
                }
                
                cgContext.restoreGState()
            }
        }
    }
}

#Preview {
    NewPaywallView()
        .environmentObject(AppState())
}
