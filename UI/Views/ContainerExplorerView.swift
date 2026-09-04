//
//  ContainerExplorerView.swift
//  PixelV2
//
//  Live container file explorer for Free Fire.
//  Gaara Quantum Studio
//

import SwiftUI

struct ContainerExplorerView: View {
    @ObservedObject var containerManager = ContainerManager.shared
    
    @State private var currentRelativePath: String = ""
    @State private var directoryItems: [FileItem] = []
    
    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let isDirectory: Bool
        let size: Int64
        let path: String
    }
    
    var body: some View {
        ZStack {
            PixelTheme.canvas.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXPLORADOR DE CONTENEDOR")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(PixelTheme.chromeMuted)
                        Text("com.dts.freefireth")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(PixelTheme.chromeWhite)
                    }
                    Spacer()
                    
                    Button(action: refreshContents) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PixelTheme.chromeWhite)
                            .padding(10)
                            .background(PixelTheme.cardBg)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(PixelTheme.cardBorder, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                // Ruta actual
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(PixelTheme.chromeSilver)
                    Text("/" + currentRelativePath)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(PixelTheme.chromeWhite)
                        .lineLimit(1)
                    Spacer()
                    
                    if !currentRelativePath.isEmpty {
                        Button(action: navigateUp) {
                            Text("VOLVER")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(PixelTheme.chromeWhite)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(PixelTheme.cardBg)
                .cornerRadius(10)
                .padding(.horizontal, 20)
                
                // Lista de archivos
                if directoryItems.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(PixelTheme.chromeMuted)
                        Text(containerManager.isContainerConnected ? "Directorio vacío o inaccesible" : "Conecta a Free Fire primero")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PixelTheme.chromeMuted)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(directoryItems) { item in
                            Button(action: {
                                if item.isDirectory {
                                    navigateTo(item.name)
                                }
                            }) {
                                HStack {
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundColor(item.isDirectory ? PixelTheme.chromeWhite : PixelTheme.chromeSilver)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(PixelTheme.chromeWhite)
                                        
                                        if !item.isDirectory {
                                            Text("\(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))")
                                                .font(.system(size: 10))
                                                .foregroundColor(PixelTheme.chromeMuted)
                                        }
                                    }
                                    Spacer()
                                    if item.isDirectory {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(PixelTheme.chromeMuted)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(PixelTheme.cardBg)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .padding(.horizontal, 10)
                }
            }
        }
        .onAppear(perform: refreshContents)
    }
    
    private func refreshContents() {
        guard let root = containerManager.containerPath else {
            directoryItems = []
            return
        }
        
        let fullPath = currentRelativePath.isEmpty ? root : (root as NSString).appendingPathComponent(currentRelativePath)
        let fm = FileManager.default
        
        guard let contents = try? fm.contentsOfDirectory(atPath: fullPath) else {
            directoryItems = []
            return
        }
        
        directoryItems = contents.compactMap { name -> FileItem? in
            let itemPath = (fullPath as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: itemPath, isDirectory: &isDir) else { return nil }
            let size = (try? fm.attributesOfItem(atPath: itemPath)[.size] as? Int64) ?? 0
            return FileItem(name: name, isDirectory: isDir.boolValue, size: size, path: itemPath)
        }.sorted { $0.isDirectory && !$1.isDirectory }
    }
    
    private func navigateTo(_ folder: String) {
        if currentRelativePath.isEmpty {
            currentRelativePath = folder
        } else {
            currentRelativePath = (currentRelativePath as NSString).appendingPathComponent(folder)
        }
        refreshContents()
    }
    
    private func navigateUp() {
        if !currentRelativePath.isEmpty {
            currentRelativePath = (currentRelativePath as NSString).deletingLastPathComponent
            refreshContents()
        }
    }
}
