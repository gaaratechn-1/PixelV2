//
//  ModEngine.swift
//  PixelV2
//
//  Data model and injection coordinator for the 7 official Free Fire modifications.
//  Gaara Quantum Studio
//

import Foundation

enum ModCategory: String, CaseIterable, Identifiable {
    case all = "Todos (7)"
    case combat = "Combate"
    case visual = "Visuales"
    case performance = "Rendimiento"
    case restore = "Restauradores"
    
    var id: String { rawValue }
}

struct ModItemInfo: Identifiable, Equatable {
    let id: String
    let number: Int
    let uiName: String
    let alias: String
    let category: ModCategory
    let badgeText: String
    let description: String
    let targetRelativePath: String
    let isRestoreAction: Bool
    let iconSystemName: String
}

final class ModEngine {
    static let shared = ModEngine()
    
    let allMods: [ModItemInfo] = [
        ModItemInfo(
            id: "01_aim_cuello_98",
            number: 1,
            uiName: "Aim Cuello 98%",
            alias: "aim_cuello_98",
            category: .combat,
            badgeText: "HIGH INTENSITY",
            description: "Hitbox magnético crítico fijado al cuello/cabeza (98% precisión).",
            targetRelativePath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.H5ak1JM1Eck",
            isRestoreAction: false,
            iconSystemName: "scope"
        ),
        ModItemInfo(
            id: "02_holograma",
            number: 2,
            uiName: "Holograma Metal (Chams)",
            alias: "holograma",
            category: .visual,
            badgeText: "ESP VISUAL",
            description: "Visión total a través de muros mediante sombreadores Metal sin prueba de profundidad.",
            targetRelativePath: "Documents/contentcache/Optional/ios/gameassetbundles/shaders.HPt9DZviTSXL9hpGW9QNOMigNLA",
            isRestoreAction: false,
            iconSystemName: "eye.fill"
        ),
        ModItemInfo(
            id: "03_aim_pecho_disimulado",
            number: 3,
            uiName: "Aim Pecho Disimulado",
            alias: "aim_pecho_disimulado",
            category: .combat,
            badgeText: "STEALTH AIM",
            description: "Atracción legítima disimulada hacia el torso para evitar reportes de espectadores.",
            targetRelativePath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.H5ak1JM1Eck",
            isRestoreAction: false,
            iconSystemName: "shield.checkerboard"
        ),
        ModItemInfo(
            id: "04_cuello_68",
            number: 4,
            uiName: "Cuello 68% (Equilibrado)",
            alias: "cuello_68",
            category: .combat,
            badgeText: "BALANCED",
            description: "Magnetismo moderado y natural para juego competitivo.",
            targetRelativePath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.H5ak1JM1Eck",
            isRestoreAction: false,
            iconSystemName: "cross.circle.fill"
        ),
        ModItemInfo(
            id: "05_unlock_144_fps",
            number: 5,
            uiName: "Desbloqueo 144 FPS",
            alias: "unlock_144_fps",
            category: .performance,
            badgeText: "ULTRA SMOOTH",
            description: "Modificación del archivo de preferencias para desbloquear alta tasa de cuadros.",
            targetRelativePath: "Library/Preferences/com.dts.freefireth.plist",
            isRestoreAction: false,
            iconSystemName: "bolt.fill"
        ),
        ModItemInfo(
            id: "06_desactivar_aimbot",
            number: 6,
            uiName: "Restaurar Aim Limpio",
            alias: "restore_aimbot",
            category: .restore,
            badgeText: "CLEAN RESTORE",
            description: "Restaura el assetindexer oficial original de Garena, devolviendo el avatar al estado limpio.",
            targetRelativePath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.H5ak1JM1Eck",
            isRestoreAction: true,
            iconSystemName: "arrow.counterclockwise.circle"
        ),
        ModItemInfo(
            id: "07_desactivar_holograma",
            number: 7,
            uiName: "Restaurar Holograma Limpio",
            alias: "restore_holograma",
            category: .restore,
            badgeText: "CLEAN RESTORE",
            description: "Restaura los sombreadores Metal originales de fábrica sin efectos visuales.",
            targetRelativePath: "Documents/contentcache/Optional/ios/gameassetbundles/shaders.HPt9DZviTSXL9hpGW9QNOMigNLA",
            isRestoreAction: true,
            iconSystemName: "arrow.counterclockwise.circle.fill"
        )
    ]
    
    func inject(mod: ModItemInfo, progress: ((Float) -> Void)? = nil, completion: @escaping (Bool, String) -> Void) {
        InjectionEngine.shared().injectMod(
            withAlias: mod.alias,
            targetRelativePath: mod.targetRelativePath,
            progress: progress != nil ? { p in progress?(p) } : nil
        ) { success, message in
            completion(success, message)
        }
    }
}
