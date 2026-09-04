//
//  App.swift
//  PixelV2
//
//  Application entry point.
//  Gaara Quantum Studio
//

import SwiftUI

@main
struct PixelV2App: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
