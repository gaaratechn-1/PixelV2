//
//  Theme.swift
//  PixelV2
//
//  Ultra Luxury Fintech Dark OLED Design System.
//  Gaara Quantum Studio
//

import SwiftUI

struct PixelTheme {
    static let canvas = Color(red: 10/255, green: 12/255, blue: 16/255)
    static let cardBg = Color(red: 18/255, green: 20/255, blue: 26/255)
    static let cardBorder = Color.white.opacity(0.08)
    static let cardBorderHover = Color.white.opacity(0.24)
    
    static let chromeWhite = Color.white
    static let chromeSilver = Color(red: 161/255, green: 161/255, blue: 170/255)
    static let chromeMuted = Color(red: 113/255, green: 113/255, blue: 122/255)
    
    static let accentMint = Color(red: 48/255, green: 209/255, blue: 88/255)
    static let dangerRed = Color(red: 255/255, green: 69/255, blue: 58/255)
    
    static let mintWaveGradient = LinearGradient(
        colors: [
            Color(red: 48/255, green: 209/255, blue: 88/255).opacity(0.28),
            Color(red: 48/255, green: 209/255, blue: 88/255).opacity(0.08),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    func pixelCardStyle() -> some View {
        self
            .background(PixelTheme.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(PixelTheme.cardBorder, lineWidth: 1)
            )
    }
}
