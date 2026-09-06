//
//  ModStateStore.swift
//  PixelV2
//
//  Reactive UI state store, active mod tracking, dynamic OTA catalog coordinator and panic restore.
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
    @Published var availableCategories: [ModCategory] = [.all]
    
    // --- 5.1 Laboratorio Experimental: Calibración Dinámica de Aimbot (50% - 100%) ---
    @Published var dynamicPrecision: Double = 88.0
    @Published var isInjectingDynamicAim: Bool = false
    @Published var dynamicAimStatusMessage: String = "Precisión lista (88%)"
    
    let engine = ModEngine.shared
    let containerManager = ContainerManager.shared
    let keyManager = KeyManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        if let savedActive = UserDefaults.standard.array(forKey: "pixelv2_active_mods") as? [String] {
            self.activeModIds = Set(savedActive)
        }
        
        // Observar cambios en el catálogo de ModEngine para actualizar las categorías dinámicas
        engine.$allMods
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAvailableCategories()
            }
            .store(in: &cancellables)
            
        updateAvailableCategories()
        
        // Sincronizar catálogo con el servidor en segundo plano
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshCatalog()
        }
    }
    
    /// Actualiza la lista de categorías visibles basada en los mods registrados
    func updateAvailableCategories() {
        var set: Set<ModCategory> = []
        for m in engine.allMods {
            set.insert(m.category)
        }
        
        var ordered: [ModCategory] = [.all]
        for cat in [ModCategory.pruebas, ModCategory.combat, ModCategory.visual, ModCategory.performance, ModCategory.restore] {
            if set.contains(cat) {
                ordered.append(cat)
                set.remove(cat)
            }
        }
        for remaining in set where remaining != .all {
            ordered.append(remaining)
        }
        self.availableCategories = ordered
    }
    
    /// Sincroniza el catálogo en vivo desde el servidor
    func refreshCatalog(completion: ((Bool, String) -> Void)? = nil) {
        engine.fetchRemoteCatalog(serverBaseUrl: containerManager.currentServerUrl) { success, msg in
            DispatchQueue.main.async {
                if success {
                    self.statusMessage = msg
                }
                completion?(success, msg)
            }
        }
    }
    
    /// Versión asíncrona para soportar pull-to-refresh en SwiftUI (.refreshable)
    @MainActor
    func refreshCatalogAsync() async {
        await withCheckedContinuation { continuation in
            self.refreshCatalog { _, _ in
                continuation.resume()
            }
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
                        // Si es restauración, desmarcar mods de esa categoría o alias
                        if mod.alias.contains("aim") || mod.category == .combat {
                            let combatIds = self.engine.allMods.filter { $0.category == .combat }.map { $0.id }
                            for cid in combatIds { self.activeModIds.remove(cid) }
                        } else if mod.alias.contains("holo") || mod.category == .visual {
                            let visualIds = self.engine.allMods.filter { $0.category == .visual }.map { $0.id }
                            for vid in visualIds { self.activeModIds.remove(vid) }
                        }
                    } else {
                        // Si es un mod de combate, reemplazar otros de combate para evitar solapamientos
                        if mod.category == .combat {
                            let combatIds = self.engine.allMods.filter { $0.category == .combat }.map { $0.id }
                            for cid in combatIds { self.activeModIds.remove(cid) }
                        }
                        self.activeModIds.insert(mod.id)
                    }
                    UserDefaults.standard.set(Array(self.activeModIds), forKey: "pixelv2_active_mods")
                    self.statusMessage = "✓ \(mod.uiName) aplicado con éxito"
                    
                    let restartPrompt = mod.isRestoreAction ? 
                        "✓ Archivo original de Garena restaurado en el almacenamiento.\n\nEl juego está 100% limpio en disco y protegido contra escaneos de inicio." :
                        "✓ Mod inyectado en el contenedor con éxito.\n\n🛡️ PROTOCOLO SEGURO (RAM HOT-SWAP):\n\n1. Entra a Free Fire y accede al Lobby.\n2. Espera 10 segundos en el Lobby (los assets se deserializan y quedan fijados en la memoria RAM).\n3. Abre PixelV2 y pulsa 'RESTAURAR ORIGINAL' o 'DESACTIVAR'.\n4. Regresa a Free Fire y juega con total normalidad.\n\nAl restaurar, el archivo en disco vuelve a ser el oficial de Garena y los escaneos de integridad no detectarán ninguna anomalía mientras el mod sigue activo en memoria."
                    self.presentAlert(title: "Inyección Exitosa", message: restartPrompt)
                    
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
    
    /// Botón de Pánico: Restaura todos los archivos limpios originales de Garena dinámicamente
    func panicRestoreAll() {
        guard !isRestoringAll else { return }
        isRestoringAll = true
        statusMessage = "Restaurando juego a estado de fábrica..."
        
        // Obtener todos los mods marcados como restauración
        var restoreMods = engine.allMods.filter { $0.isRestoreAction }
        if restoreMods.isEmpty {
            restoreMods = ModEngine.defaultMods.filter { $0.isRestoreAction }
        }
        
        guard !restoreMods.isEmpty else {
            self.isRestoringAll = false
            self.presentAlert(title: "Sin Mods de Restauración", message: "No se encontraron payloads de restauración registrados.")
            return
        }
        
        // Ejecutar restauraciones en cadena sin forzar desempaquetados
        func runRestoreSequence(index: Int, errors: [String]) {
            if index >= restoreMods.count {
                DispatchQueue.main.async {
                    self.isRestoringAll = false
                    self.activeModIds.removeAll()
                    UserDefaults.standard.removeObject(forKey: "pixelv2_active_mods")
                    
                    if errors.isEmpty {
                        self.statusMessage = "✓ Juego 100% limpio y restaurado"
                        self.presentAlert(title: "Restauración Completa", message: "Todos los sombreadores y assets de combate han sido reemplazados por las versiones originales oficiales de Garena.")
                    } else {
                        self.presentAlert(title: "Restauración Parcial", message: errors.joined(separator: "\n"))
                    }
                }
                return
            }
            
            let currentMod = restoreMods[index]
            self.engine.inject(mod: currentMod) { success, msg in
                var newErrors = errors
                if !success {
                    newErrors.append("• \(currentMod.uiName): \(msg)")
                }
                runRestoreSequence(index: index + 1, errors: newErrors)
            }
        }
        
        runRestoreSequence(index: 0, errors: [])
    }
    
    /// Calibra dinámicamente y descarga en tiempo real el assetindexer con el radio de CapsuleCollider seleccionado
    func applyDynamicAim(precision: Int) {
        guard keyManager.isAuthorized else {
            presentAlert(title: "Licencia Requerida", message: "Debes activar una clave de licencia válida antes de aplicar modificaciones.")
            return
        }
        
        isInjectingDynamicAim = true
        dynamicAimStatusMessage = "Generando asset binario calibrado al \(precision)%..."
        
        InjectionEngine.shared().injectDynamicAim(withPrecision: precision, progress: { [weak self] p in
            DispatchQueue.main.async {
                if p >= 0.7 {
                    self?.dynamicAimStatusMessage = "Inyectando en avatar/assetindexer (\(Int(p * 100))%)..."
                }
            }
        }) { [weak self] success, message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isInjectingDynamicAim = false
                self.dynamicAimStatusMessage = success ? "✓ Aimbot \(precision)% Activo" : "Error en inyección"
                self.presentAlert(
                    title: success ? "Laboratorio // Inyección Exitosa" : "Fallo de Calibración",
                    message: message
                )
            }
        }
    }
}
