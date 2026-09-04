//
//  SettingsView.swift
//  PixelV2
//
//  Settings, local server configuration and digital signature diagnostics.
//  Gaara Quantum Studio
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var containerManager = ContainerManager.shared
    @ObservedObject var keyManager = KeyManager.shared
    
    @State private var serverInput: String = ""
    @State private var testResult: String? = nil
    @State private var isTesting: Bool = false
    
    var body: some View {
        ZStack {
            PixelTheme.canvas.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    headerView
                    
                    serverConfigCard
                    
                    digitalCertCard
                    
                    licenseCard
                    
                    containerDiagnosticsCard
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .onAppear {
            serverInput = containerManager.currentServerUrl
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AJUSTES // CONFIGURACIÓN")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(PixelTheme.chromeMuted)
                
                Text("Centro de Control")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(PixelTheme.chromeWhite)
            }
            Spacer()
        }
        .padding(.top, 6)
    }
    
    private var serverConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SERVIDOR LOCAL DE PAYLOADS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PixelTheme.chromeWhite)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("DIRECCIÓN DEL NODO (IP Y PUERTO):")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PixelTheme.chromeMuted)
                
                HStack {
                    TextField("http://192.168.1.15:8888", text: $serverInput)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(PixelTheme.chromeWhite)
                        .padding(10)
                        .background(PixelTheme.canvas)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PixelTheme.cardBorder, lineWidth: 1))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        containerManager.currentServerUrl = serverInput
                        isTesting = true
                        containerManager.checkServerHealth { online in
                            isTesting = false
                            testResult = online ? "✓ Conexión exitosa (200 OK)" : "✕ Servidor no responde"
                        }
                    }) {
                        Text(isTesting ? "PROBANDO..." : "PROBAR")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(PixelTheme.chromeWhite)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                }
                
                if let res = testResult {
                    Text(res)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(res.contains("✓") ? PixelTheme.accentMint : PixelTheme.dangerRed)
                        .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .pixelCardStyle()
    }
    
    private var digitalCertCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(PixelTheme.chromeWhite)
                Text("CERTIFICACIÓN CRIPTOGRÁFICA")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PixelTheme.chromeWhite)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Equipo / Team:")
                        .font(.system(size: 11))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Spacer()
                    Text(keyManager.certTeamName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.chromeWhite)
                }
                
                HStack {
                    Text("Vigencia Certificado:")
                        .font(.system(size: 11))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Spacer()
                    Text(keyManager.certExpiryDateStr)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.accentMint)
                }
                
                HStack {
                    Text("UDID Vinculado:")
                        .font(.system(size: 11))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Spacer()
                    Text(keyManager.deviceUDID)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(PixelTheme.chromeSilver)
                        .lineLimit(1)
                }
            }
        }
        .padding(18)
        .pixelCardStyle()
    }
    
    private var licenseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ESTADO DE LICENCIA")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PixelTheme.chromeWhite)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Clave Activa:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Spacer()
                    Text(keyManager.activeKey.isEmpty ? "No activa" : keyManager.activeKey)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(PixelTheme.chromeWhite)
                }
                
                HStack {
                    Text("Tiempo Restante:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PixelTheme.chromeMuted)
                    Spacer()
                    Text(keyManager.expirationDateStr)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PixelTheme.accentMint)
                }
            }
            
            Button(action: {
                keyManager.logout()
            }) {
                Text("DESACTIVAR LICENCIA Y CERRAR SESIÓN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(PixelTheme.dangerRed)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(PixelTheme.dangerRed.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(18)
        .pixelCardStyle()
    }
    
    private var containerDiagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DIAGNÓSTICO DEL CONTENEDOR")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PixelTheme.chromeWhite)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Target Bundle ID: com.dts.freefireth")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(PixelTheme.chromeSilver)
                
                Text(containerManager.containerPath ?? "Ruta no enlazada")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(PixelTheme.chromeMuted)
                    .lineLimit(2)
            }
            
            Button(action: {
                containerManager.detectAndActivate()
            }) {
                HStack {
                    Spacer()
                    Text(containerManager.isConnecting ? "ESCANEANDO..." : "RE-ESCANEAR CONTENEDOR")
                        .font(.system(size: 11, weight: .bold))
                    Spacer()
                }
                .padding(10)
                .background(Color.white.opacity(0.06))
                .foregroundColor(PixelTheme.chromeWhite)
                .cornerRadius(8)
            }
        }
        .padding(18)
        .pixelCardStyle()
    }
}
