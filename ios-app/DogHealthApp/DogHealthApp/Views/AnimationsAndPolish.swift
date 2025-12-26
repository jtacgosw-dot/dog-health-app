import SwiftUI

// MARK: - Skeleton Loading Views

struct SkeletonView: View {
    @State private var isAnimating = false
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.petlyLightGreen.opacity(0.6),
                        Color.petlyLightGreen.opacity(0.3),
                        Color.petlyLightGreen.opacity(0.6)
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView()
                .frame(height: 20)
                .frame(maxWidth: 150)
            
            SkeletonView()
                .frame(height: 60)
            
            HStack(spacing: 12) {
                SkeletonView()
                    .frame(width: 80, height: 16)
                SkeletonView()
                    .frame(width: 60, height: 16)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct SkeletonCircle: View {
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.petlyLightGreen.opacity(0.6),
                        Color.petlyLightGreen.opacity(0.3),
                        Color.petlyLightGreen.opacity(0.6)
                    ]),
                    startPoint: isAnimating ? .topLeading : .bottomTrailing,
                    endPoint: isAnimating ? .bottomTrailing : .topLeading
                )
            )
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Success Animation

struct SuccessCheckmarkView: View {
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0
    @State private var checkmarkProgress: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ZStack {
                    // Outer ring
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(Color.petlyDarkGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    // Inner circle
                    Circle()
                        .fill(Color.petlyDarkGreen)
                        .frame(width: 70, height: 70)
                    
                    // Checkmark
                    CheckmarkShape()
                        .trim(from: 0, to: checkmarkProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .frame(width: 30, height: 30)
                }
                .scaleEffect(scale)
                .onAppear {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Animate in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        scale = 1
                    }
                    
                    withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                        ringProgress = 1
                    }
                    
                    withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                        checkmarkProgress = 1
                    }
                    
                    // Auto dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scale = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.2))
        
        return path
    }
}

// MARK: - Enhanced Button Style with Haptics

struct PetlyPressButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.95
    var enableHaptics: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptics {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

struct PetlyBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: configuration.isPressed)
    }
}

// MARK: - Animated Ring for Health Score

struct AnimatedScoreRing: View {
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat
    @State private var animatedProgress: CGFloat = 0
    @State private var displayedScore: Int = 0
    
    private var ringColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.petlyDarkGreen.opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor.opacity(0.6), ringColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Score text
            VStack(spacing: 2) {
                Text("\(displayedScore)")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundColor(.petlyDarkGreen)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            animateScore()
        }
        .onChange(of: score) { _, _ in
            animateScore()
        }
    }
    
    private func animateScore() {
        // Reset
        animatedProgress = 0
        displayedScore = 0
        
        // Animate ring
        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            animatedProgress = CGFloat(score) / 100.0
        }
        
        // Animate number counting up
        let duration: Double = 1.0
        let steps = 30
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + (stepDuration * Double(i))) {
                withAnimation(.none) {
                    displayedScore = Int(Double(score) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Card Flip Animation

struct FlipCard<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: Front
    let back: Back
    
    init(isFlipped: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }
    
    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isFlipped)
    }
}

// MARK: - Parallax Header

struct ParallaxHeader<Content: View>: View {
    let height: CGFloat
    let content: Content
    
    init(height: CGFloat, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let offset = minY > 0 ? -minY : 0
            let scale = minY > 0 ? 1 + (minY / height) : 1
            
            content
                .frame(width: geometry.size.width, height: height + (minY > 0 ? minY : 0))
                .offset(y: offset)
                .scaleEffect(scale, anchor: .bottom)
        }
        .frame(height: height)
    }
}

// MARK: - Slide In Animation Modifier

struct SlideInModifier: ViewModifier {
    let index: Int
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isVisible ? 0 : 50)
            .opacity(isVisible ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7)
                .delay(Double(index) * 0.05),
                value: isVisible
            )
    }
}

extension View {
    func slideIn(index: Int, isVisible: Bool) -> some View {
        modifier(SlideInModifier(index: index, isVisible: isVisible))
    }
}

// MARK: - Bounce Animation Modifier

struct BounceModifier: ViewModifier {
    @State private var isAnimating = false
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        isAnimating = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                            isAnimating = false
                        }
                    }
                }
            }
    }
}

extension View {
    func bounce(trigger: Bool) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}

// MARK: - Pull to Refresh with Custom Animation

struct PullToRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
    }
}

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, onRefresh: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(isRefreshing: isRefreshing, onRefresh: onRefresh))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Appear Animation

struct AppearAnimationModifier: ViewModifier {
    @State private var hasAppeared = false
    let animation: Animation
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(animation: Animation = .spring(response: 0.5, dampingFraction: 0.7), delay: Double = 0) -> some View {
        modifier(AppearAnimationModifier(animation: animation, delay: delay))
    }
}

// MARK: - Tab Bar Bounce Effect

struct TabBarBounceEffect: ViewModifier {
    let isSelected: Bool
    @State private var bounceScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(bounceScale)
            .onChange(of: isSelected) { _, newValue in
                if newValue {
                    // Bounce animation
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                        bounceScale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            bounceScale = 1.0
                        }
                    }
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

extension View {
    func tabBarBounce(isSelected: Bool) -> some View {
        modifier(TabBarBounceEffect(isSelected: isSelected))
    }
}

// MARK: - Loading Dots Animation

struct LoadingDotsView: View {
    @State private var animatingDots = [false, false, false]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.petlyDarkGreen)
                    .frame(width: 8, height: 8)
                    .offset(y: animatingDots[index] ? -8 : 0)
            }
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
                ) {
                    animatingDots[i] = true
                }
            }
        }
    }
}

// MARK: - Pulsing Animation

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}

#Preview {
    VStack(spacing: 20) {
        SkeletonCard()
        
        AnimatedScoreRing(score: 75, size: 100, lineWidth: 10)
        
        LoadingDotsView()
    }
    .padding()
    .background(Color.petlyBackground)
}
