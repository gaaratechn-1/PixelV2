import SwiftUI

/// Componente que dibuja la onda luminosa curva inspirada directamente en la tarjeta de la referencia.
struct GlowingWaveView: View {
    @State private var pulse: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            ZStack {
                // Relleno degradado bajo la curva
                WaveFillShape()
                    .fill(PixelTheme.mintWaveGradient)
                
                // Trazo superior brillante de la onda
                WaveStrokeShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                PixelTheme.accentMint.opacity(0.3),
                                PixelTheme.accentMint,
                                Color.white,
                                PixelTheme.accentMint
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: PixelTheme.accentMint.opacity(0.8), radius: pulse ? 8 : 4, x: 0, y: 0)
                
                // Nodo / Punto de pulso activo en la cresta de la curva
                let dotX = width * 0.72
                let dotY = height * 0.32
                
                ZStack {
                    Circle()
                        .fill(PixelTheme.accentMint.opacity(pulse ? 0.35 : 0.15))
                        .frame(width: pulse ? 22 : 14, height: pulse ? 22 : 14)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: PixelTheme.accentMint, radius: 6)
                }
                .position(x: dotX, y: dotY)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// Forma del trazo de la onda (Bézier suave)
struct WaveStrokeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.75))
        
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.85),
            control1: CGPoint(x: w * 0.12, y: h * 0.72),
            control2: CGPoint(x: w * 0.22, y: h * 0.86)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.32),
            control1: CGPoint(x: w * 0.48, y: h * 0.82),
            control2: CGPoint(x: w * 0.60, y: h * 0.35)
        )
        
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.55),
            control1: CGPoint(x: w * 0.82, y: h * 0.30),
            control2: CGPoint(x: w * 0.92, y: h * 0.48)
        )
        
        return path
    }
}

// Forma del relleno que cierra la base del gráfico
struct WaveFillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.75))
        
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.85),
            control1: CGPoint(x: w * 0.12, y: h * 0.72),
            control2: CGPoint(x: w * 0.22, y: h * 0.86)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.32),
            control1: CGPoint(x: w * 0.48, y: h * 0.82),
            control2: CGPoint(x: w * 0.60, y: h * 0.35)
        )
        
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.55),
            control1: CGPoint(x: w * 0.82, y: h * 0.30),
            control2: CGPoint(x: w * 0.92, y: h * 0.48)
        )
        
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}
