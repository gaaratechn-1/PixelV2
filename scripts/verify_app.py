#!/usr/bin/env python3
"""
PixelV2 App Verification Script
Gaara Quantum Studio
"""

import os
from pathlib import Path

app_dir = Path(__file__).resolve().parent.parent

print("=" * 70)
print("  VERIFICACIÓN INTEGRAL DE ARTEFACTOS // PIXELV2 APP")
print(f"  Ruta base: {app_dir}")
print("=" * 70)

required_files = [
    # Swift
    "App.swift",
    "Core/KeyManager.swift",
    "Core/ContainerManager.swift",
    "Core/ModEngine.swift",
    "Core/ModStateStore.swift",
    "UI/Theme.swift",
    "UI/Components/GlowingWaveView.swift",
    "UI/Components/PixelLogoView.swift",
    "UI/Views/KeyAuthView.swift",
    "UI/Views/PixelDashboardView.swift",
    "UI/Views/ContainerExplorerView.swift",
    "UI/Views/SettingsView.swift",
    "UI/Views/MainTabView.swift",
    # C / ObjC
    "Core/bad_query.c",
    "Core/bad_query.h",
    "Core/MCMLease.m",
    "Core/MCMLease.h",
    "Core/InjectionEngine.m",
    "Core/InjectionEngine.h",
    "Bridge/mcm_bridge.m",
    "Bridge/mcm_bridge.h",
    "Bridge/PixelV2-Bridging-Header.h",
    # Resources
    "Info.plist",
    "PixelV2.entitlements",
    "Assets.xcassets/AppIcon.appiconset/icon-1024.png",
    "Assets.xcassets/PixelLogo.imageset/PixelLogo.png",
    "PixelV2.xcodeproj/project.pbxproj",
    ".github/workflows/build-ipa.yml"
]

all_ok = True
for rel in required_files:
    p = app_dir / rel
    if p.exists():
        size = p.stat().st_size
        print(f"  [OK] {rel} ({size} bytes)")
    else:
        print(f"  [ERROR] Faltante: {rel}")
        all_ok = False

if all_ok:
    print("\n" + "=" * 70)
    print("  >>> TODOS LOS ARCHIVOS DE PIXELV2 APP VERIFICADOS AL 100% <<<")
    print("=" * 70)
else:
    print("\n[FALLO] Existen archivos faltantes en la estructura.")
