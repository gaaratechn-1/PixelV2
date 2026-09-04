//
//  ModStateStore.swift
//  PixelV2
//
//  Reactive UI state store, active mod tracking and panic restore handler.
//  Gaara Quantum Studio
//

import Foundation
import SwiftUI
import Combine

final class ModStateStore: ObservableObject {
    static let shared = ModStateStore()
    
    @Published var activeModIds: Set<String> = []
    @Published var injectingModId: String? = nil
    @Published var injectionProgress: Float = 0.0
    @Published var statusMessage: String = "Listo para inyectar"
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isRestoringAll: Bool = false
    
    let engine = ModEngine.shared
    let containerManager = ContainerManager.shared
    let keyManager = KeyManager.shared
    
    private init() {
        if let savedActive = UserDefaults.standard.array(forKey: "pixelv2_active_mods") as? [String] {
            self.activeModIds = Set(savedActive)
        }
    }
    
    func isModActive(_ mod: ModItemInfo) -> Bool {
        activeModIds.contains(mod.id)
    }
    
    func presentAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    func applyMod(_ mod: ModItemInfo) {
        guard keyManager.isAuthorized else {
            presentAlert(title: "Licencia Requerida", message: "Debes activar una clave de licencia válida antes de aplicar modificaciones.")
            return
        }
        
        injectingModId = mod.id
        injectionProgress = 0.1
        statusMessage = "Descargando payload desde servidor local..."
        
        engine.inject(mod: mod, progress: { [weak self] p in
            DispatchQueue.main.async {
                self?.injectionProgress = p
                if p >= 0.7 {
                    self?.statusMessage = "Inyectando en contenedor de Free Fire..."
                }
            }
        }) { [weak self] success, message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.injectingModId = nil
                self.injectionProgress = 0.0
                
                if success {
                    if mod.isRestoreAction {
                        // Si es restauración, desmarcar mods correspondientes
                        if mod.alias == "restore_aimbot" {
                            self.activeModIds.remove("01_aim_cuello_98")
                            self.activeModIds.remove("03_aim_pecho_disimulado")
                            self.activeModIds.remove("04_cuello_68")
                        } else if mod.alias == "restore_holograma" {
                            self.activeModIds.remove("02_holograma")
                        }
                    } else {
                        // Si es un aimbot, reemplazar los otros aimbots activos
                        if mod.category == .combat {
                            self.activeModIds.remove("01_aim_cuello_98")
                            self.activeModIds.remove("03_aim_pecho_disimulado")
                            self.activeModIds.remove("04_cuello_68")
                        }
                        self.activeModIds.insert(mod.id)
                    }
                    
                    UserDefaults.standard.set(Array(self.activeModIds), forKey: "pixelv2_active_mods")
                    self.statusMessage = "✓ \(mod.uiName) aplicado con éxito"
                    
                    // Vibración háptica de éxito
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                } else {
                    self.statusMessage = "Fallo en inyección"
                    self.presentAlert(title: "Error de Inyección", message: message)
                    
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    /// Botón de Pánico: Restaura todos los archivos limpios originales de Garena
    func panicRestoreAll() {
        guard !isRestoringAll else { return }
        isRestoringAll = true
        statusMessage = "Restaurando juego a estado de fábrica..."
        
        let restoreAimMod = engine.allMods.first { $0.alias == "restore_aimbot" }!
        let restoreHoloMod = engine.allMods.first { $0.alias == "restore_holograma" }!
        
        engine.inject(mod: restoreAimMod) { [weak self] success1, msg1 in
            guard let self = self else { return }
            self.engine.inject(mod: restoreHoloMod) { success2, msg2 in
                DispatchQueue.main.async {
                    self.isRestoringAll = false
                    self.activeModIds.removeAll()
                    UserDefaults.standard.removeObject(forKey: "pixelv2_active_mods")
                    
                    if success1 && success2 {
                        self.statusMessage = "✓ Juego 100% limpio y restaurado"
                        self.presentAlert(title: "Restauración Completa", message: "Todos los sombreadores y assets de combate han sido reemplazados por las versiones originales oficiales de Garena.")
                    } else {
                        self.presentAlert(title: "Restauración Parcial", message: "\(msg1)\n\(msg2)")
                    }
                }
            }
        }
    }
}
