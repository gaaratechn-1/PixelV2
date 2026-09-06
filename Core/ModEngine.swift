//
//  ModEngine.swift
//  PixelV2
//
//  Dynamic OTA Mod Registry & Injection Coordinator.
//  Fetches real-time mod catalog from server with offline persistent fallback.
//  Gaara Quantum Studio
//

import Foundation
import Combine

public struct ModCategory: RawRepresentable, Equatable, Hashable, Identifiable, Codable {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }
    
    public var id: String { rawValue }
    
    public static let all = ModCategory("all")
    public static let pruebas = ModCategory("pruebas")
    public static let combat = ModCategory("combat")
    public static let visual = ModCategory("visual")
    public static let performance = ModCategory("performance")
    public static let restore = ModCategory("restore")
    
    public var displayName: String {
        switch rawValue {
        case "all": return "Todos"
        case "pruebas", "testing": return "Pruebas"
        case "combat": return "Combate"
        case "visual": return "Visuales"
        case "performance": return "Rendimiento"
        case "restore": return "Restauradores"
        default: return rawValue.capitalized
        }
    }
    
    public static var defaultCases: [ModCategory] {
        return [.all, .pruebas, .combat, .visual, .performance, .restore]
    }
}

public struct ModItemInfo: Identifiable, Equatable, Codable {
    public let id: String
    public var number: Int
    public var uiName: String
    public var alias: String
    public var category: ModCategory
    public var badgeText: String
    public var description: String
    public var targetDir: String
    public var filePrefix: String
    public var fallbackFilename: String
    public var isRestoreAction: Bool
    public var iconSystemName: String
    public var available: Bool
    public var sizeBytes: Int64
    public var sizeKb: Double
    public var downloadUrl: String?
    
    public var targetRelativePath: String {
        return "\(targetDir)/\(fallbackFilename)"
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case actionId = "action_id"
        case alias
        case uiName = "name"
        case badgeText = "badge"
        case category
        case description
        case filename
        case targetDir = "dir"
        case filePrefix = "prefix"
        case fallbackFilename = "fallback_filename"
        case isRestoreAction = "is_restore"
        case available
        case sizeBytes = "size_bytes"
        case sizeKb = "size_kb"
        case downloadUrl = "download_url"
    }
    
    public init(
        id: String,
        number: Int = 0,
        uiName: String,
        alias: String,
        category: ModCategory,
        badgeText: String,
        description: String,
        targetDir: String,
        filePrefix: String,
        fallbackFilename: String,
        isRestoreAction: Bool,
        iconSystemName: String = "cube.fill",
        available: Bool = true,
        sizeBytes: Int64 = 0,
        sizeKb: Double = 0.0,
        downloadUrl: String? = nil
    ) {
        self.id = id
        self.number = number
        self.uiName = uiName
        self.alias = alias
        self.category = category
        self.badgeText = badgeText
        self.description = description
        self.targetDir = targetDir
        self.filePrefix = filePrefix
        self.fallbackFilename = fallbackFilename
        self.isRestoreAction = isRestoreAction
        self.iconSystemName = iconSystemName
        self.available = available
        self.sizeBytes = sizeBytes
        self.sizeKb = sizeKb
        self.downloadUrl = downloadUrl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.alias = try container.decodeIfPresent(String.self, forKey: .alias) ?? self.id
        self.uiName = try container.decodeIfPresent(String.self, forKey: .uiName) ?? self.id
        self.badgeText = try container.decodeIfPresent(String.self, forKey: .badgeText) ?? "NATIVO"
        
        let catStr = try container.decodeIfPresent(String.self, forKey: .category) ?? "combat"
        self.category = ModCategory(catStr)
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.targetDir = try container.decodeIfPresent(String.self, forKey: .targetDir) ?? "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar"
        self.filePrefix = try container.decodeIfPresent(String.self, forKey: .filePrefix) ?? "assetindexer.H5ak1JM1Eck"
        self.fallbackFilename = try container.decodeIfPresent(String.self, forKey: .fallbackFilename) ?? "assetindexer.H5ak1JM1Eck_7e_2FxRcJrEp_7e_2FMzeuqmY_7e_3D"
        self.isRestoreAction = try container.decodeIfPresent(Bool.self, forKey: .isRestoreAction) ?? false
        self.available = try container.decodeIfPresent(Bool.self, forKey: .available) ?? true
        self.sizeBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeBytes) ?? 0
        self.sizeKb = try container.decodeIfPresent(Double.self, forKey: .sizeKb) ?? (Double(self.sizeBytes) / 1024.0)
        self.downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        self.number = 0
        
        // Inferencia inteligente de íconos según categoría y alias
        if self.isRestoreAction {
            self.iconSystemName = "arrow.counterclockwise.circle.fill"
        } else if self.category == .pruebas {
            if self.alias.contains("head") || self.alias.contains("cabeza") || self.alias.contains("aim") {
                self.iconSystemName = "target"
            } else if self.alias.contains("recoil") || self.alias.contains("weapon") || self.alias.contains("sniper") || self.alias.contains("katana") {
                self.iconSystemName = "flame.fill"
            } else if self.alias.contains("skin") || self.alias.contains("traje") || self.alias.contains("criminal") || self.alias.contains("sakura") {
                self.iconSystemName = "sparkles"
            } else if self.alias.contains("vehiculo") {
                self.iconSystemName = "car.fill"
            } else if self.alias.contains("skill") {
                self.iconSystemName = "bolt.shield.fill"
            } else {
                self.iconSystemName = "flask.fill"
            }
        } else if self.category == .visual || self.alias.contains("holo") || self.alias.contains("shader") {
            self.iconSystemName = "eye.fill"
        } else if self.category == .performance || self.alias.contains("fps") {
            self.iconSystemName = "bolt.fill"
        } else if self.alias.contains("cuello") {
            self.iconSystemName = "scope"
        } else if self.alias.contains("pecho") {
            self.iconSystemName = "shield.checkerboard"
        } else {
            self.iconSystemName = "cross.circle.fill"
        }
    }
}

public final class ModEngine: ObservableObject {
    public static let shared = ModEngine()
    
    private let cacheKey = "pixelv2_dynamic_mods_catalog_v1"
    
    @Published public var allMods: [ModItemInfo] = []
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTime: Date? = nil
    @Published public var syncMessage: String = "Catálogo listo"
    
    public static let defaultMods: [ModItemInfo] = [
        ModItemInfo(
            id: "01_aim_cuello_98",
            number: 1,
            uiName: "Aim Cuello 98%",
            alias: "aim_cuello_98",
            category: .combat,
            badgeText: "NATIVO 2022 // ESTABLE",
            description: "Hitbox magnético crítico fijado al cuello/cabeza (98% precisión). Compilado en Unity 2022.3 oficial.",
            targetDir: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar",
            filePrefix: "assetindexer.H5ak1JM1Eck",
            fallbackFilename: "assetindexer.H5ak1JM1Eck_7e_2FxRcJrEp_7e_2FMzeuqmY_7e_3D",
            isRestoreAction: false,
            iconSystemName: "scope"
        ),
        ModItemInfo(
            id: "02_holograma",
            number: 2,
            uiName: "Holograma Metal (Chams)",
            alias: "holograma",
            category: .visual,
            badgeText: "NATIVO 2022 // ESTABLE",
            description: "Visión total a través de muros con sombreadores Metal (Unity 2022.3 oficial).",
            targetDir: "Documents/contentcache/Optional/ios/gameassetbundles",
            filePrefix: "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA",
            fallbackFilename: "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA_7e_3D",
            isRestoreAction: false,
            iconSystemName: "eye.fill"
        ),
        ModItemInfo(
            id: "03_aim_pecho_disimulado",
            number: 3,
            uiName: "Aim Pecho Disimulado",
            alias: "aim_pecho_disimulado",
            category: .combat,
            badgeText: "LEGACY 2018 // RIESGO",
            description: "Atracción disimulada al torso (Compilado en Unity 2018 legacy, posible reporte de motor).",
            targetDir: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar",
            filePrefix: "assetindexer.H5ak1JM1Eck",
            fallbackFilename: "assetindexer.H5ak1JM1Eck_7e_2FxRcJrEp_7e_2FMzeuqmY_7e_3D",
            isRestoreAction: false,
            iconSystemName: "shield.checkerboard"
        ),
        ModItemInfo(
            id: "04_cuello_68",
            number: 4,
            uiName: "Cuello 68% (Equilibrado)",
            alias: "cuello_68",
            category: .combat,
            badgeText: "LEGACY 2018 // RIESGO",
            description: "Magnetismo moderado (Compilado en Unity 2018 legacy, usar con precaución).",
            targetDir: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar",
            filePrefix: "assetindexer.H5ak1JM1Eck",
            fallbackFilename: "assetindexer.H5ak1JM1Eck_7e_2FxRcJrEp_7e_2FMzeuqmY_7e_3D",
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
            targetDir: "Library/Preferences",
            filePrefix: "com.dts.freefireth.plist",
            fallbackFilename: "com.dts.freefireth.plist",
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
            targetDir: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar",
            filePrefix: "assetindexer.H5ak1JM1Eck",
            fallbackFilename: "assetindexer.H5ak1JM1Eck_7e_2FxRcJrEp_7e_2FMzeuqmY_7e_3D",
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
            targetDir: "Documents/contentcache/Optional/ios/gameassetbundles",
            filePrefix: "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA",
            fallbackFilename: "shaders.HPt9DZviTSXL9hpGW9QNOMigNLA_7e_3D",
            isRestoreAction: true,
            iconSystemName: "arrow.counterclockwise.circle.fill"
        )
    ]
    
    private init() {
        loadCachedCatalog()
    }
    
    /// Carga el catálogo guardado en disco o inicializa con los 7 predeterminados
    private func loadCachedCatalog() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([ModItemInfo].self, from: data),
           !cached.isEmpty {
            self.allMods = cached
            self.syncMessage = "Catálogo cargado desde caché (\(cached.count) mods)"
        } else {
            self.allMods = ModEngine.defaultMods
            self.syncMessage = "Catálogo base listo (7 mods oficiales)"
        }
    }
    
    /// Sincroniza dinámicamente el catálogo desde el servidor '/api/v1/mods/catalog'
    public func fetchRemoteCatalog(serverBaseUrl: String? = nil, completion: ((Bool, String) -> Void)? = nil) {
        let base = serverBaseUrl ?? InjectionEngine.shared().serverBaseUrl ?? "http://192.168.1.15:8888"
        guard let url = URL(string: "\(base)/api/v1/mods/catalog") else {
            completion?(false, "URL de catálogo inválida")
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSyncing = false
                
                if let error = error {
                    completion?(false, "Servidor no disponible: \(error.localizedDescription)")
                    return
                }
                
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data else {
                    completion?(false, "Respuesta errónea del servidor")
                    return
                }
                
                do {
                    let decodedMods = try JSONDecoder().decode([ModItemInfo].self, from: data)
                    if !decodedMods.isEmpty {
                        self.allMods = decodedMods
                        self.lastSyncTime = Date()
                        self.syncMessage = "✓ Catálogo en vivo sincronizado (\(decodedMods.count) mods)"
                        
                        // Guardar en caché persistente para soporte offline
                        if let encoded = try? JSONEncoder().encode(decodedMods) {
                            UserDefaults.standard.set(encoded, forKey: self.cacheKey)
                        }
                        
                        completion?(true, "Catálogo sincronizado exitosamente con \(decodedMods.count) modificaciones.")
                    } else {
                        completion?(false, "El servidor devolvió un catálogo vacío")
                    }
                } catch {
                    completion?(false, "Error al decodificar catálogo: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    public func inject(mod: ModItemInfo, progress: ((Float) -> Void)? = nil, completion: @escaping (Bool, String) -> Void) {
        InjectionEngine.shared().injectMod(
            withAlias: mod.alias,
            targetDir: mod.targetDir,
            filePrefix: mod.filePrefix,
            fallbackFilename: mod.fallbackFilename,
            progress: progress != nil ? { p in progress?(p) } : nil
        ) { success, message in
            completion(success, message)
        }
    }
}
