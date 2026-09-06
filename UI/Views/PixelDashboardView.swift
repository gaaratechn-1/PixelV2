//
//  PixelDashboardView.swift
//  PixelV2
//
//  Master Dashboard with digital signature telemetry, dynamic live OTA catalog, and panic restore.
//  Gaara Quantum Studio
//

import SwiftUI

struct PixelDashboardView: View {
    @ObservedObject var store = ModStateStore.shared
    @ObservedObject var containerManager = ContainerManager.shared
    @ObservedObject var keyManager = KeyManager.shared
    
    @State private var selectedCategory: ModCategory = .all
    @State private var showProtocolGuide: Bool = false
    @State private var showLaboratory: Bool = false
    
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
                    
                    safeInjectionProtocolCard
                    
                    categoryFilterBar
                    
                    modsListView
                    
                    panicRestoreSection
                    
                    laboratoryDynamicAimSection
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .refreshable {
                await store.refreshCatalogAsync()
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
    
    // MARK: - 1. Encabezado Superior con Sincronización OTA
    private var headerView: some View {
        HStack(spacing: 14) {
            PixelLogoView(size: 46, showGlow: false)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("NODO LOCAL // ACTIVO")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1)
                        .foregroundColor(PixelTheme.chromeMuted)
                    
                    if store.engine.isSyncing {
                        Text("• SINCRONIZANDO")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(PixelTheme.accentMint)
                    }
                }
                
                Text("PixelV2 Suite")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(PixelTheme.chromeWhite)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    store.refreshCatalog()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(store.engine.isSyncing ? PixelTheme.accentMint : PixelTheme.chromeSilver)
                        .padding(10)
                        .background(PixelTheme.cardBg)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(PixelTheme.cardBorder, lineWidth: 1))
                }
                .disabled(store.engine.isSyncing)
                
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
    
    // MARK: - 2. Banner de Estado (Servidor Local, Contenedor y Catálogo OTA)
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
            
            Divider().background(PixelTheme.cardBorder)
            
            // Estado 3: Catálogo Dinámico OTA
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(store.engine.allMods.count > 0 ? PixelTheme.accentMint : PixelTheme.dangerRed)
                        .frame(width: 8, height: 8)
                    Text("CATÁLOGO OTA:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.chromeMuted)
                }
                Spacer()
                Text("\(store.engine.allMods.count) MODS DISPONIBLES")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(PixelTheme.chromeWhite)
            }
        }
        .padding(16)
        .pixelCardStyle()
    }
    
    // MARK: - 2.1 Protocolo Seguro Anti-Ban (RAM Hot-Swap)
    private var safeInjectionProtocolCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showProtocolGuide.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(PixelTheme.accentMint)
                    
                    Text("PROTOCOLO ANTI-BAN (HOT-SWAP)")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(PixelTheme.chromeWhite)
                    
                    Spacer()
                    
                    Text(showProtocolGuide ? "OCULTAR" : "VER PASOS")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(PixelTheme.chromeSilver)
                        .cornerRadius(6)
                    
                    Image(systemName: showProtocolGuide ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(PixelTheme.chromeMuted)
                }
            }
            
            if showProtocolGuide {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(PixelTheme.cardBorder)
                    
                    protocolStepRow(num: "1", title: "Pantalla de Login / Lobby:", desc: "Abre Free Fire y quédate en el inicio de sesión o accede hasta el Lobby.")
                    protocolStepRow(num: "2", title: "Aplica el Mod en PixelV2:", desc: "Selecciona el mod nativo y pulsa 'Aplicar Mod'.")
                    protocolStepRow(num: "3", title: "Carga en Memoria RAM (10s):", desc: "Regresa al Lobby y espera 10 segundos para que Unity instancie los recursos en RAM.")
                    protocolStepRow(num: "4", title: "Restaura el Disco Limpio:", desc: "Abre PixelV2 y pulsa 'Restaurar Original'. El juego queda limpio en disco y activo en RAM.")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(showProtocolGuide ? PixelTheme.accentMint.opacity(0.35) : PixelTheme.cardBorder, lineWidth: 1))
    }
    
    private func protocolStepRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.black)
                .frame(width: 18, height: 18)
                .background(PixelTheme.accentMint)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(PixelTheme.chromeWhite)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(PixelTheme.chromeMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - 3. Selector Dinámico de Categorías
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.availableCategories) { cat in
                    let isSelected = selectedCategory == cat
                    let count = cat == .all ? store.engine.allMods.count : store.engine.allMods.filter { $0.category == cat }.count
                    
                    Button(action: {
                        selectedCategory = cat
                    }) {
                        HStack(spacing: 6) {
                            Text(cat.displayName)
                                .font(.system(size: 12, weight: .bold))
                            
                            Text("\(count)")
                                .font(.system(size: 10, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSelected ? Color.black.opacity(0.2) : Color.white.opacity(0.08))
                                .foregroundColor(isSelected ? .black : PixelTheme.chromeMuted)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? PixelTheme.chromeWhite : PixelTheme.cardBg)
                        .foregroundColor(isSelected ? .black : PixelTheme.chromeSilver)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? PixelTheme.chromeWhite : PixelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 4. Lista Dinámica de Mods
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
    
    // MARK: - 6. Laboratorio Experimental: Calibración Dinámica de Aimbot (50% - 100%)
    private var laboratoryDynamicAimSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showLaboratory.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.below.rectangle")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(PixelTheme.accentMint)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("LABORATORIO // PRECISIÓN DINÁMICA")
                                .font(.system(size: 11, weight: .black))
                                .tracking(1)
                                .foregroundColor(PixelTheme.chromeWhite)
                            
                            Text("EXPERIMENTAL")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(PixelTheme.accentMint.opacity(0.15))
                                .foregroundColor(PixelTheme.accentMint)
                                .cornerRadius(4)
                        }
                        
                        Text("Calibrador milimétrico de radio CapsuleCollider (50% - 100%)")
                            .font(.system(size: 10))
                            .foregroundColor(PixelTheme.chromeMuted)
                    }
                    
                    Spacer()
                    
                    Text(showLaboratory ? "OCULTAR" : "CALIBRAR")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(PixelTheme.chromeSilver)
                        .cornerRadius(6)
                    
                    Image(systemName: showLaboratory ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(PixelTheme.chromeMuted)
                }
            }
            
            if showLaboratory {
                VStack(alignment: .leading, spacing: 16) {
                    Divider().background(PixelTheme.cardBorder)
                    
                    // Indicador Central de Nivel de Calibración
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INTENSIDAD DE MAGNETISMO:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(PixelTheme.chromeMuted)
                            
                            Text("\(Int(store.dynamicPrecision))% PRECISIÓN")
                                .font(.system(size: 22, weight: .black, design: .monospaced))
                                .foregroundColor(dynamicPrecisionColor)
                        }
                        
                        Spacer()
                        
                        Text(dynamicPrecisionLabel)
                            .font(.system(size: 9, weight: .black))
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(dynamicPrecisionColor.opacity(0.15))
                            .foregroundColor(dynamicPrecisionColor)
                            .cornerRadius(8)
                    }
                    
                    // Slider Deslizante
                    VStack(spacing: 6) {
                        Slider(value: $store.dynamicPrecision, in: 50...100, step: 1)
                            .accentColor(dynamicPrecisionColor)
                        
                        HStack {
                            Text("50% Disimulado")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(PixelTheme.chromeMuted)
                            Spacer()
                            Text("75% Equilibrado")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(PixelTheme.chromeMuted)
                            Spacer()
                            Text("100% Agresivo")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(PixelTheme.chromeMuted)
                        }
                    }
                    
                    // Telemetría en Tiempo Real del Collider
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Radio Cápsula:")
                                .font(.system(size: 9))
                                .foregroundColor(PixelTheme.chromeMuted)
                            Text(String(format: "%.2fx", 1.0 + (store.dynamicPrecision - 50.0) * 0.016))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(PixelTheme.chromeWhite)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zona Objetivo:")
                                .font(.system(size: 9))
                                .foregroundColor(PixelTheme.chromeMuted)
                            Text(dynamicTargetBone)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(PixelTheme.chromeWhite)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Riesgo:")
                                .font(.system(size: 9))
                                .foregroundColor(PixelTheme.chromeMuted)
                            Text(dynamicRiskLevel)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(dynamicPrecisionColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                    }
                    
                    // Botón de Inyección Dinámica
                    Button(action: {
                        store.applyDynamicAim(precision: Int(store.dynamicPrecision))
                    }) {
                        HStack(spacing: 8) {
                            if store.isInjectingDynamicAim {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bolt.badge.clock.fill")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            
                            Text(store.isInjectingDynamicAim ? store.dynamicAimStatusMessage : "GENERAR & INYECTAR CALIBRACIÓN AL \(Int(store.dynamicPrecision))%")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(store.isInjectingDynamicAim ? Color.white.opacity(0.4) : dynamicPrecisionColor)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .disabled(store.isInjectingDynamicAim)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(showLaboratory ? PixelTheme.accentMint.opacity(0.4) : PixelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private var dynamicPrecisionColor: Color {
        if store.dynamicPrecision < 65 {
            return PixelTheme.accentMint
        } else if store.dynamicPrecision < 85 {
            return PixelTheme.chromeWhite
        } else if store.dynamicPrecision < 98 {
            return Color(red: 1.0, green: 0.75, blue: 0.2)
        } else {
            return PixelTheme.dangerRed
        }
    }
    
    private var dynamicPrecisionLabel: String {
        if store.dynamicPrecision < 65 {
            return "DISIMULADO\n(PECHO / DISCRETO)"
        } else if store.dynamicPrecision < 85 {
            return "EQUILIBRADO\n(CUELLO MEDIO)"
        } else if store.dynamicPrecision < 98 {
            return "AGRESIVO\n(CUELLO-CABEZA)"
        } else {
            return "EXTREMO 100%\n(AUTO-HEADSHOT)"
        }
    }
    
    private var dynamicTargetBone: String {
        if store.dynamicPrecision < 65 {
            return "bone_Spine2"
        } else if store.dynamicPrecision < 85 {
            return "bone_Neck"
        } else {
            return "bone_Head"
        }
    }
    
    private var dynamicRiskLevel: String {
        if store.dynamicPrecision < 65 {
            return "Bajo (Anti-Ban)"
        } else if store.dynamicPrecision < 85 {
            return "Medio"
        } else if store.dynamicPrecision < 98 {
            return "Moderado"
        } else {
            return "Alto (Extremo)"
        }
    }
}
