//
//  KeyAuthView.swift
//  PixelV2
//
//  License activation screen with digital signature certification display.
//  Gaara Quantum Studio
//

import SwiftUI

struct KeyAuthView: View {
    @ObservedObject var keyManager = KeyManager.shared
    @ObservedObject var containerManager = ContainerManager.shared
    
    @State private var inputKey: String = ""
    @State private var statusAlert: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            PixelTheme.canvas.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)
                    
                    // Logotipo Pixel y Marca
                    VStack(spacing: 12) {
                        PixelLogoView(size: 72, showGlow: true)
                        
                        Text("PIXEL V2")
                            .font(.system(size: 26, weight: .black))
                            .tracking(2)
                            .foregroundColor(PixelTheme.chromeWhite)
                        
                        Text("INJECTION SUITE // FIRMA CERTIFICADA")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(PixelTheme.chromeMuted)
                    }
                    
                    // Indicador de Servidor Local
                    HStack(spacing: 8) {
                        Circle()
                            .fill(containerManager.isServerConnected ? PixelTheme.accentMint : PixelTheme.dangerRed)
                            .frame(width: 8, height: 8)
                        
                        Text(containerManager.isServerConnected ? "SERVIDOR LOCAL CONECTADO (192.168.1.15:8888)" : "SERVIDOR LOCAL NO DETECTADO")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(PixelTheme.chromeWhite)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(PixelTheme.cardBg)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(PixelTheme.cardBorder, lineWidth: 1))
                    
                    // Tarjeta de Ingreso de Clave
                    VStack(alignment: .leading, spacing: 18) {
                        Text("ACTIVACIÓN DE LICENCIA")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                            .foregroundColor(PixelTheme.chromeWhite)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CLAVE VINCULADA A TU FIRMA DIGITAL:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(PixelTheme.chromeMuted)
                            
                            TextField("PIXEL-XXXX-XXXX-XXXX", text: $inputKey)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(PixelTheme.chromeWhite)
                                .padding(14)
                                .background(PixelTheme.canvas)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(PixelTheme.cardBorder, lineWidth: 1))
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                        }
                        
                        // Botón de Verificación
                        Button(action: {
                            keyManager.validateKey(inputKey) { success, msg in
                                if !success {
                                    self.statusAlert = msg
                                    self.showAlert = true
                                }
                            }
                        }) {
                            HStack {
                                if keyManager.isValidating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .padding(.trailing, 6)
                                }
                                Text(keyManager.isValidating ? "VERIFICANDO CON SERVIDOR..." : "ACTIVAR LICENCIA")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(PixelTheme.chromeWhite)
                            .cornerRadius(12)
                        }
                        .disabled(keyManager.isValidating || inputKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        // Opción de Modo Autónomo Local
                        Button(action: {
                            keyManager.validateKey("AUTONOMOUS") { success, msg in
                                if !success {
                                    self.statusAlert = msg
                                    self.showAlert = true
                                }
                            }
                        }) {
                            Text("ACCEDER EN MODO AUTÓNOMO LOCAL")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(PixelTheme.chromeSilver)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(PixelTheme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(24)
                    .pixelCardStyle()
                    
                    // Tarjeta de Certificación y UDID
                    VStack(alignment: .leading, spacing: 10) {
                        Text("IDENTIFICADOR DEL DISPOSITIVO (UDID):")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(PixelTheme.chromeMuted)
                        
                        Button(action: {
                            UIPasteboard.general.string = keyManager.deviceUDID
                            let haptic = UINotificationFeedbackGenerator()
                            haptic.notificationOccurred(.success)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(PixelTheme.chromeWhite)
                                
                                Text(keyManager.deviceUDID)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(PixelTheme.chromeSilver)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundColor(PixelTheme.chromeWhite)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Validación de Licencia"),
                message: Text(statusAlert ?? "Error"),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }
}
