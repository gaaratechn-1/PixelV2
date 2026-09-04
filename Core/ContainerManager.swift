//
//  ContainerManager.swift
//  PixelV2
//
//  Reactive container connection & server health coordinator for SwiftUI.
//  Gaara Quantum Studio
//

import Foundation
import Combine

final class ContainerManager: ObservableObject {
    static let shared = ContainerManager()
    
    static let freeFireBundleID = "com.dts.freefireth"
    
    @Published var containerPath: String? = nil
    @Published var isContainerConnected: Bool = false
    @Published var isServerConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var currentServerUrl: String = "http://192.168.1.15:8888" {
        didSet {
            UserDefaults.standard.set(currentServerUrl, forKey: "pixelv2_server_url")
            InjectionEngine.shared().serverBaseUrl = currentServerUrl
        }
    }
    @Published var diagnosticLog: String = ""
    @Published var lastError: String? = nil
    
    private let engine = InjectionEngine.shared()
    
    private init() {
        if let savedUrl = UserDefaults.standard.string(forKey: "pixelv2_server_url"), !savedUrl.isEmpty {
            self.currentServerUrl = savedUrl
        }
        engine.serverBaseUrl = self.currentServerUrl
        
        checkServerHealth()
        detectAndActivate()
    }
    
    /// Verifica la conexión con el servidor local
    func checkServerHealth(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(currentServerUrl)/health") else {
            self.isServerConnected = false
            completion?(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil, let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    self.isServerConnected = true
                    completion?(true)
                } else {
                    self.isServerConnected = false
                    completion?(false)
                }
            }
        }.resume()
    }
    
    /// Intenta detectar el contenedor de Free Fire
    func detectAndActivate(completion: ((Bool, String) -> Void)? = nil) {
        DispatchQueue.main.async {
            self.isConnecting = true
            self.lastError = nil
        }
        
        engine.testContainerAccess { [weak self] connected, path, msg in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isConnecting = false
                self.isContainerConnected = connected
                self.containerPath = path
                self.diagnosticLog = msg
                if !connected {
                    self.lastError = msg
                }
                completion?(connected, msg)
            }
        }
    }
}
