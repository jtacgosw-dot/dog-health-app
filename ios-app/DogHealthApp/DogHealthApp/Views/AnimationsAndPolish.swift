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

// MARK: - Dashboard Skeleton Cards

struct SkeletonDashboardCard: View {
    let height: CGFloat
    
    init(height: CGFloat = 180) {
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 40)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView()
                        .frame(width: 120, height: 16)
                    SkeletonView()
                        .frame(width: 80, height: 12)
                }
                Spacer()
            }
            
            Spacer()
            
            SkeletonView()
                .frame(height: 40)
            
            HStack(spacing: 12) {
                SkeletonView()
                    .frame(width: 60, height: 14)
                SkeletonView()
                    .frame(width: 80, height: 14)
            }
        }
        .padding()
        .frame(height: height)
        .background(Color.petlyLightGreen.opacity(0.3))
        .cornerRadius(16)
    }
}

struct SkeletonActivityRingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                SkeletonView()
                    .frame(width: 100, height: 18)
                Spacer()
            }
            
            SkeletonCircle(size: 120)
            
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonView()
                            .frame(width: 40, height: 14)
                        SkeletonView()
                            .frame(width: 30, height: 10)
                    }
                }
            }
        }
        .padding()
        .frame(height: 240)
        .background(Color.petlyLightGreen.opacity(0.3))
        .cornerRadius(16)
    }
}

struct SkeletonListRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: 140, height: 16)
                SkeletonView()
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
            
            SkeletonView()
                .frame(width: 60, height: 24)
                .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }
}

struct SkeletonChatBubble: View {
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: CGFloat.random(in: 150...250), height: 14)
                SkeletonView()
                    .frame(width: CGFloat.random(in: 100...200), height: 14)
                if !isUser {
                    SkeletonView()
                        .frame(width: CGFloat.random(in: 80...150), height: 14)
                }
            }
            .padding()
            .background(isUser ? Color.petlyDarkGreen.opacity(0.3) : Color.petlyLightGreen.opacity(0.5))
            .cornerRadius(16)
            
            if !isUser { Spacer() }
        }
    }
}

struct SkeletonArticleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(cornerRadius: 12)
                .frame(height: 140)
            
            SkeletonView()
                .frame(height: 18)
                .frame(maxWidth: .infinity)
            
            SkeletonView()
                .frame(width: 200, height: 14)
            
            HStack {
                SkeletonView()
                    .frame(width: 80, height: 12)
                Spacer()
                SkeletonView()
                    .frame(width: 60, height: 12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct SkeletonProfileHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            SkeletonCircle(size: 100)
            
            SkeletonView()
                .frame(width: 150, height: 24)
            
            SkeletonView()
                .frame(width: 100, height: 14)
        }
    }
}

struct SkeletonHealthInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 36)
                SkeletonView()
                    .frame(width: 120, height: 16)
                Spacer()
            }
            
            SkeletonView()
                .frame(height: 14)
            SkeletonView()
                .frame(width: 200, height: 14)
            
            HStack(spacing: 8) {
                SkeletonView()
                    .frame(width: 70, height: 28)
                    .cornerRadius(14)
                SkeletonView()
                    .frame(width: 90, height: 28)
                    .cornerRadius(14)
            }
        }
        .padding()
        .background(Color.petlyLightGreen.opacity(0.3))
        .cornerRadius(16)
    }
}

// MARK: - Loading State Wrapper

struct LoadingStateView<Content: View, LoadingContent: View>: View {
    let isLoading: Bool
    let content: Content
    let loadingContent: LoadingContent
    
    init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loadingContent: () -> LoadingContent
    ) {
        self.isLoading = isLoading
        self.content = content()
        self.loadingContent = loadingContent()
    }
    
    var body: some View {
        if isLoading {
            loadingContent
                .transition(.opacity)
        } else {
            content
                .transition(.opacity)
        }
    }
}

// MARK: - Skeleton Dashboard Grid (for Home screen)

struct SkeletonDashboardGrid: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView()
                        .frame(width: 180, height: 28)
                    SkeletonView()
                        .frame(width: 120, height: 16)
                }
                Spacer()
                SkeletonCircle(size: 50)
            }
            .padding(.horizontal)
            
            // Cards grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                SkeletonDashboardCard(height: 160)
                SkeletonDashboardCard(height: 160)
                SkeletonDashboardCard(height: 160)
                SkeletonDashboardCard(height: 160)
            }
            .padding(.horizontal)
            
            // Full width card
            SkeletonActivityRingCard()
                .padding(.horizontal)
        }
    }
}

// MARK: - Skeleton Chat View

struct SkeletonChatView: View {
    var body: some View {
        VStack(spacing: 16) {
            SkeletonChatBubble(isUser: false)
            SkeletonChatBubble(isUser: true)
            SkeletonChatBubble(isUser: false)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Skeleton Explore View

struct SkeletonExploreView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Search bar skeleton
            SkeletonView()
                .frame(height: 44)
                .cornerRadius(22)
                .padding(.horizontal)
            
            // Categories skeleton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonView()
                            .frame(width: 80, height: 32)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            
            // Articles skeleton
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonArticleCard()
                    }
                }
                .padding(.horizontal)
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

// MARK: - Glow Effect for Pet Photo

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.2), radius: isGlowing ? radius : radius / 2)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func glow(color: Color = .petlyDarkGreen, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Card Press Style with Shadow

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.05),
                radius: configuration.isPressed ? 2 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var isShowing: Bool
    let particleCount: Int
    
    init(isShowing: Binding<Bool>, particleCount: Int = 50) {
        self._isShowing = isShowing
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            if isShowing {
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiParticle(index: index)
                }
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                // Auto-dismiss after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    isShowing = false
                }
            }
        }
    }
}

struct ConfettiParticle: View {
    let index: Int
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private let shapes: [AnyShape] = [AnyShape(Circle()), AnyShape(Rectangle()), AnyShape(Capsule())]
    
    var body: some View {
        shapes[index % shapes.count]
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
            .position(position)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                // Start from center top
                position = CGPoint(x: screenWidth / 2, y: 0)
                
                // Animate to random position
                withAnimation(.easeOut(duration: Double.random(in: 2.0...3.0))) {
                    position = CGPoint(
                        x: CGFloat.random(in: 0...screenWidth),
                        y: screenHeight + 50
                    )
                    rotation = Double.random(in: 0...720)
                    opacity = 0
                }
            }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Streak Counter View

struct StreakCounterView: View {
    let streakDays: Int
    @State private var animatedCount: Int = 0
    @State private var isFlaming = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: streakDays > 0 ? "flame.fill" : "flame")
                .font(.system(size: 24))
                .foregroundColor(streakDays > 0 ? .orange : .petlyFormIcon)
                .scaleEffect(isFlaming ? 1.2 : 1.0)
                .animation(
                    streakDays > 0 ?
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                        .default,
                    value: isFlaming
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(animatedCount)")
                    .font(.petlyTitle(24))
                    .foregroundColor(.petlyDarkGreen)
                    .contentTransition(.numericText())
                
                Text("day streak")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
        }
        .onAppear {
            if streakDays > 0 {
                isFlaming = true
            }
            animateCount()
        }
        .onChange(of: streakDays) { _, _ in
            animateCount()
        }
    }
    
    private func animateCount() {
        let duration: Double = 0.5
        let steps = min(streakDays, 20)
        guard steps > 0 else {
            animatedCount = 0
            return
        }
        
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                withAnimation(.none) {
                    animatedCount = Int(Double(streakDays) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Gradient Card Background

struct GradientCardBackground: View {
    let colors: [Color]
    
    init(colors: [Color] = [Color.petlyLightGreen, Color.petlyLightGreen.opacity(0.8)]) {
        self.colors = colors
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Swipe Action Card Modifier

struct SwipeActionModifier: ViewModifier {
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    @State private var offset: CGFloat = 0
    @State private var showingLeading = false
    @State private var showingTrailing = false
    
    struct SwipeAction: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let action: () -> Void
    }
    
    func body(content: Content) -> some View {
        ZStack {
            // Leading actions
            HStack(spacing: 0) {
                ForEach(leadingActions) { action in
                    Button(action: {
                        withAnimation { offset = 0 }
                        action.action()
                    }) {
                        Image(systemName: action.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(action.color)
                    }
                }
                Spacer()
            }
            .opacity(showingLeading ? 1 : 0)
            
            // Trailing actions
            HStack(spacing: 0) {
                Spacer()
                ForEach(trailingActions) { action in
                    Button(action: {
                        withAnimation { offset = 0 }
                        action.action()
                    }) {
                        Image(systemName: action.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(action.color)
                    }
                }
            }
            .opacity(showingTrailing ? 1 : 0)
            
            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation.width
                            showingLeading = offset > 30
                            showingTrailing = offset < -30
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if offset > 100 && !leadingActions.isEmpty {
                                    offset = CGFloat(leadingActions.count) * 60
                                } else if offset < -100 && !trailingActions.isEmpty {
                                    offset = -CGFloat(trailingActions.count) * 60
                                } else {
                                    offset = 0
                                    showingLeading = false
                                    showingTrailing = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}

extension View {
    func swipeActions(
        leading: [SwipeActionModifier.SwipeAction] = [],
        trailing: [SwipeActionModifier.SwipeAction] = []
    ) -> some View {
        modifier(SwipeActionModifier(leadingActions: leading, trailingActions: trailing))
    }
}

// MARK: - Share Health Summary Card

struct ShareableHealthCard: View {
    let petName: String
    let healthScore: Int
    let streakDays: Int
    let activityMinutes: Int
    let mealsLogged: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.petlyDarkGreen)
                Text("Petly")
                    .font(.petlyTitle(24))
                    .foregroundColor(.petlyDarkGreen)
                Spacer()
            }
            
            // Pet name and score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(petName)
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                    Text("Health Summary")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                }
                Spacer()
                
                // Health score ring
                ZStack {
                    Circle()
                        .stroke(Color.petlyDarkGreen.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(healthScore) / 100)
                        .stroke(Color.petlyDarkGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(healthScore)")
                        .font(.petlyTitle(20))
                        .foregroundColor(.petlyDarkGreen)
                }
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                StatItem(icon: "flame.fill", value: "\(streakDays)", label: "Day Streak", color: .orange)
                StatItem(icon: "figure.walk", value: "\(activityMinutes)", label: "Minutes", color: .green)
                StatItem(icon: "fork.knife", value: "\(mealsLogged)", label: "Meals", color: .blue)
            }
            
            // Footer
            Text("petlyapp.com")
                .font(.petlyBody(12))
                .foregroundColor(.petlyFormIcon)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.petlyBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            Text(label)
                .font(.petlyBody(10))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State with Animation

struct AnimatedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @State private var isAnimating = false
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.petlyDarkGreen.opacity(0.5))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text(title)
                .font(.petlyTitle(20))
                .foregroundColor(.petlyDarkGreen)
            
            Text(message)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(20)
                }
                .buttonStyle(PetlyPressButtonStyle())
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Haptic Feedback Helper

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Onboarding Tooltips System

class OnboardingTooltipManager: ObservableObject {
    static let shared = OnboardingTooltipManager()
    
    private let userDefaultsPrefix = "tooltip_shown_"
    
    enum TooltipKey: String, CaseIterable {
        case dailyLog = "daily_log"
        case healthTimeline = "health_timeline"
        case aiChat = "ai_chat"
        case petProfile = "pet_profile"
        case reminders = "reminders"
        case carePlans = "care_plans"
        case healthScore = "health_score"
        case swipeToDelete = "swipe_to_delete"
    }
    
    func shouldShowTooltip(for key: TooltipKey) -> Bool {
        !UserDefaults.standard.bool(forKey: userDefaultsPrefix + key.rawValue)
    }
    
    func markTooltipShown(for key: TooltipKey) {
        UserDefaults.standard.set(true, forKey: userDefaultsPrefix + key.rawValue)
    }
    
    func resetAllTooltips() {
        for key in TooltipKey.allCases {
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + key.rawValue)
        }
    }
}

struct TooltipView: View {
    let message: String
    let icon: String
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(message)
                .font(.petlyBody(14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button(action: {
                HapticFeedback.light()
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.petlyDarkGreen)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

struct TooltipModifier: ViewModifier {
    let tooltipKey: OnboardingTooltipManager.TooltipKey
    let message: String
    let icon: String
    
    @State private var showTooltip = false
    @StateObject private var tooltipManager = OnboardingTooltipManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showTooltip {
                    TooltipView(
                        message: message,
                        icon: icon,
                        onDismiss: {
                            tooltipManager.markTooltipShown(for: tooltipKey)
                            showTooltip = false
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .onAppear {
                if tooltipManager.shouldShowTooltip(for: tooltipKey) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showTooltip = true
                        }
                    }
                }
            }
    }
}

extension View {
    func onboardingTooltip(
        key: OnboardingTooltipManager.TooltipKey,
        message: String,
        icon: String = "lightbulb.fill"
    ) -> some View {
        modifier(TooltipModifier(tooltipKey: key, message: message, icon: icon))
    }
}

// MARK: - Feature Highlight Pulse

struct FeatureHighlightView: View {
    let isActive: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.petlyDarkGreen.opacity(0.3))
            .frame(width: 20, height: 20)
            .scaleEffect(isPulsing ? 1.5 : 1.0)
            .opacity(isPulsing ? 0 : 1)
            .overlay(
                Circle()
                    .fill(Color.petlyDarkGreen)
                    .frame(width: 10, height: 10)
            )
            .opacity(isActive ? 1 : 0)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }
            }
    }
}

// MARK: - Enhanced Button with Haptic Feedback

struct HapticButton<Label: View>: View {
    let action: () -> Void
    let feedbackStyle: HapticStyle
    let label: () -> Label
    
    enum HapticStyle {
        case light, medium, heavy, selection, success
    }
    
    init(
        feedbackStyle: HapticStyle = .light,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.feedbackStyle = feedbackStyle
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            label()
        }
        .buttonStyle(PetlyPressButtonStyle())
    }
    
    private func triggerHaptic() {
        switch feedbackStyle {
        case .light:
            HapticFeedback.light()
        case .medium:
            HapticFeedback.medium()
        case .heavy:
            HapticFeedback.heavy()
        case .selection:
            HapticFeedback.selection()
        case .success:
            HapticFeedback.success()
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text(message)
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(Color.petlyDarkGreen)
                .cornerRadius(16)
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Skeleton Loading for Reminders

struct SkeletonReminderCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: 120, height: 14)
                SkeletonView()
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            SkeletonCircle(size: 28)
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Loading for Care Plans

struct SkeletonCarePlanCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView()
                        .frame(width: 140, height: 16)
                    SkeletonView()
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
                
                SkeletonView()
                    .frame(width: 50, height: 24)
                    .cornerRadius(8)
            }
            
            SkeletonView()
                .frame(height: 8)
                .cornerRadius(4)
            
            HStack {
                SkeletonView()
                    .frame(width: 80, height: 12)
                Spacer()
                SkeletonView()
                    .frame(width: 60, height: 12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Enhanced Empty State

struct EnhancedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?
    
    @State private var iconBounce = false
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.petlyDarkGreen.opacity(0.5))
                .scaleEffect(iconBounce ? 1.1 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        iconBounce = true
                    }
                }
            
            Text(title)
                .font(.petlyTitle(22))
                .foregroundColor(.petlyDarkGreen)
            
            Text(message)
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                HapticButton(feedbackStyle: .medium, action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(25)
                }
            }
            
            if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                Button(action: {
                    HapticFeedback.light()
                    secondaryAction()
                }) {
                    Text(secondaryTitle)
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyDarkGreen)
                        .underline()
                }
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - First Time User Welcome Card

struct WelcomeCard: View {
    let petName: String
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                
                Text("Welcome to Petly!")
                    .font(.petlyTitle(20))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                    withAnimation {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.petlyFormIcon)
                }
            }
            
            Text("Start tracking \(petName)'s health by logging daily activities. Tap the + button to add your first entry!")
                .font(.petlyBody(14))
                .foregroundColor(.petlyDarkGreen)
            
            HStack(spacing: 16) {
                QuickTipItem(icon: "fork.knife", text: "Log meals")
                QuickTipItem(icon: "figure.walk", text: "Track walks")
                QuickTipItem(icon: "heart.fill", text: "Monitor health")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.petlyLightGreen)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

struct QuickTipItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
            Text(text)
                .font(.petlyCaption(11))
                .foregroundColor(.petlyFormIcon)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Swipe Hint Animation

struct SwipeHintView: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw")
                .font(.system(size: 16))
            Text("Swipe left to delete")
                .font(.petlyBody(12))
        }
        .foregroundColor(.petlyFormIcon)
        .offset(x: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                offset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SkeletonCard()
        
        AnimatedScoreRing(score: 75, size: 100, lineWidth: 10)
        
        LoadingDotsView()
        
        StreakCounterView(streakDays: 7)
        
        ShareableHealthCard(
            petName: "Buddy",
            healthScore: 85,
            streakDays: 7,
            activityMinutes: 45,
            mealsLogged: 3
        )
        .padding()
    }
    .padding()
    .background(Color.petlyBackground)
}
