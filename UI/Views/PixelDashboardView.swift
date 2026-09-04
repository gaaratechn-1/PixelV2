//
//  PixelDashboardView.swift
//  PixelV2
//
//  Master Dashboard with digital signature telemetry, mod cards and panic restore.
//  Gaara Quantum Studio
//

import SwiftUI

struct PixelDashboardView: View {
    @ObservedObject var store = ModStateStore.shared
    @ObservedObject var containerManager = ContainerManager.shared
    @ObservedObject var keyManager = KeyManager.shared
    
    @State private var selectedCategory: ModCategory = .all
    
    var filteredMods: [ModItemInfo] {
        if selectedCategory == .all {
            return store.engine.allMods
        }
        return store.engine.allMods.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            PixelTheme.canvas.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    
                    digitalSignatureCard
                    
                    dualStatusBanner
                    
                    categoryFilterBar
                    
                    modsListView
                    
                    panicRestoreSection
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .alert(isPresented: $store.showAlert) {
            Alert(
                title: Text(store.alertTitle),
                message: Text(store.alertMessage),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }
    
    // MARK: - 1. Encabezado Superior
    private var headerView: some View {
        HStack(spacing: 14) {
            PixelLogoView(size: 46, showGlow: false)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("NODO LOCAL // ACTIVO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(PixelTheme.chromeMuted)
                
                Text("PixelV2 Suite")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(PixelTheme.chromeWhite)
            }
            
            Spacer()
            
            Button(action: {
                keyManager.logout()
            }) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(PixelTheme.chromeSilver)
                    .padding(10)
                    .background(PixelTheme.cardBg)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PixelTheme.cardBorder, lineWidth: 1))
            }
        }
        .padding(.top, 6)
    }
    
    // MARK: - 1.1 Tarjeta de Firma Digital Registrada
    private var digitalSignatureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundColor(PixelTheme.chromeWhite)
                
                Text("FIRMA DIGITAL REGISTRADA")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(PixelTheme.chromeWhite)
                
                Spacer()
                
                Text(keyManager.remainingDaysStr)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(PixelTheme.chromeWhite)
                    .cornerRadius(6)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Team / Certificado:")
                        .font(.system(size: 10))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Text(keyManager.certTeamName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PixelTheme.chromeWhite)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Dispositivo UDID:")
                        .font(.system(size: 10))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Text(keyManager.deviceUDID.count > 14 ? keyManager.deviceUDID.prefix(14) + "..." : keyManager.deviceUDID)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(PixelTheme.chromeSilver)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(PixelTheme.cardBorderHover, lineWidth: 1))
    }
    
    // MARK: - 2. Banner de Doble Estado (Servidor Local + Contenedor Free Fire)
    private var dualStatusBanner: some View {
        VStack(spacing: 10) {
            // Estado 1: Servidor Local
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(containerManager.isServerConnected ? PixelTheme.accentMint : PixelTheme.dangerRed)
                        .frame(width: 8, height: 8)
                    Text("SERVIDOR LOCAL:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.chromeMuted)
                }
                Spacer()
                Text(containerManager.isServerConnected ? "192.168.1.15:8888 (ONLINE)" : "DESCONECTADO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(containerManager.isServerConnected ? PixelTheme.accentMint : PixelTheme.dangerRed)
            }
            
            Divider().background(PixelTheme.cardBorder)
            
            // Estado 2: Contenedor Free Fire
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(containerManager.isContainerConnected ? PixelTheme.accentMint : PixelTheme.dangerRed)
                        .frame(width: 8, height: 8)
                    Text("FREE FIRE:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.chromeMuted)
                }
                Spacer()
                Text(containerManager.isContainerConnected ? "CONTENEDOR ENLAZADO" : "SIN ACCESO (ABRE EL JUEGO)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(containerManager.isContainerConnected ? PixelTheme.accentMint : PixelTheme.dangerRed)
            }
        }
        .padding(16)
        .pixelCardStyle()
    }
    
    // MARK: - 3. Selector de Categorías
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ModCategory.allCases) { cat in
                    Button(action: {
                        selectedCategory = cat
                    }) {
                        Text(cat.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? PixelTheme.chromeWhite : PixelTheme.cardBg)
                            .foregroundColor(selectedCategory == cat ? .black : PixelTheme.chromeSilver)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(PixelTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 4. Lista de Mods
    private var modsListView: some View {
        VStack(spacing: 14) {
            ForEach(filteredMods) { mod in
                modCardView(for: mod)
            }
        }
    }
    
    private func modCardView(for mod: ModItemInfo) -> some View {
        let isActive = store.isModActive(mod)
        let isInjectingThis = store.injectingModId == mod.id
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: mod.iconSystemName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? PixelTheme.accentMint : PixelTheme.chromeWhite)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mod.uiName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PixelTheme.chromeWhite)
                    
                    Text(mod.description)
                        .font(.system(size: 11))
                        .foregroundColor(PixelTheme.chromeSilver)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(mod.badgeText)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(mod.isRestoreAction ? PixelTheme.chromeWhite : Color.white.opacity(0.08))
                    .foregroundColor(mod.isRestoreAction ? .black : PixelTheme.chromeSilver)
                    .cornerRadius(6)
            }
            
            Text(mod.targetRelativePath)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(PixelTheme.chromeMuted)
                .lineLimit(1)
                .padding(6)
                .background(Color.white.opacity(0.02))
                .cornerRadius(6)
            
            if isInjectingThis {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: Double(store.injectionProgress), total: 1.0)
                        .accentColor(PixelTheme.chromeWhite)
                    Text(store.statusMessage)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(PixelTheme.chromeSilver)
                }
            } else {
                Button(action: {
                    store.applyMod(mod)
                }) {
                    HStack {
                        Spacer()
                        Text(isActive ? "MOD ACTIVO (RE-APLICAR)" : (mod.isRestoreAction ? "RESTAURAR ORIGINAL" : "APLICAR MOD"))
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(0.5)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(isActive ? PixelTheme.accentMint.opacity(0.15) : (mod.isRestoreAction ? PixelTheme.chromeWhite : Color.white.opacity(0.06)))
                    .foregroundColor(isActive ? PixelTheme.accentMint : (mod.isRestoreAction ? .black : PixelTheme.chromeWhite))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive ? PixelTheme.accentMint.opacity(0.4) : PixelTheme.cardBorder, lineWidth: 1)
                    )
                }
                .disabled(store.injectingModId != nil)
            }
        }
        .padding(18)
        .pixelCardStyle()
    }
    
    // MARK: - 5. Botón de Pánico
    private var panicRestoreSection: some View {
        Button(action: {
            store.panicRestoreAll()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 16))
                
                Text(store.isRestoringAll ? "RESTAURANDO TODO..." : "BOTÓN DE PÁNICO // RESTAURAR JUEGO 100% LIMPIO")
                    .font(.system(size: 12, weight: .black))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(PixelTheme.dangerRed.opacity(0.18))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(PixelTheme.dangerRed.opacity(0.5), lineWidth: 1))
        }
        .disabled(store.isRestoringAll)
        .padding(.top, 10)
    }
}
