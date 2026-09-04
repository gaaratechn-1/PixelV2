import SwiftUI

/// Vista que renderiza el logotipo oficial de Pixel (la 'P' gótica cromada).
struct PixelLogoView: View {
    var size: CGFloat = 80
    var showGlow: Bool = true
    
    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.18),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.9
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
            }
            
            // Imagen del logo desde el Asset Catalog
            Image("PixelLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: 5)
        }
    }
}
