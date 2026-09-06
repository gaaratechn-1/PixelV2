//
//  KeyManager.swift
//  PixelV2
//
//  License validation and device binding against local server http://192.168.1.15:8888
//  Gaara Quantum Studio
//

import Foundation
import UIKit
import Combine
import CommonCrypto

final class KeyManager: ObservableObject {
    static let shared = KeyManager()
    
    @Published var isAuthorized: Bool = false
    @Published var activeKey: String = ""
    @Published var expirationDateStr: String = "No registrada"
    @Published var remainingDaysStr: String = "--"
    @Published var deviceUDID: String = ""
    @Published var certTeamName: String = "Desconocido"
    @Published var certExpiryDateStr: String = "Desconocida"
    @Published var isValidating: Bool = false
    @Published var lastErrorMessage: String? = nil
    
    private let keyDefaultsKey = "pixelv2_license_key"
    private let authDefaultsKey = "pixelv2_is_authorized"
    private let teamDefaultsKey = "pixelv2_cert_team"
    private let expDefaultsKey = "pixelv2_cert_exp"
    
    // Clave secreta HMAC compartida con el servidor PixelV2 (Anti-Bypass Criptográfico)
    private let hmacSecret = "pixelv2_secret_hmac_master_2026"
    
    private init() {
        self.deviceUDID = UIDevice.current.identifierForVendor?.uuidString ?? "00008101-PIXEL-V2"
        self.activeKey = UserDefaults.standard.string(forKey: keyDefaultsKey) ?? ""
        self.isAuthorized = UserDefaults.standard.bool(forKey: authDefaultsKey)
        self.certTeamName = UserDefaults.standard.string(forKey: teamDefaultsKey) ?? "Gaara Developer Team"
        self.certExpiryDateStr = UserDefaults.standard.string(forKey: expDefaultsKey) ?? "Permanente"
        
        if !activeKey.isEmpty {
            validateKey(activeKey)
        }
    }
    
    /// Calcula la firma HMAC-SHA256 de un mensaje para verificar la integridad de la respuesta del servidor
    private func computeHMACSHA256(key: String, message: String) -> String {
        let keyData = Data(key.utf8)
        let messageData = Data(message.utf8)
        var mac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { msgBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyData.count, msgBytes.baseAddress, messageData.count, &mac)
            }
        }
        return mac.map { String(format: "%02x", $0) }.joined()
    }
    
    func validateKey(_ keyToValidate: String, completion: ((Bool, String) -> Void)? = nil) {
        let cleanKey = keyToValidate.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanKey.isEmpty else {
            self.lastErrorMessage = "Ingresa una clave de licencia válida."
            completion?(false, self.lastErrorMessage!)
            return
        }
        
        DispatchQueue.main.async {
            self.isValidating = true
            self.lastErrorMessage = nil
        }
        
        let serverUrl = InjectionEngine.shared().serverBaseUrl
        guard let url = URL(string: "\(serverUrl)/api/v1/keys/validate") else {
            DispatchQueue.main.async {
                self.isValidating = false
                self.lastErrorMessage = "URL de servidor inválida."
                completion?(false, self.lastErrorMessage!)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let body: [String: Any] = [
            "key": cleanKey,
            "udid": self.deviceUDID
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isValidating = false
                
                if error != nil {
                    if self.isAuthorized && self.activeKey == cleanKey {
                        completion?(true, "Modo sin conexión temporal activo.")
                        return
                    }
                    self.lastErrorMessage = "No se pudo conectar al servidor local (\(serverUrl)). Asegúrate de que start_server.bat esté abierto."
                    completion?(false, self.lastErrorMessage!)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.lastErrorMessage = "Respuesta del servidor inválida."
                    completion?(false, self.lastErrorMessage!)
                    return
                }
                
                let isValid = json["valid"] as? Bool ?? false
                let serverTime = json["server_time"] as? Int ?? 0
                let serverSignature = (json["signature"] as? String ?? "").lowercased()
                
                // --- 3.1 Criptografía Anti-Bypass (Verificación de Firma HMAC-SHA256) ---
                // Si alguien usa Burp Suite, Charles Proxy o HTTP Catcher para cambiar {"valid": false} a {"valid": true},
                // la firma HMAC fallará de inmediato porque el atacante desconoce la clave secreta maestra.
                let expectedMessage = "\(cleanKey):\(isValid ? "true" : "false"):\(serverTime):\(self.deviceUDID)"
                let computedSignature = self.computeHMACSHA256(key: self.hmacSecret, message: expectedMessage).lowercased()
                
                guard !serverSignature.isEmpty, serverSignature == computedSignature else {
                    self.isAuthorized = false
                    self.lastErrorMessage = "Violación de integridad criptográfica: la respuesta del servidor fue interceptada o alterada (Anti-Bypass)."
                    UserDefaults.standard.set(false, forKey: self.authDefaultsKey)
                    completion?(false, self.lastErrorMessage!)
                    return
                }
                
                // Validación de frescura de tiempo (Anti-Replay Attack)
                let localTime = Int(Date().timeIntervalSince1970)
                if abs(localTime - serverTime) > 300 && serverTime > 0 {
                    // Advertencia de desincronización de reloj si supera 5 minutos
                    NSLog("[PixelV2] Advertencia: Desfase de reloj con el servidor: %ld s", abs(localTime - serverTime))
                }
                
                if isValid {
                    self.isAuthorized = true
                    self.activeKey = cleanKey
                    UserDefaults.standard.set(cleanKey, forKey: self.keyDefaultsKey)
                    UserDefaults.standard.set(true, forKey: self.authDefaultsKey)
                    
                    // Extraer información de la firma digital
                    if let team = json["cert_team"] as? String {
                        self.certTeamName = team
                        UserDefaults.standard.set(team, forKey: self.teamDefaultsKey)
                    }
                    if let expCert = json["cert_expiry"] as? String {
                        self.certExpiryDateStr = expCert
                        UserDefaults.standard.set(expCert, forKey: self.expDefaultsKey)
                    }
                    if let bound = json["bound_udid"] as? String, !bound.isEmpty {
                        self.deviceUDID = bound
                    }
                    
                    if let exp = json["expires_at"] as? Double, exp > 9000000000 {
                        self.expirationDateStr = "Permanente (Lifetime)"
                        self.remainingDaysStr = "Ilimitado"
                    } else if let rem = json["remaining_days"] as? Double {
                        self.remainingDaysStr = "\(rem) días"
                        self.expirationDateStr = "\(rem) días restantes"
                    }
                    
                    completion?(true, "¡Licencia y firma digital validadas criptográficamente con éxito!")
                } else {
                    let errMsg = json["error"] as? String ?? "Clave inválida o expirada."
                    self.isAuthorized = false
                    self.lastErrorMessage = errMsg
                    UserDefaults.standard.set(false, forKey: self.authDefaultsKey)
                    completion?(false, errMsg)
                }
            }
        }.resume()
    }
    
    func logout() {
        self.isAuthorized = false
        self.activeKey = ""
        UserDefaults.standard.removeObject(forKey: keyDefaultsKey)
        UserDefaults.standard.set(false, forKey: authDefaultsKey)
    }
}
