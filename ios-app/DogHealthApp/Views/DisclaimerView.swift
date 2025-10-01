import SwiftUI

struct DisclaimerView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasScrolledToBottom = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Important Safety Notice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DisclaimerSection(
                        title: "Not a Substitute for Veterinary Care",
                        content: "This app provides general information only and is not a substitute for professional veterinary advice, diagnosis, or treatment. Always seek the advice of your veterinarian with any questions you may have regarding your pet's health."
                    )
                    
                    DisclaimerSection(
                        title: "Emergency Situations",
                        content: "If your dog is experiencing a medical emergency, contact your veterinarian or emergency animal hospital immediately. Do not rely on this app for emergency medical guidance."
                    )
                    
                    DisclaimerSection(
                        title: "Red Flag Symptoms",
                        content: "Seek immediate veterinary care if your dog shows: difficulty breathing, loss of consciousness, severe bleeding, inability to urinate or defecate, suspected poisoning, severe pain, or any other concerning symptoms."
                    )
                    
                    DisclaimerSection(
                        title: "AI Limitations",
                        content: "Our AI assistant provides general information based on common knowledge about dog health and care. It cannot examine your pet, run diagnostic tests, or provide personalized medical advice."
                    )
                    
                    DisclaimerSection(
                        title: "Privacy Policy",
                        content: "By using this app, you agree to our Privacy Policy. We do not store personal health information about your pets. Chat conversations may be used to improve our service."
                    )
                    
                    Text("By continuing, you acknowledge that you have read and understood these important safety notices.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                hasScrolledToBottom = value <= -100
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    appState.acceptDisclaimer()
                }) {
                    Text("I Understand and Agree")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasScrolledToBottom ? PetlyColors.primaryGreen : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!hasScrolledToBottom)
                
                if !hasScrolledToBottom {
                    Text("Please scroll to read the full disclaimer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct DisclaimerSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
