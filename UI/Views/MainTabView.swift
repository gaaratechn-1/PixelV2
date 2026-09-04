//
//  MainTabView.swift
//  PixelV2
//
//  Main Tab View container with Key Authorization guard.
//  Gaara Quantum Studio
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var keyManager = KeyManager.shared
    @State private var selectedTab = 0
    
    init() {
        // Estilo de barra de navegación oscuro
        UITabBar.appearance().barTintColor = UIColor(red: 10/255, green: 12/255, blue: 16/255, alpha: 1.0)
        UITabBar.appearance().backgroundColor = UIColor(red: 10/255, green: 12/255, blue: 16/255, alpha: 1.0)
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.5, alpha: 1.0)
    }
    
    var body: some View {
        Group {
            if !keyManager.isAuthorized {
                KeyAuthView()
            } else {
                TabView(selection: $selectedTab) {
                    PixelDashboardView()
                        .tabItem {
                            Image(systemName: "square.grid.2x2.fill")
                            Text("Mods")
                        }
                        .tag(0)
                    
                    ContainerExplorerView()
                        .tabItem {
                            Image(systemName: "folder.fill")
                            Text("Explorador")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Ajustes")
                        }
                        .tag(2)
                }
                .accentColor(PixelTheme.chromeWhite)
            }
        }
    }
}
